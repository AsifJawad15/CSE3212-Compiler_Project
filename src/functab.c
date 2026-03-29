#include "functab.h"

/* ========= Function Table Storage ========= */
struct function_structure functions[100];
int func_count = 0;

/* ========= Function Call Results Storage ========= */
struct function_result function_results[100];
int result_count = 0;

/* Find function by name. Returns index or -1. */
int get_function_index(char* name) {
    for (int i = 0; i < func_count; i++) {
        if (!strcmp(functions[i].func_name, name)) {
            return i;
        }
    }
    return -1;
}
