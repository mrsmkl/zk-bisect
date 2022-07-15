/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('@nomiclabs/hardhat-ethers')
require('hardhat-gas-reporter')

module.exports = {
  solidity: {
    compilers: [
        {
            version: '0.8.9',
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 10
                }
            }
        }
    ]
  },
  networks: {
    hardhat: {
        allowUnlimitedContractSize: true,
        initialBaseFeePerGas: 0
    },
    external: {
        url: 'http://localhost:8545',
        timeout: 200000
    },
  },

};
