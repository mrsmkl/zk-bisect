pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// what is the state?
// * first step
// * last step
// * first hash
// * last hash
// There should be some kind of salt to hide the encrypted stuff ...
// Round number should be known anyway

// Constructing state from the node data?
// figure out what is empty stack hash: 0

template Main() {
	signal input step1_L_in;
	signal input step1_R_in;
	signal input step2_L_in;
	signal input step2_R_in;
	signal input step3_L_in;
	signal input step3_R_in;

	signal input hash1_L_in;
	signal input hash1_R_in;
	signal input hash2_L_in;
	signal input hash2_R_in;
	signal input hash3_L_in;
	signal input hash3_R_in;

	signal input sender_k;

	signal input difference[64];
	signal input difference_round;

	signal input sender_x;
	signal input sender_y;
	signal input other_x;
	signal input other_y;

	signal input cipher_step1_L_in;
	signal input cipher_step1_R_in;
	signal input cipher_step2_L_in;
	signal input cipher_step2_R_in;
	signal input cipher_step3_L_in;
	signal input cipher_step3_R_in;

	signal input cipher_hash1_L_in;
	signal input cipher_hash1_R_in;
	signal input cipher_hash2_L_in;
	signal input cipher_hash2_R_in;
	signal input cipher_hash3_L_in;
	signal input cipher_hash3_R_in;

	signal input hash_state_in;

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

	// input for final state
    signal input value_stack;
    signal input internal_stack;
    signal input block_stack;
    signal input frame_stack;
    signal input module_idx;
    signal input function_idx;
    signal input function_pc;
	signal output sender_x_out;
	signal output sender_y_out;
	signal output other_x_out;
	signal output other_y_out;

	signal output cipher_step1_L_in_out;
	signal output cipher_step1_R_in_out;
	signal output cipher_step2_L_in_out;
	signal output cipher_step2_R_in_out;
	signal output cipher_step3_L_in_out;
	signal output cipher_step3_R_in_out;

	signal output cipher_hash1_L_in_out;
	signal output cipher_hash1_R_in_out;
	signal output cipher_hash2_L_in_out;
	signal output cipher_hash2_R_in_out;
	signal output cipher_hash3_L_in_out;
	signal output cipher_hash3_R_in_out;

	signal output hash_state_out;
	signal output assertion_hash;

/*
	sender_x_out <== 8911751603281566160452710943246074761822317551823405301307348714667359009192;
	sender_x === 8911751603281566160452710943246074761822317551823405301307348714667359009192;
*/

	var i;


	// Initial step has to be zero, final has to be larger
	component bits = Bits2Num(64);
    for (i=0; i<64; i++) {
		difference[i] * (difference[i]-1) === 0;
		bits.in[i] <== difference[i];
    }

	difference_round * (difference_round-1) === 0;

	step1_L_in === 0;
	step2_L_in === step1_L_in + bits.out + 1;
	step3_L_in === step2_L_in + bits.out + difference_round;

	component snum2bits = Num2Bits(253);
    snum2bits.in <== sender_k;

	// compute secret key (ECDH)
	component mulAny = EscalarMulAny(253);
    for (i=0; i<253; i++) {
        mulAny.e[i] <== snum2bits.out[i];
    }
	mulAny.p[0] <== other_x;
	mulAny.p[1] <== other_y;

	// check sender public key matches to private key
	var BASE8[2] = [
        5299619240641551281634865583518297030282874472190772894086521144482721001553,
        16950150798460657717958625567821834550301663161624707787222815936182638968203
    ];
    component mulFix = EscalarMulFix(253, BASE8);
    for (i=0; i<253; i++) {
        mulFix.e[i] <== snum2bits.out[i];
    }

	mulFix.out[0] === sender_x;
	mulFix.out[1] === sender_y;

	// encrypt and hash
	component encrypt_step1 = MiMCFeistel(220);
	encrypt_step1.xL_in <== step1_L_in;
	encrypt_step1.xR_in <== step1_R_in;
	encrypt_step1.k <== mulAny.out[0];

	component encrypt_step2 = MiMCFeistel(220);
	encrypt_step2.xL_in <== step2_L_in;
	encrypt_step2.xR_in <== step2_R_in;
	encrypt_step2.k <== mulAny.out[0];

	component encrypt_step3 = MiMCFeistel(220);
	encrypt_step3.xL_in <== step3_L_in;
	encrypt_step3.xR_in <== step3_R_in;
	encrypt_step3.k <== mulAny.out[0];

	component encrypt_hash1 = MiMCFeistel(220);
	encrypt_hash1.xL_in <== hash1_L_in;
	encrypt_hash1.xR_in <== hash1_R_in;
	encrypt_hash1.k <== mulAny.out[0];

	component encrypt_hash2 = MiMCFeistel(220);
	encrypt_hash2.xL_in <== hash2_L_in;
	encrypt_hash2.xR_in <== hash2_R_in;
	encrypt_hash2.k <== mulAny.out[0];

	component encrypt_hash3 = MiMCFeistel(220);
	encrypt_hash3.xL_in <== hash3_L_in;
	encrypt_hash3.xR_in <== hash3_R_in;
	encrypt_hash3.k <== mulAny.out[0];

	component hash_state = Poseidon(7);
	hash_state.inputs[0] <== step1_L_in;
	hash_state.inputs[1] <== step2_L_in;
	hash_state.inputs[2] <== step3_L_in;
	hash_state.inputs[3] <== hash1_L_in;
	hash_state.inputs[4] <== hash2_L_in;
	hash_state.inputs[5] <== hash3_L_in;
	hash_state.inputs[6] <== step1_R_in;

	cipher_step1_L_in_out <== encrypt_step1.xL_out;
	cipher_step1_R_in_out <== encrypt_step1.xR_out;
	cipher_step2_L_in_out <== encrypt_step2.xL_out;
	cipher_step2_R_in_out <== encrypt_step2.xR_out;
	cipher_step3_L_in_out <== encrypt_step3.xL_out;
	cipher_step3_R_in_out <== encrypt_step3.xR_out;

	cipher_hash1_L_in_out <== encrypt_hash1.xL_out;
	cipher_hash1_R_in_out <== encrypt_hash1.xR_out;
	cipher_hash2_L_in_out <== encrypt_hash2.xL_out;
	cipher_hash2_R_in_out <== encrypt_hash2.xR_out;
	cipher_hash3_L_in_out <== encrypt_hash3.xL_out;
	cipher_hash3_R_in_out <== encrypt_hash3.xR_out;

	other_x_out <== other_x;
	other_y_out <== other_y;
	sender_x_out <== sender_x;
	sender_y_out <== sender_y;
	hash_state_out <== hash_state.out;

	cipher_step1_L_in_out === cipher_step1_L_in;
	cipher_step2_L_in_out === cipher_step2_L_in;
	cipher_step3_L_in_out === cipher_step3_L_in;

	cipher_hash1_L_in_out === cipher_hash1_L_in;
	cipher_hash2_L_in_out === cipher_hash2_L_in;
	cipher_hash3_L_in_out === cipher_hash3_L_in;

	cipher_step1_R_in_out === cipher_step1_R_in;
	cipher_step2_R_in_out === cipher_step2_R_in;
	cipher_step3_R_in_out === cipher_step3_R_in;

	cipher_hash1_R_in_out === cipher_hash1_R_in;
	cipher_hash2_R_in_out === cipher_hash2_R_in;
	cipher_hash3_R_in_out === cipher_hash3_R_in;

	hash_state_in === hash_state_out;

	// check that it's correct with assertion
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

    component hash_init_state = Poseidon(4);
    hash_init_state.inputs[0] <== before_block;
    hash_init_state.inputs[1] <== before_send;
    hash_init_state.inputs[2] <== before_inbox;
    hash_init_state.inputs[3] <== before_position;

    component hash_final_state = Poseidon(4);
    hash_final_state.inputs[0] <== after_block;
    hash_final_state.inputs[1] <== after_send;
    hash_final_state.inputs[2] <== after_inbox;
    hash_final_state.inputs[3] <== after_position;

    component hash_machine = Poseidon(9);
    // stacks
    hash_machine.inputs[0] <== 0;
    hash_machine.inputs[1] <== 0;
    hash_machine.inputs[2] <== 0;
    hash_machine.inputs[3] <== 0;
    hash_machine.inputs[4] <== hash_init_state.out;
    // PC
    hash_machine.inputs[5] <== 0;
    hash_machine.inputs[6] <== 0;
    hash_machine.inputs[7] <== 0;
    hash_machine.inputs[8] <== wasm_root;

    component hash_final = Poseidon(9);
    // stacks
    hash_final.inputs[0] <== value_stack;
    hash_final.inputs[1] <== internal_stack;
    hash_final.inputs[2] <== block_stack;
    hash_final.inputs[3] <== frame_stack;
    hash_final.inputs[4] <== hash_state.out;
    // PC
    hash_final.inputs[5] <== module_idx;
    hash_final.inputs[6] <== function_idx;
    hash_final.inputs[7] <== function_pc;
    hash_final.inputs[8] <== wasm_root;

	hash1_L_in === hash_machine.out;
	hash3_L_in === hash_final.out;

}

component main = Main();
