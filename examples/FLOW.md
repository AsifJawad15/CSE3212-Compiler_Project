# Full Flow of This Compiler

This compiler works in these stages:

## 1. Source code

You write a program in the custom language, for example:

```txt
using std.h

start() {
    float x = 16;
    float y = 0;
    y = x ^ 2;
    print(y);
}
```

## 2. Lexical analysis

The lexer reads characters from `test.txt` and turns them into tokens.

Examples:

- `float` becomes a `FLOAT` token
- `start()` becomes a `MAIN` token
- `^` becomes a `POW` token
- `print` becomes a `PRINT` token

This step is defined in `2107007.l`.

## 3. Parsing

The parser checks whether the token stream follows the grammar.

Examples of grammar rules:

- program structure
- variable declaration
- assignment
- if / elif / otherwise
- loops
- stack, queue, and dictionary operations

This step is defined in `2107007.y`.

## 4. Semantic actions and runtime behavior

This project does not only parse.
It also executes many statements during parsing.

That means when the parser sees:

```txt
y = x ^ 2;
print(y);
```

it immediately:

- evaluates the expression
- stores the value in the variable table
- prints the runtime result to `testout.txt`

So `testout.txt` is the execution output of the original program, not the optimized code.

## 5. Intermediate code generation

While parsing, the compiler also writes three-address style intermediate code to `intermediate_code.txt`.

Example:

```txt
t1 = 16.000000 ^ 2.000000
y = 256.000000
print y
```

This is a lower-level representation of the program.

## 6. Optimization pass

After parsing finishes, the compiler runs a separate optimization pass.

It reads the stored intermediate-code lines and writes optimized results to `optimized_code.txt`.

Example:

```txt
t1 = 256    # folded from: t1 = 16.000000 ^ 2.000000
```

This is why the optimized code may show an integer-looking constant even when runtime output still prints a float variable.

## 7. Runtime output

Runtime output depends on the variable type used in the program.

For example:

- if `y` is `float`, the compiler prints it with `%f`
- if `y` is `int`, the compiler prints it with `%d`

So these two results can both be correct at the same time:

- optimized code: `t1 = 256`
- runtime output: `256.000000`

## Summary

The full pipeline is:

1. `test.txt`
2. tokens from lexer
3. grammar parsing
4. immediate execution + semantic checks
5. `intermediate_code.txt`
6. `optimized_code.txt`
7. visible program output in `testout.txt`