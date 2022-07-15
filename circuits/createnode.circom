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

    signal input salt;

    // Previous Assertion data
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

    signal input position_diff[200];
    signal input extra_inbox[64];

    signal input current_inbox_size;

    signal input before_inbox_small[64];
    signal input before_position_small[64];
    signal input after_inbox_small[64];
    signal input after_position_small[64];

    // Need to know that correct secret is used
    signal output secret_hash;
    signal output salt_out;

    // Assertion data (encrypted)
    signal output num_blocks_out;
    signal output inbox_max_out;
    signal output before_status_out;
    signal output before_block_out;
    signal output before_send_out;
    signal output before_inbox_out;
    signal output before_position_out;
    signal output after_status_out;
    signal output after_block_out;
    signal output after_send_out;
    signal output after_inbox_out;
    signal output after_position_out;

    signal output assertion_hash;
    signal output prev_assertion_hash;

    signal output current_inbox_size_out;

    var i;

    // Machine status must be finished or error
    (after_status - 1)*(after_status - 2) === 0;

    // previous state matches
    before_status === prev_after_status;
    before_block === prev_after_block;
    before_send === prev_after_send;
    before_inbox === prev_after_inbox;
    before_position === prev_after_position;

    // compare before and after for inbox
    component position_diff_num = Bits2Num(200);
    for (i=0; i<200; i++) {
		position_diff[i] * (position_diff[i]-1) === 0;
		position_diff_num.in[i] <== position_diff[i];
    }

    component extra_inbox_num = Bits2Num(64);
    for (i=0; i<64; i++) {
		extra_inbox[i] * (extra_inbox[i]-1) === 0;
		extra_inbox_num.in[i] <== extra_inbox[i];
    }

    signal pos_before;
    signal pos_after;

    pos_before <== before_inbox * (2**100) + before_position;
    pos_after <== after_inbox * (2**100) + after_position;

    pos_before + position_diff_num.out === pos_after;

    // will be one if the status was error, zero if was finished
    signal one_if_error;
    one_if_error <== after_status - 1;

    // will be one if position is zero, zero otherwise
    /*
    signal one_if_position;
    signal tmp;
    tmp <== ;
    one_if_position <== ;
    */

    current_inbox_size === after_inbox + extra_inbox_num.out + one_if_error;

    // Checks that all positions are small
    component before_inbox_num = Bits2Num(64);
    for (i=0; i<64; i++) {
		before_inbox_small[i] * (before_inbox_small[i]-1) === 0;
		before_inbox_num.in[i] <== before_inbox_small[i];
    }
    before_inbox_num.out === before_inbox;

    component before_position_num = Bits2Num(64);
    for (i=0; i<64; i++) {
		before_position_small[i] * (before_position_small[i]-1) === 0;
		before_position_num.in[i] <== before_position_small[i];
    }
    before_position_num.out === before_position;

    component after_inbox_num = Bits2Num(64);
    for (i=0; i<64; i++) {
	    after_inbox_small[i] * (after_inbox_small[i]-1) === 0;
		after_inbox_num.in[i] <== after_inbox_small[i];
    }
    after_inbox_num.out === after_inbox;

    component after_position_num = Bits2Num(64);
    for (i=0; i<64; i++) {
		after_position_small[i] * (after_position_small[i]-1) === 0;
		after_position_num.in[i] <== after_position_small[i];
    }
    after_position_num.out === after_position;

    // encrypt the assertion, where to put salt
    component encrypt_num_blocks = MiMCFeistel(220);
	encrypt_num_blocks.xL_in <== num_blocks;
	encrypt_num_blocks.xR_in <== salt;
	encrypt_num_blocks.k <== secret;
	num_blocks_out <== encrypt_num_blocks.xL_out;

    component encrypt_inbox_max = MiMCFeistel(220);
	encrypt_inbox_max.xL_in <== inbox_max;
	encrypt_inbox_max.xR_in <== encrypt_num_blocks.xR_out;
	encrypt_inbox_max.k <== secret;
	inbox_max_out <== encrypt_inbox_max.xL_out;

    component encrypt_before_status = MiMCFeistel(220);
	encrypt_before_status.xL_in <== before_status;
	encrypt_before_status.xR_in <== encrypt_inbox_max.xR_out;
	encrypt_before_status.k <== secret;
	before_status_out <== encrypt_before_status.xL_out;

    component encrypt_before_block = MiMCFeistel(220);
	encrypt_before_block.xL_in <== before_block;
	encrypt_before_block.xR_in <== encrypt_before_status.xR_out;
	encrypt_before_block.k <== secret;
	before_block_out <== encrypt_before_block.xL_out;

    component encrypt_before_send = MiMCFeistel(220);
	encrypt_before_send.xL_in <== before_send;
	encrypt_before_send.xR_in <== encrypt_before_block.xR_out;
	encrypt_before_send.k <== secret;
	before_send_out <== encrypt_before_send.xL_out;

    component encrypt_before_inbox = MiMCFeistel(220);
	encrypt_before_inbox.xL_in <== before_inbox;
	encrypt_before_inbox.xR_in <== encrypt_before_send.xR_out;
	encrypt_before_inbox.k <== secret;
	before_inbox_out <== encrypt_before_inbox.xL_out;

    component encrypt_before_position = MiMCFeistel(220);
	encrypt_before_position.xL_in <== before_position;
	encrypt_before_position.xR_in <== encrypt_before_inbox.xR_out;
	encrypt_before_position.k <== secret;
	before_position_out <== encrypt_before_position.xL_out;

    component encrypt_after_status = MiMCFeistel(220);
	encrypt_after_status.xL_in <== after_status;
	encrypt_after_status.xR_in <== encrypt_before_position.xR_out;
	encrypt_after_status.k <== secret;
	after_status_out <== encrypt_after_status.xL_out;

    component encrypt_after_block = MiMCFeistel(220);
	encrypt_after_block.xL_in <== after_block;
	encrypt_after_block.xR_in <== encrypt_after_status.xR_out;
	encrypt_after_block.k <== secret;
	after_block_out <== encrypt_after_block.xL_out;

    component encrypt_after_send = MiMCFeistel(220);
	encrypt_after_send.xL_in <== after_send;
	encrypt_after_send.xR_in <== encrypt_after_block.xR_out;
	encrypt_after_send.k <== secret;
	after_send_out <== encrypt_after_send.xL_out;

    component encrypt_after_inbox = MiMCFeistel(220);
	encrypt_after_inbox.xL_in <== after_inbox;
	encrypt_after_inbox.xR_in <== encrypt_after_send.xR_out;
	encrypt_after_inbox.k <== secret;
	after_inbox_out <== encrypt_after_inbox.xL_out;

    component encrypt_after_position = MiMCFeistel(220);
	encrypt_after_position.xL_in <== after_position;
	encrypt_after_position.xR_in <== encrypt_after_inbox.xR_out;
	encrypt_after_position.k <== secret;
	after_position_out <== encrypt_after_position.xL_out;
    salt_out <== encrypt_after_position.xR_out;

    // Handle hashing the secret
    component hash_secret = Poseidon(1);
    hash_secret.inputs[0] <== secret;
    secret_hash <== hash_secret.out;

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

    component prev_hash_assertion = Poseidon(12);
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
    prev_assertion_hash <== prev_hash_assertion.out;

    current_inbox_size_out <== current_inbox_size;

}

component main = Main();
