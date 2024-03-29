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

	signal input prev_step1_L_in;
	signal input prev_step1_R_in;
	signal input prev_step2_L_in;
	signal input prev_step3_L_in;

	signal input prev_hash1_L_in;
	signal input prev_hash2_L_in;
	signal input prev_hash3_L_in;

	signal input sender_k;

	// true if chose the first segment
	signal input choose_L_in;
	signal input choose_R_in;

	signal input difference[64];
	signal input difference_eq[64];
	signal input difference_choose;
	signal input difference_round;
	signal input steps_equal;
	signal input choose_bits[254];

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

	signal input cipher_choose_L_in;
	signal input cipher_choose_R_in;

	signal input hash_state_in;
	signal input prev_hash_state_in;

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

	signal output cipher_choose_L_in_out;
	signal output cipher_choose_R_in_out;

	signal output hash_state_out;
	signal output prev_hash_state_out;

	var i;

	////////////////////
	difference_round * (difference_round-1) === 0;
	steps_equal * (steps_equal-1) === 0;
	difference_choose * (difference_choose-1) === 0;
	component bits = Bits2Num(64);
    for (i=0; i<64; i++) {
		difference[i] * (difference[i]-1) === 0;
		bits.in[i] <== difference[i];
    }
	component bits_eq = Bits2Num(64);
    for (i=0; i<64; i++) {
		difference_eq[i] * (difference_eq[i]-1) === 0;
		bits_eq.in[i] <== difference_eq[i];
    }
	component bits_choose = Bits2Num_strict();
    for (i=0; i<254; i++) {
		choose_bits[i] * (choose_bits[i]-1) === 0;
		bits_choose.in[i] <== choose_bits[i];
    }
	difference_choose === choose_bits[0];
	bits_choose.out === choose_L_in;

	// step1 < step2 <= step3
	signal step1_choose;
	signal step2_choose;
	step1_choose <== (1-difference_choose) * prev_step1_L_in;
	step1_L_in === step1_choose + difference_choose * prev_step2_L_in;
	step2_L_in === step1_L_in + bits.out + 1;
	step3_L_in === step2_L_in + bits.out - difference_round;
	step2_choose <== (1-difference_choose) * prev_step2_L_in;
	step3_L_in === step2_choose + difference_choose * prev_step3_L_in;

	// Another one of the hashes changes (choose)
	// choose == true if first step changed
	signal selected_hash1;
	selected_hash1 <== (1-difference_choose) * prev_hash1_L_in;
	selected_hash1 === (1-difference_choose) * hash1_L_in;
	signal selected_hash2;
	selected_hash2 <== (1-difference_choose) * prev_hash2_L_in;
	selected_hash2 === (1-difference_choose) * hash3_L_in;
	signal selected_hash3;
	selected_hash3 <== difference_choose * prev_hash2_L_in;
	selected_hash3 === difference_choose * hash1_L_in;
	signal selected_hash4;
	selected_hash4 <== difference_choose * prev_hash3_L_in;
	selected_hash4 === difference_choose * hash3_L_in;

	signal eq_step2;
	eq_step2 <== steps_equal*step2_L_in;
	eq_step2 === steps_equal*step3_L_in;
	signal eq_hash2;
	eq_hash2 <== steps_equal*hash2_L_in;
	eq_hash2 === steps_equal*hash3_L_in;
	// if step_equal == false, then steps must be different
	(1-steps_equal)*(1+bits_eq.out) + step2_L_in === step3_L_in;

	///////////
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

	component encrypt_choose = MiMCFeistel(220);
	encrypt_choose.xL_in <== choose_L_in;
	encrypt_choose.xR_in <== choose_R_in;
	encrypt_choose.k <== mulAny.out[0];

	component hash_state = Poseidon(7);
	hash_state.inputs[0] <== step1_L_in;
	hash_state.inputs[1] <== step2_L_in;
	hash_state.inputs[2] <== step3_L_in;
	hash_state.inputs[3] <== hash1_L_in;
	hash_state.inputs[4] <== hash2_L_in;
	hash_state.inputs[5] <== hash3_L_in;
	hash_state.inputs[6] <== step1_R_in;

	component prev_hash_state = Poseidon(7);
	prev_hash_state.inputs[0] <== prev_step1_L_in;
	prev_hash_state.inputs[1] <== prev_step2_L_in;
	prev_hash_state.inputs[2] <== prev_step3_L_in;
	prev_hash_state.inputs[3] <== prev_hash1_L_in;
	prev_hash_state.inputs[4] <== prev_hash2_L_in;
	prev_hash_state.inputs[5] <== prev_hash3_L_in;
	prev_hash_state.inputs[6] <== prev_step1_R_in;

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

	cipher_choose_L_in_out <== encrypt_choose.xL_out;
	cipher_choose_R_in_out <== encrypt_choose.xR_out;

	other_x_out <== other_x;
	other_y_out <== other_y;
	sender_x_out <== sender_x;
	sender_y_out <== sender_y;

	hash_state_out <== hash_state.out;
	prev_hash_state_out <== prev_hash_state.out;

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

	cipher_choose_L_in_out === cipher_choose_L_in;
	cipher_choose_R_in_out === cipher_choose_R_in;

	hash_state_in === hash_state_out;
	prev_hash_state_in === prev_hash_state_out;
}

component main = Main();
