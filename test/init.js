const circomlib = require('circomlibjs')

const snarkjs = require('snarkjs')
// const { unstringifyBigInts } = require('ffjavascript').utils

describe('testing init', () => {
    it('proving init', async () => {
        let step1 = 0
        let step2 = 12
        let step3 = 24

        let hash1 = 333
        let hash2 = 444
        let hash3 = 555

        let step1_salt = 220
        let step2_salt = 2212
        let step3_salt = 2224

        let hash1_salt = 22333
        let hash2_salt = 22444
        let hash3_salt = 22555

        let senderK = 123 
        let otherK = 234

        const poseidon = await circomlib.buildPoseidonReference()
        const babyJub = await circomlib.buildBabyjub()
        const mimcjs = await circomlib.buildMimcSponge()
        const F = poseidon.F
        function conv(x) {
            const res = F.toObject(x)
            return res
        }
        const origHash = poseidon([F.e(orig1), F.e(orig2)])

        const senderPub = babyJub.mulPointEscalar(babyJub.Base8, senderK)
        const otherPub = babyJub.mulPointEscalar(babyJub.Base8, otherK)

        const k = babyJub.mulPointEscalar(senderPub, otherK)

        const cipher_step1 = mimcjs.hash(step1, step1_salt, k[0])
        const cipher_step2 = mimcjs.hash(step2, step2_salt, k[0])
        const cipher_step3 = mimcjs.hash(step3, step3_salt, k[0])

        const cipher_hash1 = mimcjs.hash(hash1, hash1_salt, k[0])
        const cipher_hash2 = mimcjs.hash(hash2, hash2_salt, k[0])
        const cipher_hash3 = mimcjs.hash(hash3, hash3_salt, k[0])

        const snarkParams = {
            // private
            xL_in: orig1,
            xR_in: orig2,
            provider_k: providerK,
            // public
            buyer_x: conv(buyerPub[0]),
            buyer_y: conv(buyerPub[1]),
            provider_x: conv(providerPub[0]),
            provider_y: conv(providerPub[1]),
            cipher_xL_in: conv(cipher.xL),
            cipher_xR_in: conv(cipher.xR),
            hash_plain: conv(origHash)
        }

        const { proof } = await snarkjs.plonk.fullProve(
            snarkParams,
            'circuits/bisectinit.wasm',
            'circuits/bisectinit.zkey'
        )
    })
})
