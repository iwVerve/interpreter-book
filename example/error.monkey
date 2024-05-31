let string = "A string";
let log = fn(message) {
    let message = "LOG: " + @string(message);
    @print(message);
};

log(string);
let n = 1;
while (n < 6) {
    log(n);
    n = n + 1;
}

let throw_error = fn(value, num) {
    if (num == 0) {
        throw_error(value, 1);
    }
    else {
        error(error());
    }
};

throw_error("asdf", 0);
