import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { abi as UniswapV2FactoryAbi } from '@uniswap/v2-core/build/UniswapV2Factory.json';
import { abi as UniswapV2FactoryPair } from '@uniswap/v2-core/build/UniswapV2Pair.json';

const signerAddress = '0x06920C9fC643De77B99cB7670A944AD31eaAA260';

const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const wETHAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const MATICAddress = '0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0';

describe('Flashloan', function() {
    async function deployAndGetUniswap() {
        const signer = await ethers.getImpersonatedSigner(signerAddress);

        const UniswapFlashloanCycleSwap = await ethers.getContractFactory('UniswapFlashloanCycleSwap');
        const uniswapFlashloanCycleSwap = await UniswapFlashloanCycleSwap.connect(signer).deploy();

        const uniswapFactory = await ethers.getContractAt(UniswapV2FactoryAbi, uniswapV2FactoryAddress);

        return { signer, uniswapFlashloanCycleSwap, uniswapFactory };
    }

    it('Deployment', async function() {
        const { signer, uniswapFlashloanCycleSwap } = await loadFixture(deployAndGetUniswap);

        expect(await uniswapFlashloanCycleSwap.owner())
            .to.equal(signer.address, 'owner should be equals owner address');
    });

    it('wETH -> LINK -> DAI-> wETH', async function() {
        const { signer, uniswapFlashloanCycleSwap, uniswapFactory } = await loadFixture(deployAndGetUniswap);

        const pairForFlashloan = await uniswapFactory.getPair(wETHAddress, MATICAddress);

        const pairContract = await ethers.getContractAt(UniswapV2FactoryPair, pairForFlashloan);

        await pairContract.connect(signer).swap(0, BigNumber.from(10).pow(15), uniswapFlashloanCycleSwap.address, 1);
    });
});
