#ifndef IO_RUNTIME_H
#define IO_RUNTIME_H

#include "common.h"

/* File handle for read() — values read from input.txt */
extern FILE *input_file;

/* Print a variable's value based on its type.
   Prints to stdout in the format "Printing variable <name>: <value>".
   Returns 1 on success, 0 if var_idx is invalid. */
int io_print_var(int var_idx);

/* Read a value into a variable from input_file (or stdin as fallback).
   Returns 1 on success, 0 if var_idx is invalid. */
int io_read_var(int var_idx);

#endif /* IO_RUNTIME_H */
