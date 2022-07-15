const { ethers } = require("hardhat");

describe('Accumulator test', function () {
    this.timeout(100000)
    let contract
    let owner, other
    beforeEach(async () => {
        let Test = await ethers.getContractFactory('Accumulator')
        contract = await Test.deploy()
        await contract.deployed();
        await contract.init();
        [owner, other] = await ethers.getSigners()
    })
    it('contract test', async () => {
        for (let i = 0; i < 50; i++) {
            await contract.accumulate("0x0000000000000000000000000000000000000000000000000000000000001234")
        }
    })
    it('contract test2', async () => {
        for (let i = 0; i < 50; i++) {
            await contract.add("0x0000000000000000000000000000000000000000000000000000000000001234")
        }
    })
    it('contract test3', async () => {
        for (let i = 0; i < 50; i++) {
            await contract.addBuffer("0x0000000000000000000000000000000000000000000000000000000000001234")
        }
    })
})

