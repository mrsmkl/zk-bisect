
function num2bits(num) {
    let res = []
    for (let i = 0; i < 64; i++) {
        res.push(num % 2)
        num = Math.floor(num / 2)
    }
    return res
}

function num2fullbits(num) {
    let res = []
    for (let i = 0; i < 254; i++) {
        res.push(num % 2n)
        num = num / 2n
    }
    return res
}

function bisectRange(F, start, end) {
    let mid = start + Math.floor((end-start) / 2) + 1
    let difference = mid - start - 1
    let difference_eq = end - mid - 1
    let steps_equal = 0
    let difference_round = (start + 1 + 2*difference) - end
    if (difference_eq < 0) {
        difference_eq = 0
        steps_equal = 1
        mid = start+1
        end = mid
        difference = 0
        difference_round = 0
    }
    // console.log("steps", start, mid, end, "diff", difference, difference_eq, difference_round)
    return {
        prev_step1: F.e(start),
        prev_step2: F.e(end),
        prev_step3: F.e(start+10),
        step1: F.e(start),
        step2: F.e(mid),
        step3: F.e(end),
        difference_eq: num2bits(difference_eq),
        difference: num2bits(difference),
        difference_round,
        steps_equal,
    }
}

module.exports = {
    num2bits,
    num2fullbits,
    bisectRange,
}
