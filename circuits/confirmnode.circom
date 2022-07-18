pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template Main() {
    signal input secret; // Shared secret
    // Assertion data
    signal input num_blocks;
    signal input inbox_max;
    signal input before_status;
    signal input before_block;
    signal input before_send;
    signal input before_inbox;
    signal input before_position;
    signal input after_status;
    signal input after_block;
    signal input after_send;
    signal input after_inbox;
    signal input after_position;

    signal output assertion_hash;
    signal output send_root_out;

    component hash_assertion = Poseidon(12);
    hash_assertion.inputs[0] <== num_blocks;
    hash_assertion.inputs[1] <== inbox_max;
    hash_assertion.inputs[2] <== before_status;
    hash_assertion.inputs[3] <== before_block;
    hash_assertion.inputs[4] <== before_send;
    hash_assertion.inputs[5] <== before_inbox;
    hash_assertion.inputs[6] <== before_position;
    hash_assertion.inputs[7] <== after_status;
    hash_assertion.inputs[8] <== after_block;
    hash_assertion.inputs[9] <== after_send;
    hash_assertion.inputs[10] <== after_inbox;
    hash_assertion.inputs[11] <== after_position;
    assertion_hash <== hash_assertion.out;

    send_root_out <== after_send;
}

component main = Main();
