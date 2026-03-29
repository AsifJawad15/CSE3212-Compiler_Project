# Let Me Introduce You to This Compiler

This compiler accepts a small custom language.

## Program shape

Every program starts like this:

```txt
using std.h

start() {
    print("Hello");
}
```

## Core rules

- `start()` is the main function
- End each statement with `;`
- Use `{` and `}` for blocks
- Comments start with `#`

## Data types

- `int`
- `float`
- `char`
- `string`
- `dict`
- `stack`
- `queue`

## Output

- `print("text");` prints text directly
- `print(name);` prints a variable

## Conditions

```txt
if(marks >= 80) {
    print("Grade A");
} otherwise {
    print("Other grade");
}
```

## Loops

```txt
from i to 4 inc 1 {
    print(i);
}
```

## Math

- `sqrt(x)`
- `abs(x)`
- `log(x)`
- `sin(x)`
- `cos(x)`
- `tan(x)`
- `x ^ 2`

## Important note about output

This compiler currently prints debug-style internal messages for declarations, assignments, loops, and some expressions.

Because of that:

- `01_intro.txt` gives the cleanest raw output
- the other `*_output.txt` files show the clean expected user-facing result only
- raw `testout.txt` may contain extra compiler trace lines

## Recommended learning order

1. `01_intro.txt`
2. `02_variables.txt`
3. `03_condition.txt`
4. `05_math.txt`
5. `04_loop.txt`