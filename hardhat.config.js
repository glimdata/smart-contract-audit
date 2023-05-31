require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
// require("solidity-coverage");
require("dotenv").config();

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: 'hardhat',
  networks: {
    // coverage: {
    //   host: "localhost",
    //   network_id: "*",
    //   port: 8555,         // <-- If you change this, also set the port option in .solcover.js.
    //   gas: 0xfffffffffff, // <-- Use this high gas value
    //   gasPrice: 0x01      // <-- Use this low gas price
    // },
    fuji: {
      url: `https://avalanche-fuji.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY]
    }
  }
};

