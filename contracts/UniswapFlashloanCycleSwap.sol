// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "hardhat/console.sol";

contract UniswapFlashloanCycleSwap {
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public immutable owner;

    modifier onlyOwner(address sender) {
        require(sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyUniswapV2PairWETH(uint amount0, uint amount1) {
        require(amount0 == 0 || amount1 == 0, "Only one token can be wETH.");

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = getPair(token0, token1);

        require(msg.sender == pair, "Only UniswapV2Pair can call this function.");

        if (amount0 == 0) {
            require(token1 == wETH, "Only wETH amount can be non-zero.");
        } else {
            require(token0 == wETH, "Only wETH amount can be non-zero.");
        }

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata)
        public
        onlyOwner(sender)
        onlyUniswapV2PairWETH(amount0, amount1)
    {
        uint ethAmount = amount0 == 0 ? amount1 : amount0;

        console.log("Flashloaned %s wETH", ethAmount);

        address[3] memory path = [wETH, LINK, DAI];

        uint amountIn = ethAmount;

        for (uint8 i = 0; i < path.length; i++) {
            address tokenIn = path[i];
            address tokenOut = path[(i + 1) % path.length];

            amountIn = swapExactTokensForTokens(amountIn, tokenIn, tokenOut);
        }

        uint amountToRepay = (ethAmount * 1000 + 996) / 997; // 0.3% fee with ceil
        IERC20(wETH).transfer(msg.sender, amountToRepay);

        console.log("Repayed %s wETH", amountToRepay);

        if (amountIn >= amountToRepay) {
            console.log("Profit: %s wETH", amountIn - amountToRepay);
        } else {
            console.log("Overpaid: %s wETH", amountToRepay - amountIn);
        }
    }

    function withdraw(address token, uint amount) public onlyOwner(msg.sender) {
        IERC20(token).transfer(msg.sender, amount);
    }

    function swapExactTokensForTokens(uint amountIn, address tokenIn, address tokenOut) private returns (uint amountOut) {
        address pair = getPair(tokenIn, tokenOut);
        (uint reserveIn, uint reserveOut) = getReserves(pair, tokenIn, tokenOut);
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        require(amountOut > 0, "Insufficient output amount.");

        bool result = IERC20(tokenIn).transfer(pair, amountIn);
        require(result, "Transfer failed.");
        (uint amount0Out, uint amount1Out) = tokenIn < tokenOut ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));

        console.log("Swapped:");
        console.log("  %s %s", amountIn, IERC20Metadata(tokenIn).symbol());
        console.log("  -> %s %s", amountOut, IERC20Metadata(tokenOut).symbol());
    }

    function getPair(address token0, address token1) private returns (address) {
        (bool success, bytes memory result) = UNISWAP_V2_FACTORY.call(abi.encodeWithSignature("getPair(address,address)", token0, token1));
        require(success, "Failed to call getPair()");
        return abi.decode(result, (address));
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function getReserves(address pair, address tokenIn, address tokenOut) private returns (uint112 reserveIn, uint112 reserveOut) {
        (bool success, bytes memory result) = pair.call(abi.encodeWithSignature("getReserves()"));
        require(success, "Failed to call getReserves()");
        (uint112 reserve0, uint112 reserve1) = abi.decode(result, (uint112, uint112));
        (reserveIn, reserveOut) = tokenIn < tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
