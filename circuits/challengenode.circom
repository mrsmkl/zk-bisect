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
    signal input propose_time; // cannot be secret
    signal input wasm_root;

    // Other Assertion data
    signal input prev_num_blocks;
    signal input prev_inbox_max;
    signal input prev_before_status;
    signal input prev_before_block;
    signal input prev_before_send;
    signal input prev_before_inbox;
    signal input prev_before_position;
    signal input prev_after_status;
    signal input prev_after_block;
    signal input prev_after_send;
    signal input prev_after_inbox;
    signal input prev_after_position;
    signal input prev_propose_time; // cannot be secret
    signal input prev_wasm_root;

    signal output assertion_hash;
    signal output prev_assertion_hash;
    signal output init_hash;
    signal output prev_propose_time_out;

    prev_propose_time_out <== prev_propose_time;

    component hash_assertion = Poseidon(14);
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
    hash_assertion.inputs[12] <== wasm_root;
    hash_assertion.inputs[13] <== propose_time;
    assertion_hash <== hash_assertion.out;

    component prev_hash_assertion = Poseidon(14);
    prev_hash_assertion.inputs[0] <== prev_num_blocks;
    prev_hash_assertion.inputs[1] <== prev_inbox_max;
    prev_hash_assertion.inputs[2] <== prev_before_status;
    prev_hash_assertion.inputs[3] <== prev_before_block;
    prev_hash_assertion.inputs[4] <== prev_before_send;
    prev_hash_assertion.inputs[5] <== prev_before_inbox;
    prev_hash_assertion.inputs[6] <== prev_before_position;
    prev_hash_assertion.inputs[7] <== prev_after_status;
    prev_hash_assertion.inputs[8] <== prev_after_block;
    prev_hash_assertion.inputs[9] <== prev_after_send;
    prev_hash_assertion.inputs[10] <== prev_after_inbox;
    prev_hash_assertion.inputs[11] <== prev_after_position;
    prev_hash_assertion.inputs[12] <== prev_wasm_root;
    prev_hash_assertion.inputs[13] <== prev_propose_time;
    prev_assertion_hash <== prev_hash_assertion.out;

    component hash_init = Poseidon(5);
    hash_init.inputs[0] <== after_status;
    hash_init.inputs[1] <== after_block;
    hash_init.inputs[2] <== after_send;
    hash_init.inputs[3] <== after_inbox;
    hash_init.inputs[4] <== after_position;

    init_hash <== hash_init.out;
    
    component prev_hash_init = Poseidon(5);
    prev_hash_init.inputs[0] <== prev_after_status;
    prev_hash_init.inputs[1] <== prev_after_block;
    prev_hash_init.inputs[2] <== prev_after_send;
    prev_hash_init.inputs[3] <== prev_after_inbox;
    prev_hash_init.inputs[4] <== prev_after_position;

    signal exec_hash_cmp;
    exec_hash_cmp <== init_hash - prev_hash_init.out;
    component exec_hash_same = IsZero();
    exec_hash_same.in <== exec_hash_cmp;

    exec_hash_same.out === 0;
    // maybe should construct better initial state here
}

component main = Main();
