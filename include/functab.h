#ifndef FUNCTAB_H
#define FUNCTAB_H

#include "common.h"

/* ========= Function Table ========= */
extern struct function_structure functions[100];
extern int func_count;

/* ========= Function Call Results ========= */
extern struct function_result function_results[100];
extern int result_count;

/* Find function by name. Returns index or -1 if not found. */
int get_function_index(char* name);

#endif /* FUNCTAB_H */
