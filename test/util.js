
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

module.exports = {
    num2bits,
    num2fullbits,
}