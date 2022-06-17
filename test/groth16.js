const { ethers } = require("hardhat");
const circomlib = require('circomlibjs')
const snarkjs = require('snarkjs')
const { unstringifyBigInts } = require('ffjavascript').utils

const { num2bits, num2fullbits, bisectRange } = require('./util')

describe('Groth16 test', function () {
    this.timeout(100000)
    let contract
    let owner, other
    before(async () => {
        let Test = await ethers.getContractFactory('Verifier')
        contract = await Test.deploy()
        await contract.deployed();
        [owner, other] = await ethers.getSigners()
    })
    it('contract test', async () => {
        let a = [0x235A403A00532267F15ACC0C8A1B18B7BD1E7ABABD0564C39743CF05F4354013n, 0x154B889E1A2632C4D4887BEE4E9EBEE3015EE794450A0617F61EEB2C4F6EB0C9n]
        let b = [[0x181192C5A95CA1DE2915CDC597621C636EAD563C590E74CF83CEFDAF2E06DF56n, 0x2E5137A9EE9E059438197E9284E88D80277CA3D5389E628290514CCFDE7AA308n], [0x0CD80900F4ACDFED097602A2EF074C964CF621D0504977EABB1577E4BBDF8826n, 0x09035B2B700EC0A467E27A537E761B7EF73D654ACD04A21E0586929A362AD257n]]
        let c = [0x0EB8291EA0060BAB25CFC73D10BDAC879B96EAF81B6179977717CFD25D9719E1n, 0x222A10C9D3C0BD2DD9645DECC5AF8568783F5150E2067D0F36F6D0DE890AE8FAn]
        let inputs = [
            0x2F5AE8118C58E5049EE150230F03CC2A959D6D4AD877621A38EE7204DAE73CBFn,
            0x29A18140FF8A413E68A8E139682D3BCF9A16AE90A77B83E4CE26E243646F470Cn
        ]
        let res = await contract.verifyProof(a, b, c, inputs)
        console.log(res)
    })
})

