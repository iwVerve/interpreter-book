Zig implementation (and expansion) of [Writing An Interpreter In Go](https://interpreterbook.com/)
with an overly eager mark-and-sweep garbage collector.

### Usage:
```
monkey.exe [path]
zig build run -- [path]
```

### Todo:
- Memory leaks on interpreter errors.
- Don't collect garbage literally always.
