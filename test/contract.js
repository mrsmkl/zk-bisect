const { ethers } = require("hardhat");
const circomlib = require('circomlibjs')
const snarkjs = require('snarkjs')
const { unstringifyBigInts } = require('ffjavascript').utils

const { num2bits, num2fullbits, bisectRange } = require('./util')

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
    
        console.log('current hash', conv(hash_state),
        [
            step1,
            step2,
            step3,
            hash1,
            hash2,
            hash3,
            step1_salt,
        ].map(conv))

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

        const proofSolidity = (await snarkjs.plonk.exportSolidityCallData(unstringifyBigInts(proof), signals))
        const proofData = proofSolidity.split(',')[0]

        console.log(proofData)
        // console.log(proofSolidity)

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

    it('query and reply challenge', async () => {
        const poseidon = await circomlib.buildPoseidonReference()
        const babyJub = await circomlib.buildBabyjub()
        const mimcjs = await circomlib.buildMimcSponge()
        const F = poseidon.F

        let {
            difference,
            difference_eq,
            difference_round,
            step1,
            step2,
            step3,
            prev_step1,
            prev_step2,
            // prev_step3,
            steps_equal,
        } = bisectRange(F, 0, 12)

        let prev_step3 = F.e(24)

        let prev_hash1 = F.e(333)
        let prev_hash2 = F.e(444)
        let prev_hash3 = F.e(555)

        let hash1 = F.e(333)
        let hash2 = F.e(999)
        let hash3 = F.e(444)

        if (steps_equal === 1) {
            hash2 = hash3
        }

        let step1_salt = F.e(2203)
        let step2_salt = F.e(2212)
        let step3_salt = F.e(2224)

        let hash1_salt = F.e(22333)
        let hash2_salt = F.e(22444)
        let hash3_salt = F.e(22555)

        let prev_step1_salt = F.e(220)

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
        const prev_hash_state = poseidon([
            prev_step1,
            prev_step2,
            prev_step3,
            prev_hash1,
            prev_hash2,
            prev_hash3,
            prev_step1_salt,
        ])

        console.log('prev hash', conv(prev_hash_state),
        [
            prev_step1,
            prev_step2,
            prev_step3,
            prev_hash1,
            prev_hash2,
            prev_hash3,
            prev_step1_salt,
        ].map(conv))

        const senderPub = babyJub.mulPointEscalar(babyJub.Base8, senderK)
        const otherPub = babyJub.mulPointEscalar(babyJub.Base8, otherK)

        const k = babyJub.mulPointEscalar(senderPub, otherK)

        let choose = F.e(0)
        let choose_salt = F.e(1667)

        const cipher_step1 = mimcjs.hash(step1, step1_salt, k[0])
        const cipher_step2 = mimcjs.hash(step2, step2_salt, k[0])
        const cipher_step3 = mimcjs.hash(step3, step3_salt, k[0])

        const cipher_hash1 = mimcjs.hash(hash1, hash1_salt, k[0])
        const cipher_hash2 = mimcjs.hash(hash2, hash2_salt, k[0])
        const cipher_hash3 = mimcjs.hash(hash3, hash3_salt, k[0])

        const cipher_choose = mimcjs.hash(choose, choose_salt, k[0])

        // Make reply
        await bisect.connect(other).queryChallenge(
            "0x1232",
            [conv(cipher_choose.xL), conv(cipher_choose.xR)]
        )

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

            prev_step1_L_in: conv(prev_step1),
            prev_step1_R_in: conv(prev_step1_salt),
            prev_step2_L_in: conv(prev_step2),
            prev_step3_L_in: conv(prev_step3),

            prev_hash1_L_in: conv(prev_hash1),
            prev_hash2_L_in: conv(prev_hash2),
            prev_hash3_L_in: conv(prev_hash3),

            choose_L_in: conv(choose),
            choose_R_in: conv(choose_salt),

            sender_k: senderK,
            difference: difference,
            difference_eq: difference_eq,
            difference_round: difference_round,
            difference_choose: conv(choose),
            steps_equal: steps_equal,
            choose_bits: num2fullbits(BigInt(conv(choose))),

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

            cipher_choose_L_in: conv(cipher_choose.xL),
            cipher_choose_R_in: conv(cipher_choose.xR),

            hash_state_in: conv(hash_state),
            prev_hash_state_in: conv(prev_hash_state),
        }

        const { proof } = await snarkjs.plonk.fullProve(
            snarkParams,
            'circuits/bisectchallenge.wasm',
            'circuits/bisectchallenge.zkey'
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
            (cipher_choose.xL),
            (cipher_choose.xR),
            (hash_state),
            (prev_hash_state),
        ]

        const proofSolidity = (await snarkjs.plonk.exportSolidityCallData(unstringifyBigInts(proof), signals))
        const proofData = proofSolidity.split(',')[0]

        console.log(proofData)

        await bisect.connect(owner).replyChallenge(
            "0x1232",
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

