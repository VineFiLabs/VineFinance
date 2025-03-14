require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: { 
    sepolia: {
      url: process.env.Sepolia_Api_Key,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2, process.env.PRIVATE_KEY3, process.env.PRIVATE_KEY4, process.env.PRIVATE_KEY5]
    },
    arb_sepolia: {
      url: process.env.Arbitrum_Api_Key,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2, process.env.PRIVATE_KEY3, process.env.PRIVATE_KEY4, process.env.PRIVATE_KEY5]
    },
    op_sepolia: {
      url: process.env.Op_Api_key,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2, process.env.PRIVATE_KEY3, process.env.PRIVATE_KEY4, process.env.PRIVATE_KEY5]
    },
    base_sepolia: {
      url: process.env.Base_Api_Key,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2, process.env.PRIVATE_KEY3, process.env.PRIVATE_KEY4, process.env.PRIVATE_KEY5]
    },
    avax_fuji: {
      url: process.env.Avax_Api_Key,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2, process.env.PRIVATE_KEY3, process.env.PRIVATE_KEY4, process.env.PRIVATE_KEY5]
    }
  },
  solidity: {
    compilers:[
      {version: "0.8.23"},
    ],
    settings: {
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: false,  
    currency: 'ETH',  
    // coinmarketcap: 'YOUR_API_KEY',
    outputFile: 'gas-report.txt', 
    noColors: true 
  },
  sourcify: {
    enabled: true
  },
  etherscan: {
    apiKey: process.env.AVAXscan_Api_key
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 4000
  }
  };
