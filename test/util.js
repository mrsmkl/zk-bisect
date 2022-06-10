
function num2bits(num) {
    let res = []
    for (let i = 0; i < 64; i++) {
        res.push(num % 2)
        num = Math.floor(num / 2)
    }
    return res
}

module.exports = {
    num2bits,
}