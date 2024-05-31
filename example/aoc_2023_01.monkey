let input_path = "aoc_2023_01.txt";
let file = @file(input_path);

let start = @ord("0");
let end = @ord("9");

let sum = 0;

let line = @readLine(file);
while (line != null) {
    let first = null;
    let last = null;
    let pos = 0;
    
    while (pos < @len(line)) {
        let char = @charAt(line, pos);
        let ord = @ord(char);
        if (ord > start - 1) if (ord < end + 1) {
            let number = ord - start;
            if (first == null) {
                first = number;
            }
            last = number;
        }

        pos = pos + 1;
    }

    sum = sum + 10 * first + last;
    line = @readLine(file);
}

@print(sum);
