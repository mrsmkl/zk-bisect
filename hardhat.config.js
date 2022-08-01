/**
 * @type import('hardhat/config').HardhatUserConfig
 */

 require('@nomiclabs/hardhat-ethers')
 require('hardhat-gas-reporter')

module.exports = {
  solidity: "0.7.3",
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
