#include "tac.h"

/* suppress_icg is defined in parser — accessed via extern */
extern int suppress_icg;

/* ========= ICG File Pointers ========= */
FILE *icg_file  = NULL;
FILE *opt_file  = NULL;

/* ========= Counters ========= */
int temp_count  = 0;
int label_count = 0;

/* ========= ICG Line Storage ========= */
char* icg_lines[MAX_ICG_LINES];
int icg_line_count = 0;

/* Generate a new temporary variable name */
char* new_temp(void) {
    char* temp = (char*)malloc(10);
    snprintf(temp, 10, "t%d", temp_count++);
    return temp;
}

/* Generate a new label name */
char* new_label(void) {
    char* label = (char*)malloc(10);
    snprintf(label, 10, "L%d", label_count++);
    return label;
}

/* Emit a line of three-address code to the ICG file */
void emit(const char* code) {
    if (suppress_icg > 0) return;
    if (icg_file != NULL) {
        fprintf(icg_file, "%s\n", code);
    }
}

/* Emit formatted three-address code */
void emit_fmt(const char* fmt, ...) {
    if (icg_file != NULL) {
        va_list args;
        va_start(args, fmt);
        vfprintf(icg_file, fmt, args);
        va_end(args);
        fprintf(icg_file, "\n");
    }
}

/* Store ICG line for later optimization */
void store_icg_line(const char* line) {
    if (suppress_icg > 0) return;
    if (icg_line_count < MAX_ICG_LINES) {
        icg_lines[icg_line_count] = strdup(line);
        icg_line_count++;
    }
}

/* Check if a string is a numeric constant */
int is_constant(const char* s) {
    if (s == NULL || *s == '\0') return 0;
    if (*s == '-') s++;
    int has_dot = 0;
    while (*s) {
        if (*s == '.') {
            if (has_dot) return 0;
            has_dot = 1;
        } else if (*s < '0' || *s > '9') {
            return 0;
        }
        s++;
    }
    return 1;
}

/* Perform constant folding and strength reduction optimization */
void optimize_constant_folding(void) {
    if (opt_file == NULL) return;

    fprintf(opt_file, "========================================\n");
    fprintf(opt_file, "   OPTIMIZED INTERMEDIATE CODE\n");
    fprintf(opt_file, "   (Constant Folding Applied)\n");
    fprintf(opt_file, "========================================\n\n");

    int optimizations_done = 0;

    for (int i = 0; i < icg_line_count; i++) {
        char line[256];
        strncpy(line, icg_lines[i], sizeof(line) - 1);
        line[sizeof(line) - 1] = '\0';

        /* Try to match pattern: tX = A op B where A and B are constants */
        char dest[32], op1[32], operator_str[8], op2[32];
        int matched = 0;

        if (sscanf(line, "%31s = %31s %7s %31s", dest, op1, operator_str, op2) == 4) {
            if (is_constant(op1) && is_constant(op2)) {
                double a = atof(op1);
                double b = atof(op2);
                double result = 0;
                int can_fold = 1;

                if (strcmp(operator_str, "+") == 0) result = a + b;
                else if (strcmp(operator_str, "-") == 0) result = a - b;
                else if (strcmp(operator_str, "*") == 0) result = a * b;
                else if (strcmp(operator_str, "/") == 0) {
                    if (b != 0) result = a / b;
                    else can_fold = 0;
                }
                else if (strcmp(operator_str, "%") == 0) {
                    if (b != 0) result = (int)a % (int)b;
                    else can_fold = 0;
                }
                else if (strcmp(operator_str, "^") == 0) result = pow(a, b);
                else can_fold = 0;

                if (can_fold) {
                    if (result == (int)result) {
                        fprintf(opt_file, "%s = %d    # folded from: %s\n", dest, (int)result, icg_lines[i]);
                    } else {
                        fprintf(opt_file, "%s = %.6f    # folded from: %s\n", dest, result, icg_lines[i]);
                    }
                    optimizations_done++;
                    matched = 1;
                }
            }

            /* Strength reduction: x * 2 => x + x, x * 1 => x, x + 0 => x */
            if (!matched && is_constant(op2)) {
                double b = atof(op2);
                if (strcmp(operator_str, "*") == 0 && b == 2.0) {
                    fprintf(opt_file, "%s = %s + %s    # strength reduction: *2 => +self\n", dest, op1, op1);
                    optimizations_done++;
                    matched = 1;
                }
                else if (strcmp(operator_str, "*") == 0 && b == 1.0) {
                    fprintf(opt_file, "%s = %s    # strength reduction: *1 => identity\n", dest, op1);
                    optimizations_done++;
                    matched = 1;
                }
                else if (strcmp(operator_str, "+") == 0 && b == 0.0) {
                    fprintf(opt_file, "%s = %s    # strength reduction: +0 => identity\n", dest, op1);
                    optimizations_done++;
                    matched = 1;
                }
                else if (strcmp(operator_str, "-") == 0 && b == 0.0) {
                    fprintf(opt_file, "%s = %s    # strength reduction: -0 => identity\n", dest, op1);
                    optimizations_done++;
                    matched = 1;
                }
                else if (strcmp(operator_str, "*") == 0 && b == 0.0) {
                    fprintf(opt_file, "%s = 0    # strength reduction: *0 => 0\n", dest);
                    optimizations_done++;
                    matched = 1;
                }
            }
        }

        if (!matched) {
            fprintf(opt_file, "%s\n", icg_lines[i]);
        }
    }

    fprintf(opt_file, "\n========================================\n");
    fprintf(opt_file, "   Total optimizations applied: %d\n", optimizations_done);
    fprintf(opt_file, "========================================\n");
}
