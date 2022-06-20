#!/bin/sh

#wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau

#git clone https://github.com/iden3/circom.git
#cd circom
#cargo build --release
#cargo install --path circom
#cd -

process() {
    circom circuits/$1.circom --r1cs --wasm --sym

    mv $1.r1cs circuits
    mv $1.sym circuits
    mv $1_js/$1.wasm circuits
    yarn run snarkjs plonk setup circuits/$1.r1cs powersOfTau28_hez_final_16.ptau circuits/$1.zkey
    yarn run snarkjs zkey export solidityverifier circuits/$1.zkey contracts/$1.sol
    gsed -i "s/PlonkVerifier/Verifier${1}/g" contracts/$1.sol || sed -i "s/PlonkVerifier/Verifier${1}/g" contracts/$1.sol
}

process bisectfinal
process bisectinit
process bisectchallenge
