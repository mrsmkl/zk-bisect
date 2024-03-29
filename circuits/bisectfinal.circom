pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// Finalize bisection

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

	signal input sender_x;
	signal input sender_y;
	signal input other_x;
	signal input other_y;

	signal input cipher_step1_L_in;
	signal input cipher_step1_R_in;
	signal input cipher_step2_L_in;
	signal input cipher_step2_R_in;

	signal input cipher_hash1_L_in;
	signal input cipher_hash1_R_in;
	signal input cipher_hash2_L_in;
	signal input cipher_hash2_R_in;

	signal input hash_state_in;

	signal output sender_x_out;
	signal output sender_y_out;
	signal output other_x_out;
	signal output other_y_out;

	signal output cipher_step1_L_in_out;
	signal output cipher_step1_R_in_out;
	signal output cipher_step2_L_in_out;
	signal output cipher_step2_R_in_out;

	signal output cipher_hash1_L_in_out;
	signal output cipher_hash1_R_in_out;
	signal output cipher_hash2_L_in_out;
	signal output cipher_hash2_R_in_out;

	signal output hash_state_out;
	signal output hash_secret_out;

	var i;

	// In the end, we must have found the correct step
	step2_L_in === step1_L_in + 1;

	// compute secret key (ECDH)
	component snum2bits = Num2Bits(253);
    snum2bits.in <== sender_k;
	
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

	component encrypt_hash1 = MiMCFeistel(220);
	encrypt_hash1.xL_in <== hash1_L_in;
	encrypt_hash1.xR_in <== hash1_R_in;
	encrypt_hash1.k <== mulAny.out[0];

	component encrypt_hash2 = MiMCFeistel(220);
	encrypt_hash2.xL_in <== hash2_L_in;
	encrypt_hash2.xR_in <== hash2_R_in;
	encrypt_hash2.k <== mulAny.out[0];

	component hash_state = Poseidon(7);
	hash_state.inputs[0] <== step1_L_in;
	hash_state.inputs[1] <== step2_L_in;
	hash_state.inputs[2] <== step3_L_in;
	hash_state.inputs[3] <== hash1_L_in;
	hash_state.inputs[4] <== hash2_L_in;
	hash_state.inputs[5] <== hash3_L_in;
	hash_state.inputs[6] <== step1_R_in;

	component hash_secret = Poseidon(1);
	hash_secret.inputs[0] <== mulAny.out[0];

	cipher_step1_L_in_out <== encrypt_step1.xL_out;
	cipher_step1_R_in_out <== encrypt_step1.xR_out;
	cipher_step2_L_in_out <== encrypt_step2.xL_out;
	cipher_step2_R_in_out <== encrypt_step2.xR_out;

	cipher_hash1_L_in_out <== encrypt_hash1.xL_out;
	cipher_hash1_R_in_out <== encrypt_hash1.xR_out;
	cipher_hash2_L_in_out <== encrypt_hash2.xL_out;
	cipher_hash2_R_in_out <== encrypt_hash2.xR_out;

	other_x_out <== other_x;
	other_y_out <== other_y;
	sender_x_out <== sender_x;
	sender_y_out <== sender_y;
	hash_state_out <== hash_state.out;
	hash_secret_out <== hash_secret.out;

	cipher_step1_L_in_out === cipher_step1_L_in;
	cipher_step2_L_in_out === cipher_step2_L_in;

	cipher_hash1_L_in_out === cipher_hash1_L_in;
	cipher_hash2_L_in_out === cipher_hash2_L_in;

	cipher_step1_R_in_out === cipher_step1_R_in;
	cipher_step2_R_in_out === cipher_step2_R_in;

	cipher_hash1_R_in_out === cipher_hash1_R_in;
	cipher_hash2_R_in_out === cipher_hash2_R_in;

	hash_state_in === hash_state_out;
}

component main = Main();
