

function check_step({difference_choose, prev_step1_L_in, prev_step2_L_in, prev_step3_L_in, difference_round, difference}) {
    let step1_choose = (1-difference_choose) * prev_step1_L_in;
    let step1_L_in = step1_choose + difference_choose * prev_step2_L_in;
    let step2_L_in = step1_L_in + difference + 1;
    let step3_L_in = step2_L_in + difference - difference_round;
    let step2_choose = (1-difference_choose) * prev_step2_L_in;
    return {
        correct: step3_L_in === step2_choose + difference_choose * prev_step3_L_in,
        step1_L_in,
        step2_L_in,
        step3_L_in,
    }
}

console.log(
    check_step({
        difference_choose: 1,
        prev_step1_L_in: 1,
        prev_step2_L_in: 2,
        prev_step3_L_in: 3,
        difference_round: 0,
        difference: 0,
    })
)

console.log(
    check_step({
        difference_choose: 1,
        prev_step1_L_in: 10,
        prev_step2_L_in: 20,
        prev_step3_L_in: 29,
        difference_round: 0,
        difference: 4,
    })
)

function check_eq({steps_equal,step2_L_in,step3_L_in,difference_eq}) {
    return {
        eq_step: steps_equal*step2_L_in === steps_equal*step3_L_in,
        neq_step: (1-steps_equal)*(1+difference_eq) + step2_L_in === step3_L_in,
    }
}

console.log(
    check_eq({
        steps_equal: 0,
        step2_L_in: 2,
        step3_L_in: 10,
        difference_eq: 7,
    })
)

console.log(
    check_eq({
        steps_equal: 1,
        step2_L_in: 2,
        step3_L_in: 2,
        difference_eq: 7,
    })
)

