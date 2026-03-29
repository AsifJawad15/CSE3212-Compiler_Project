# Beginner Examples for the CSE-3212 Compiler

These examples are written for the compiler in this folder.

## Start here

- Read `LANGUAGE_FIRST_GUIDE.md` first if you want to learn the language before the implementation.
- Then use the example files in this folder one by one.

## Basic syntax

- Program starts with `using std.h`
- Main block is `start() { ... }`
- Print text with `print("text")`
- Statements end with `;`

## Example list

1. `01_intro.txt` - first program with text output
2. `02_variables.txt` - integer, float, char, and string variables
3. `03_condition.txt` - simple `if ... otherwise`
4. `04_loop.txt` - `from ... to ... inc ...` loop
5. `05_math.txt` - `sqrt()` and power operator `^`
6. `06_while.txt` - basic `while` syntax
7. `07_elif.txt` - `if ... elif ... otherwise`
8. `08_stack.txt` - stack operations
9. `09_queue.txt` - queue operations
10. `10_dict.txt` - dictionary operations
11. `11_algorithm_factorial.txt` - built-in factorial example

Each example has a matching `*_output.txt` file with the clean expected output only.

See `FLOW.md` for the full path from source code to runtime output.

Notes:

- some examples still produce extra compiler trace lines in `testout.txt`
- `06_while.txt` demonstrates the accepted syntax, but the current while implementation does not repeatedly execute like a full interpreter loop
- stack, queue, and dictionary examples rely on built-in operation messages for their visible output

## How to run one example

The current compiler reads from `test.txt` and writes to `testout.txt`.

To try an example manually, copy one example into `test.txt`, run `parser.exe`, then compare the first user-facing lines of `testout.txt` with the matching output file here.
