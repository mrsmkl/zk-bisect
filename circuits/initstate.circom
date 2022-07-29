pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template Main() {
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

    signal output assertion_hash;
    signal output machine_hash;

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

    component hash_state = Poseidon(4);
    hash_state.inputs[0] <== before_block;
    hash_state.inputs[1] <== before_send;
    hash_state.inputs[2] <== before_inbox;
    hash_state.inputs[3] <== before_position;

    component hash_machine = Poseidon(9);
    // stacks
    hash_machine.inputs[0] <== 0;
    hash_machine.inputs[1] <== 0;
    hash_machine.inputs[2] <== 0;
    hash_machine.inputs[3] <== 0;
    hash_machine.inputs[4] <== hash_state.out;
    // PC
    hash_machine.inputs[5] <== 0;
    hash_machine.inputs[6] <== 0;
    hash_machine.inputs[7] <== 0;
    hash_machine.inputs[8] <== wasm_root;
    machine_hash <== hash_machine.out;

}

component main = Main();
