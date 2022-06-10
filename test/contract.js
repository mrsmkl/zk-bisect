const { ethers } = require("hardhat");
const circomlib = require('circomlibjs')
const snarkjs = require('snarkjs')
const { unstringifyBigInts } = require('ffjavascript').utils

const { num2bits, num2fullbits } = require('./util')

describe('Bisect', function () {
    this.timeout(100000)
    let bisect
    let owner, other
    before(async () => {
        let Init = await ethers.getContractFactory('Verifierbisectinit')
        let Challenge = await ethers.getContractFactory('Verifierbisectchallenge')
        let init = await Init.deploy()
        let challenge = await Challenge.deploy()
        await init.deployed()
        await challenge.deployed()
        let Bisect = await ethers.getContractFactory('Bisect')
        bisect = await Bisect.deploy(init.address, challenge.address)
        await bisect.deployed();
        [owner, other] = await ethers.getSigners()
    })
    it('init challenge', async () => {
        const poseidon = await circomlib.buildPoseidonReference()
        const babyJub = await circomlib.buildBabyjub()
        const mimcjs = await circomlib.buildMimcSponge()
        const F = poseidon.F

        let step1 = F.e(0)
        let step2 = F.e(12)
        let step3 = F.e(24)

        let hash1 = F.e(333)
        let hash2 = F.e(444)
        let hash3 = F.e(555)

        let step1_salt = F.e(220)
        let step2_salt = F.e(2212)
        let step3_salt = F.e(2224)

        let hash1_salt = F.e(22333)
        let hash2_salt = F.e(22444)
        let hash3_salt = F.e(22555)

        let senderK = 123
        let otherK = 234

        function conv(x) {
            const res = F.toObject(x)
            return res
        }
        const hash_state = poseidon([
            step1,
            step2,
            step3,
            hash1,
            hash2,
            hash3,
            step1_salt,
        ])

        const senderPub = babyJub.mulPointEscalar(babyJub.Base8, senderK)
        const otherPub = babyJub.mulPointEscalar(babyJub.Base8, otherK)

        const k = babyJub.mulPointEscalar(senderPub, otherK)

        const cipher_step1 = mimcjs.hash(step1, step1_salt, k[0])
        const cipher_step2 = mimcjs.hash(step2, step2_salt, k[0])
        const cipher_step3 = mimcjs.hash(step3, step3_salt, k[0])

        const cipher_hash1 = mimcjs.hash(hash1, hash1_salt, k[0])
        const cipher_hash2 = mimcjs.hash(hash2, hash2_salt, k[0])
        const cipher_hash3 = mimcjs.hash(hash3, hash3_salt, k[0])

        let difference_round = 1
        let difference = num2bits(11)

        const snarkParams = {
            // private
            step1_L_in: conv(step1),
            step1_R_in: conv(step1_salt),
            step2_L_in: conv(step2),
            step2_R_in: conv(step2_salt),
            step3_L_in: conv(step3),
            step3_R_in: conv(step3_salt),

            hash1_L_in: conv(hash1),
            hash1_R_in: conv(hash1_salt),
            hash2_L_in: conv(hash2),
            hash2_R_in: conv(hash2_salt),
            hash3_L_in: conv(hash3),
            hash3_R_in: conv(hash3_salt),

            sender_k: senderK,
            difference: difference,
            difference_round: difference_round,

            // public
            sender_x: conv(senderPub[0]),
            sender_y: conv(senderPub[1]),
            other_x: conv(otherPub[0]),
            other_y: conv(otherPub[1]),

            cipher_step1_L_in: conv(cipher_step1.xL),
            cipher_step1_R_in: conv(cipher_step1.xR),
            cipher_step2_L_in: conv(cipher_step2.xL),
            cipher_step2_R_in: conv(cipher_step2.xR),
            cipher_step3_L_in: conv(cipher_step3.xL),
            cipher_step3_R_in: conv(cipher_step3.xR),

            cipher_hash1_L_in: conv(cipher_hash1.xL),
            cipher_hash1_R_in: conv(cipher_hash1.xR),
            cipher_hash2_L_in: conv(cipher_hash2.xL),
            cipher_hash2_R_in: conv(cipher_hash2.xR),
            cipher_hash3_L_in: conv(cipher_hash3.xL),
            cipher_hash3_R_in: conv(cipher_hash3.xR),
            hash_state_in: conv(hash_state),
        }

        const { proof } = await snarkjs.plonk.fullProve(
            snarkParams,
            'circuits/bisectinit.wasm',
            'circuits/bisectinit.zkey'
        )

        const signals = [
            senderPub[0],
            senderPub[1],
            otherPub[0],
            otherPub[1],

            (cipher_step1.xL),
            (cipher_step1.xR),
            (cipher_step2.xL),
            (cipher_step2.xR),
            (cipher_step3.xL),
            (cipher_step3.xR),

            (cipher_hash1.xL),
            (cipher_hash1.xR),
            (cipher_hash2.xL),
            (cipher_hash2.xR),
            (cipher_hash3.xL),
            (cipher_hash3.xR),
            (hash_state),
        ]

        // for (let i = 0; i < )

        const proofSolidity = (await snarkjs.plonk.exportSolidityCallData(unstringifyBigInts(proof), signals))
        const proofData = proofSolidity.split(',')[0]

        console.log(proofData)
        console.log(proofSolidity)

        console.log([conv(senderPub[0]), conv(senderPub[1])])

        await bisect.connect(owner).initChallenge(
            "0x1232",
            other.address,
            [conv(senderPub[0]), conv(senderPub[1])],
            [conv(otherPub[0]), conv(otherPub[1])],
            [conv(cipher_step1.xL), conv(cipher_step1.xR)],
            [conv(cipher_hash1.xL), conv(cipher_hash1.xR)],
            [conv(cipher_step2.xL), conv(cipher_step2.xR)],
            [conv(cipher_hash2.xL), conv(cipher_hash2.xR)],
            [conv(cipher_step3.xL), conv(cipher_step3.xR)],
            [conv(cipher_hash3.xL), conv(cipher_hash3.xR)],
            conv(hash_state),
            proofData
        )

    })
})

