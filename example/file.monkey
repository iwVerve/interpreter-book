let file = @file("message.txt");
while (true) {
    let line = @readLine(file);
    if (line == null) {
        return 0;
    }
    @print(line);
}
