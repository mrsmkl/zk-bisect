#!/bin/sh

rm -f contracts/verifier.sol

wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau

git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
cd -

circom circuits/bisectinit.circom --r1cs --wasm --sym

mv bisectinit.r1cs circuits
mv bisectinit.sym circuits
mv bisectinit_js/bisectinit.wasm circuits
yarn run snarkjs plonk setup circuits/bisectinit.r1cs powersOfTau28_hez_final_16.ptau circuits/bisectinit.zkey
yarn run snarkjs zkey export solidityverifier circuits/bisectinit.zkey contracts/verifier.sol

