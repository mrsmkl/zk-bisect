const { ethers } = require("hardhat");

describe('Accumulator test', function () {
    this.timeout(100000)
    let contract
    let owner, other
    before(async () => {
        let Test = await ethers.getContractFactory('Accumulator')
        contract = await Test.deploy()
        await contract.deployed();
        await contract.init();
        [owner, other] = await ethers.getSigners()
    })
    it('contract test', async () => {
        await contract.accumulate("0x0000000000000000000000000000000000000000000000000000000000001234")
    })
})

