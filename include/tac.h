#ifndef TAC_H
#define TAC_H

#include "common.h"

/* ========= ICG File Pointers ========= */
extern FILE *icg_file;
extern FILE *opt_file;

/* ========= Counters ========= */
extern int temp_count;
extern int label_count;

/* ========= ICG Line Storage ========= */
#define MAX_ICG_LINES 1000
extern char* icg_lines[MAX_ICG_LINES];
extern int icg_line_count;

/* Generate a new temporary variable name (t0, t1, ...). Caller must free. */
char* new_temp(void);

/* Generate a new label name (L0, L1, ...). Caller must free. */
char* new_label(void);

/* Emit a line of three-address code to the ICG file.
   Respects suppress_icg: skips when suppress_icg > 0. */
void emit(const char* code);

/* Emit formatted three-address code. Does NOT respect suppress_icg. */
void emit_fmt(const char* fmt, ...);

/* Store ICG line in memory for later optimization.
   Respects suppress_icg: skips when suppress_icg > 0. */
void store_icg_line(const char* line);

/* Check if a string represents a numeric constant. */
int is_constant(const char* s);

/* Perform constant folding and strength reduction optimization.
   Reads from icg_lines[], writes to opt_file. */
void optimize_constant_folding(void);

#endif /* TAC_H */
