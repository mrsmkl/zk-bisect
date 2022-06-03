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

	signal input other_x;
	signal input other_y;
	signal input sender_x;
	signal input sender_y;

	signal output other_x_out;
	signal output other_y_out;
	signal output sender_x_out;
	signal output sender_y_out;

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

	// true if chose the first segment
	signal input choose_L_in;
	signal input choose_R_in;

	signal output hash_state_out;
	signal output prev_hash_state_out;

	signal input difference[64];
	signal input difference_eq[64];
	signal input difference_choose;
	signal input difference_round;

	var i;

	////////////////////
	difference_choose === choose_L_in;
	difference_round * (difference_round-1) === 0;
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
	step1_L_in === prev_step1_L_in + bits.out * difference_choose;
	step2_L_in === step1_L_in + bits.out + difference_round + 1;
	prev_step2_L_in === prev_step1_L_in + 2*bits.out + difference_round + 1;

	// Another one of the hashes changes (choose)
	// choose == true if first step changed
	signal selected_hash1;
	selected_hash1 <== (1-difference_choose) * prev_hash1_L_in;
	selected_hash1 === (1-difference_choose) * hash1_L_in;
	signal selected_hash2;
	selected_hash2 <== difference_choose * prev_hash2_L_in;
	selected_hash2 === difference_choose * hash2_L_in;


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
	cipher_step1_L_in_out <== encrypt_step1.xL_out;
	cipher_step1_R_in_out <== encrypt_step1.xR_out;

	component encrypt_step2 = MiMCFeistel(220);
	encrypt_step2.xL_in <== step2_L_in;
	encrypt_step2.xR_in <== step2_R_in;
	encrypt_step2.k <== mulAny.out[0];
	cipher_step2_L_in_out <== encrypt_step2.xL_out;
	cipher_step2_R_in_out <== encrypt_step2.xR_out;

	component encrypt_step3 = MiMCFeistel(220);
	encrypt_step3.xL_in <== step3_L_in;
	encrypt_step3.xR_in <== step3_R_in;
	encrypt_step3.k <== mulAny.out[0];
	cipher_step3_L_in_out <== encrypt_step3.xL_out;
	cipher_step3_R_in_out <== encrypt_step3.xR_out;

	component encrypt_hash1 = MiMCFeistel(220);
	encrypt_hash1.xL_in <== hash1_L_in;
	encrypt_hash1.xR_in <== hash1_R_in;
	encrypt_hash1.k <== mulAny.out[0];
	cipher_hash1_L_in_out <== encrypt_hash1.xL_out;
	cipher_hash1_R_in_out <== encrypt_hash1.xR_out;

	component encrypt_hash2 = MiMCFeistel(220);
	encrypt_hash2.xL_in <== hash2_L_in;
	encrypt_hash2.xR_in <== hash2_R_in;
	encrypt_hash2.k <== mulAny.out[0];
	cipher_hash2_L_in_out <== encrypt_hash2.xL_out;
	cipher_hash2_R_in_out <== encrypt_hash2.xR_out;

	component encrypt_hash3 = MiMCFeistel(220);
	encrypt_hash3.xL_in <== hash3_L_in;
	encrypt_hash3.xR_in <== hash3_R_in;
	encrypt_hash3.k <== mulAny.out[0];
	cipher_hash3_L_in_out <== encrypt_hash3.xL_out;
	cipher_hash3_R_in_out <== encrypt_hash3.xR_out;

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

	other_x_out <== other_x;
	other_y_out <== other_y;
	sender_x_out <== sender_x;
	sender_y_out <== sender_y;
	hash_state_out <== hash_state.out;
	prev_hash_state_out <== prev_hash_state.out;
}

component main = Main();
