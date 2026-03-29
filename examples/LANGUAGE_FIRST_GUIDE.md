# Language-First Guide for This Compiler

This guide teaches the custom language as a beginner programming language first.

It does **not** explain lexer rules, parser rules, semantic actions, or intermediate code yet.
The goal is simple: learn how to read and write valid programs in this language.

## How to use this guide

For each lesson:

1. Read the tiny example.
2. Predict the output before looking at the answer.
3. Read the line-by-line explanation.
4. Learn the rule.
5. Watch for common mistakes.
6. Try the mini check yourself.

## Lesson 1: Program Shape and Output

### Tiny example

```txt
using std.h

start() {
    print("Hello, I am learning this compiler");
    print("The main block starts with start()");
    print("print() shows text output");
}
```

### Expected output

```txt
Hello, I am learning this compiler
The main block starts with start()
print() shows text output
```

### Line by line

- `using std.h`
  This is the standard opening line used in the beginner examples.
- `start() {`
  This begins the main program block.
- `print("...");`
  Each `print` shows one text line.
- `}`
  This ends the main block.

### General rule

- Start a beginner program with `using std.h`
- Put your program inside `start() { ... }`
- End each statement with `;`
- Use `print("text");` to show text

### Common mistakes

- Forgetting the semicolon at the end of `print(...)`
- Forgetting `{` or `}`
- Writing code outside `start()`
- Using single quotes for strings instead of double quotes

### Mini check

Write a program that prints:

```txt
I am ready
This is my first program
```

## Lesson 2: Variables and Literals

### Tiny example

```txt
using std.h

start() {
    int age = 21;
    float cgpa = 3.75;
    char grade = @A@;
    string name = "Rafi";

    print("Variable example");
    print(name);
    print(age);
    print(cgpa);
    print(grade);
}
```

### Expected output

```txt
Variable example
Rafi
21
3.750000
A
```

### Line by line

- `int age = 21;`
  Creates an integer variable.
- `float cgpa = 3.75;`
  Creates a floating-point variable.
- `char grade = @A@;`
  Character literals use `@A@` style in this language.
- `string name = "Rafi";`
  String values use double quotes.
- `print(name);`
  Prints a variable value.

### General rule

- Use `int` for whole numbers
- Use `float` for decimal numbers
- Use `char` for one character using `@x@`
- Use `string` for text using `"..." `
- Print a variable with `print(variableName);`

### Common mistakes

- Writing `char grade = 'A';` instead of `@A@`
- Forgetting quotes around a string
- Using a variable before declaring it
- Expecting `float` output to drop decimal places

### Mini check

Write a program that creates:

- an `int` called `year`
- a `float` called `temperature`
- a `char` called `section`
- a `string` called `city`

Then print all four.

## Lesson 3: Expressions and Math

### Tiny example

```txt
using std.h

start() {
    float x = 16;
    float y = 0;

    y = sqrt(x);
    print("Square root result");
    print(y);

    y = x ^ 2;
    print("Power result");
    print(y);
}
```

### Expected output

```txt
Square root result
4.000000
Power result
256.000000
```

### Line by line

- `float x = 16;`
  Stores the starting number.
- `float y = 0;`
  Creates a result variable.
- `y = sqrt(x);`
  Calculates the square root and stores it in `y`.
- `y = x ^ 2;`
  Raises `x` to the power `2`.

### General rule

- You can build expressions with `+`, `-`, `*`, `/`, `%`, and `^`
- You can use parentheses to control order
- Math functions like `sqrt(x)` can appear on the right side of an assignment
- A safe beginner pattern is:
  calculate into a variable first, then print the variable

### Common mistakes

- Writing `print(x ^ 2);` instead of storing the result first
- Forgetting that `%` is for remainder
- Using `^` as if it means multiplication
- Using `sqrt` without parentheses

### Mini check

Predict the output of this program before running it:

```txt
using std.h

start() {
    float a = 9;
    float b = 0;
    b = sqrt(a);
    print(b);
}
```

## Lesson 4: Decisions with `if` and `otherwise`

### Tiny example

```txt
using std.h

start() {
    int marks = 85;

    if(marks >= 80) {
        print("Grade A");
    } otherwise {
        print("Grade B or below");
    }
}
```

### Expected output

```txt
Grade A
```

### Line by line

- `if(marks >= 80) {`
  Checks whether the condition is true.
- `print("Grade A");`
  Runs only when the condition is true.
- `otherwise {`
  This is the language keyword used for the `else` case.

### General rule

- Use `if(condition) { ... }` for a true branch
- Use `otherwise { ... }` for the fallback branch
- Conditions often use `>`, `<`, `>=`, `<=`, `==`, `!=`

### Common mistakes

- Writing `else` instead of `otherwise`
- Forgetting parentheses around the condition
- Forgetting braces around the blocks
- Using `=` when you mean `==`

### Mini check

Write a program that prints:

- `"Pass"` if `score >= 40`
- `"Fail"` otherwise

## Lesson 5: `elif` Chains

### Tiny example

```txt
using std.h

start() {
    int marks = 72;

    if(marks >= 80) {
        print("Grade A");
    } elif(marks >= 70) {
        print("Grade B");
    } otherwise {
        print("Grade C");
    }
}
```

### Expected output

```txt
Grade B
```

### Line by line

- First the program checks `marks >= 80`
- If that is false, it checks `marks >= 70`
- If both are false, it goes to `otherwise`

### General rule

- Use `elif(...)` when you want another condition after `if`
- The first matching branch runs
- `otherwise` should be the final fallback

### Common mistakes

- Writing multiple separate `if` blocks when only one branch should run
- Putting `otherwise` before `elif`
- Forgetting that order matters in grade-style logic

### Mini check

What will this print if `marks = 65`?

```txt
if(marks >= 80) {
    print("A");
} elif(marks >= 70) {
    print("B");
} otherwise {
    print("C");
}
```

## Lesson 6: Loops

### Part A: `from ... to ... inc ...`

```txt
using std.h

start() {
    int i = 1;

    print("Loop output");
    from i to 4 inc 1 {
        print(i);
    }
}
```

### Expected output

```txt
Loop output
1
2
3
```

### What to notice

- `from i to 4 inc 1`
  means start from the current value of `i`
- In the example, the visible output stops before `4`
- This is the best beginner pattern to follow for counting loops

### General rule

- Use `from variable to limit inc step { ... }` to count upward
- Use `from variable to limit dec step { ... }` to count downward
- Declare and initialize the loop variable first

### Common mistakes

- Forgetting to declare the loop variable first
- Using a float as the loop variable
- Expecting the stop value to be printed in the same way as the example

### Part B: `while(...)`

```txt
using std.h

start() {
    int counter = 1;

    print("While loop example");
    while(counter < 3) {
        print(counter);
        counter++;
    }
}
```

### Expected output from the example set

```txt
While loop example
1
```

### Important beginner note

The language accepts `while(...) { ... }`, but the current compiler behavior shown in the examples is limited.
So you should learn the syntax now, but treat `from ... to ... inc/dec ...` as the more reliable beginner loop for practice.

### Mini check

Write a counting loop that prints `2`, `3`, and `4` using `from ... to ... inc ...`.

## Lesson 7: Built-in Functions

### Tiny example

```txt
using std.h

start() {
    print("Factorial example");
    facto(5);
}
```

### Expected output

```txt
Factorial example
Factorial of 5 is 120
```

### Other built-ins you should know

```txt
power(2, 8);
checkprime(29);
max(a, b);
min(a, b);
```

### General rule

- `sqrt`, `abs`, `log`, `sin`, `cos`, and `tan` fit naturally inside expressions
- `facto`, `power`, `checkprime`, `max`, and `min` are used like direct commands in the beginner examples

### Common mistakes

- Expecting every built-in to be used exactly like `sqrt(x)`
- Calling `max` or `min` with raw numbers instead of variable names
- Forgetting parentheses

### Mini check

Write a small program that:

- creates `int a = 9;`
- creates `int b = 15;`
- calls `max(a, b);`

## Lesson 8: Data Structures

### Part A: Stack

```txt
using std.h

start() {
    stack books;

    push(books, 10);
    push(books, 20);
    top(books);
    stacksize(books);
    pop(books);
    isempty(books);
}
```

### Expected output

```txt
Pushed 10.000000 to stack
Pushed 20.000000 to stack
Top of stack books: 20.000000
Stack books size: 2
Popped 20.000000 from stack
Stack books is not empty
```

### Stack rule

- A stack follows **last in, first out**
- `push` adds an item
- `pop` removes the newest item
- `top` shows the newest item without removing it

### Part B: Queue

```txt
using std.h

start() {
    queue line;

    enqueue(line, 5);
    enqueue(line, 15);
    front(line);
    rear(line);
    qsize(line);
    dequeue(line);
    qempty(line);
}
```

### Expected output

```txt
Enqueued 5.000000 to queue
Enqueued 15.000000 to queue
Front of queue line: 5.000000
Rear of queue line: 15.000000
Queue line size: 2
Dequeued 5.000000 from queue
Queue line is not empty
```

### Queue rule

- A queue follows **first in, first out**
- `enqueue` adds at the back
- `dequeue` removes from the front
- `front` and `rear` show the two ends

### Part C: Dictionary

```txt
using std.h

start() {
    dict first;
    dict second;

    set(first, 0, 11);
    set(first, 1, 22);
    set(second, 0, 11);
    set(second, 1, 22);

    size(first);
    compare(first, second);
    get(first, 1);
}
```

### Expected output

```txt
Size of dictionary first: 2
Dictionaries are same
Value at index 1 in dictionary first: 22.000000
```

### Dictionary rule

- `set(name, index, value)` stores a value
- `get(name, index)` reads a value
- `size(name)` shows how many positions are currently used
- `compare(a, b)` checks whether two dictionaries match

### Common mistakes

- Using stack operations on a queue or queue operations on a stack
- Forgetting to declare the data structure before using it
- Assuming a dictionary works like text keys in other languages

### Mini check

Write a program that:

- creates a stack named `numbers`
- pushes `7`
- pushes `9`
- prints the top item with `top(numbers);`

## Lesson 9: Full Recap Program

### Combined sample

```txt
using std.h

start() {
    int score = 82;
    float root = 0;
    stack marks;

    print("Language recap");

    if(score >= 80) {
        print("High score");
    } otherwise {
        print("Keep trying");
    }

    root = sqrt(16);
    print(root);

    push(marks, 10);
    push(marks, 20);
    top(marks);
}
```

### What this review program includes

- program header and main block
- variable declarations
- conditional logic
- math with assignment
- printing text and variables
- one data structure

## Quick Syntax Cheat Sheet

### Program shape

```txt
using std.h

start() {
    ...
}
```

### Types

```txt
int a = 10;
float x = 3.5;
char ch = @A@;
string name = "Rafi";
dict d;
stack s;
queue q;
```

### Output

```txt
print("Hello");
print(a);
```

### Input

```txt
read(a);
```

### Assignment

```txt
a = 20;
x = sqrt(25);
```

### Conditions

```txt
if(a > 10) {
    print("big");
} elif(a == 10) {
    print("equal");
} otherwise {
    print("small");
}
```

### Loops

```txt
from i to 5 inc 1 {
    print(i);
}

while(i < 3) {
    print(i);
    i++;
}
```

### Math

```txt
y = a + b;
y = a - b;
y = a * b;
y = a / b;
y = a % 3;
y = a ^ 2;
y = sqrt(a);
```

### Built-ins

```txt
facto(5);
power(2, 8);
checkprime(29);
max(a, b);
min(a, b);
```

### Stack

```txt
stack books;
push(books, 10);
top(books);
pop(books);
isempty(books);
stacksize(books);
```

### Queue

```txt
queue line;
enqueue(line, 5);
front(line);
rear(line);
dequeue(line);
qempty(line);
qsize(line);
```

### Dictionary

```txt
dict first;
set(first, 0, 11);
get(first, 0);
size(first);
compare(first, first);
```

## What you should be able to do next

- Read the example programs without looking at implementation files
- Predict the output of the beginner examples
- Write your own small programs with variables, math, conditions, loops, and one data structure
- Tell the difference between language syntax and compiler implementation

When you are comfortable with this guide, the next step is to learn how the compiler recognizes and processes this language internally.
