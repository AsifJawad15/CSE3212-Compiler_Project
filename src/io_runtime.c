#include "io_runtime.h"
#include "symtab.h"
#include "common.h"

/* File handle for read() — values read from input.txt */
FILE *input_file = NULL;

/* Print a variable's value based on its type */
int io_print_var(int var_idx) {
    if (var_idx < 0 || var_idx >= no_var) return 0;
    if (verbose) printf("\nPrinting variable %s: ", variable[var_idx].var_name);
    if (variable[var_idx].var_type == 0) {
        printf("%c", variable[var_idx].value.cval);
    } else if (variable[var_idx].var_type == 1) {
        printf("%d", variable[var_idx].value.ival);
    } else if (variable[var_idx].var_type == 2) {
        printf("%f", variable[var_idx].value.fval);
    } else if (variable[var_idx].var_type == 3) {
        printf("%s", variable[var_idx].value.sval ? variable[var_idx].value.sval : "");
    }
    printf("\n");
    return 1;
}

/* Read a value into a variable from input_file (or stdin as fallback) */
int io_read_var(int var_idx) {
    if (var_idx < 0 || var_idx >= no_var) return 0;
    FILE *src = input_file ? input_file : stdin;
    if (verbose) printf("\nReading value for variable '%s'", variable[var_idx].var_name);
    if (variable[var_idx].var_type == 1) {
        if (fscanf(src, "%d", &variable[var_idx].value.ival) == 1) {
            if (verbose) printf("\nRead integer: %d", variable[var_idx].value.ival);
        } else {
            printf("\nWarning: Could not read integer for '%s'", variable[var_idx].var_name);
        }
    } else if (variable[var_idx].var_type == 2) {
        if (fscanf(src, "%f", &variable[var_idx].value.fval) == 1) {
            if (verbose) printf("\nRead float: %f", variable[var_idx].value.fval);
        } else {
            printf("\nWarning: Could not read float for '%s'", variable[var_idx].var_name);
        }
    } else if (variable[var_idx].var_type == 0) {
        char tmp;
        fscanf(src, " %c", &tmp);
        variable[var_idx].value.cval = tmp;
        if (verbose) printf("\nRead char: %c", variable[var_idx].value.cval);
    } else if (variable[var_idx].var_type == 3) {
        char rbuf[256];
        if (fscanf(src, "%255s", rbuf) == 1) {
            variable[var_idx].value.sval = strdup(rbuf);
            if (verbose) printf("\nRead string: %s", variable[var_idx].value.sval);
        } else {
            printf("\nWarning: Could not read string for '%s'", variable[var_idx].var_name);
        }
    }
    return 1;
}
