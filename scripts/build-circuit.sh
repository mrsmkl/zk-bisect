#!/bin/sh

rm -f contracts/verifier.sol

wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau

git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
cd -

circom circuits/bisect.circom --r1cs --wasm --sym

mv bisect.r1cs circuits
mv bisect.sym circuits
mv bisect_js/bisect.wasm circuits
yarn run snarkjs plonk setup circuits/bisect.r1cs powersOfTau28_hez_final_16.ptau circuits/bisect.zkey
yarn run snarkjs zkey export verificationkey circuits/bisect.zkey circuits/verification_key.json
yarn run snarkjs zkey export solidityverifier circuits/bisect.zkey contracts/verifier.sol

