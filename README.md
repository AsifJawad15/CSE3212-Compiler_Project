# CSE 3212 Compiler Design Project

Student: Asif Jawad  
Roll: 2107007

## Overview

This project implements a small custom language using:

- Flex for lexical analysis
- Bison for syntax analysis
- C helper modules for semantic checks, runtime behavior, intermediate code generation, and optimization

The compiler reads a source program from `test.txt`, optionally reads runtime values from `input.txt`, writes execution output to `testout.txt`, writes three-address code to `intermediate_code.txt`, and writes optimized three-address code to `optimized_code.txt`.

## Language Features

The current compiler supports:

- Types: `int`, `float`, `char`, `string`, `dict`, `stack`, `queue`
- I/O: `print(...)`, `read(...)`
- Arithmetic: `+`, `-`, `*`, `/`, `%`, `^`
- Math functions: `sqrt`, `abs`, `log`, `sin`, `cos`, `tan`
- Built-ins: `power`, `facto`, `checkprime`, `max`, `min`
- Control flow: `if`, `elif`, `otherwise`, `while`, `from ... to ... inc/dec ...`, `switch/state/complementary`
- User-defined functions
- Data-structure operations for dictionary, stack, and queue
- Three-address intermediate code generation
- Optimization pass with constant folding and simple strength reduction

## Repository Structure

### Core compiler files

- `2107007.l` - Flex lexer specification
- `2107007.y` - Bison grammar and parser actions
- `Makefile` - build, run, and clean commands

### Header files

- `include/common.h` - shared types and core structs
- `include/parser_ctx.h` - parser-wide execution and ICG state
- `include/actions.h` - semantic action helper declarations
- `include/semantic.h` - semantic checking helpers
- `include/symtab.h` - variable symbol table interface
- `include/tac.h` - three-address code interface
- `include/runtime.h` - stack and queue runtime helpers
- `include/io_runtime.h` - typed print/read runtime helpers
- `include/functab.h` - function table interface

### Source files

- `src/main.c` - compiler entry point
- `src/actions.c` - main semantic action implementations
- `src/tac.c` - temporary generation, label generation, TAC storage, optimization
- `src/semantic.c` - semantic checking rules
- `src/symtab.c` - variable symbol table storage and lookup
- `src/runtime.c` - stack and queue low-level operations
- `src/io_runtime.c` - typed output and input handling
- `src/functab.c` - user-defined function table storage

### Examples

- `examples/` contains sample programs and expected outputs for major language features

## Build and Run

### Prerequisites

Install these tools first:

- `flex`
- `bison`
- `gcc`

### Build and run with Make

```bash
make
```

This will:

1. generate `2107007.tab.c` and `2107007.tab.h` from `2107007.y`
2. generate `lex.yy.c` from `2107007.l`
3. compile the project into `parser.exe`
4. run `parser.exe`

### Clean generated files

```bash
make clean
```

## How Input Works

### Source program

The compiler always reads the program source from:

- `test.txt`

### Runtime input for `read(...)`

If your program uses `read(...)`, the compiler looks for:

- `input.txt`

If `input.txt` is not found, the program falls back to standard input.

## Output Files

After running the compiler, these files are produced:

- `testout.txt` - visible execution output of the program
- `intermediate_code.txt` - generated three-address intermediate code
- `optimized_code.txt` - optimized intermediate code

Generated parser/lexer files may also appear:

- `2107007.tab.c`
- `2107007.tab.h`
- `lex.yy.c`

## Running Your Own Program

1. Put your source code in `test.txt`
2. If needed, put runtime values in `input.txt`
3. Run:

```bash
make
```

Or, if `parser.exe` already exists:

```bash
parser.exe
```

Then inspect:

- `testout.txt`
- `intermediate_code.txt`
- `optimized_code.txt`

## Notes

- The project currently executes many actions during parsing, so it behaves like a compiler plus a small interpreter
- `verbose` is set in `src/main.c` and controls how much trace-style output appears
- Sample programs in `examples/` are the easiest way to explore the language behavior quickly
