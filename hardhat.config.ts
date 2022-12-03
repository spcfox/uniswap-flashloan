import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

require('dotenv-defaults').config();

const ALCHEMY_KEY: string = process.env.ALCHEMY_API_KEY
const BLOCK_NUMBER: number = parseInt(process.env.BLOCK_NUMBER);

const config: HardhatUserConfig = {
    solidity: '0.8.17',
    networks: {
        hardhat: {
            forking: {
                url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
                blockNumber: BLOCK_NUMBER,
            },
        }
    }
};

export default config;
