# Uniswap Flashloan Example

This is a simple example of how to use the Uniswap Flashloan feature.
It is a simple contract that swaps tokens in a cycle, using the flashloan and getting a profit.

## Run
To use, you need to install [Node.js](https://nodejs.org)
and get API key for [Alchemy](https://www.alchemy.com).

1. Put your Alchemy API key in environment variable `ALCHEMY_API_KEY`. You can use `.env` file for that. 
Also, you can set `BLOCK_NUMBER` environment variable to specify the block number to fork from.
2. `npm install`
3. `npx hardhat test`

## Output example
```
  Flashloan
    ✔ Deployment (12610ms)
Flashloaned 1000000000000000 wETH
Swapped:
  1000000000000000 WETH
  -> 195923316305126397 LINK
Swapped:
  195923316305126397 LINK
  -> 1222398003837262657 DAI
Swapped:
  1222398003837262657 DAI
  -> 1006603468681118 WETH
Repayed 1003009027081244 wETH
Profit: 3594441599874 wETH
    ✔ wETH -> LINK -> DAI-> wETH (576ms)
```
