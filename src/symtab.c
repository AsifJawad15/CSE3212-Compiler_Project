#include "symtab.h"

/* ========= Variable Symbol Table Storage ========= */
struct variable_structure variable[100];
int no_var = 0;

/* Check if variable name already exists. */
int search_var(char name[20]) {
    int i;
    for (i = 0; i < no_var; i++) {
        if (!strcmp(variable[i].var_name, name)) {
            return 1;
        }
    }
    return 0;
}

/* Set type for all variables whose type is still -1 (TYPE_UNKNOWN). */
void set_var_type(int type) {
    int i;
    for (i = 0; i < no_var; i++) {
        if (variable[i].var_type == -1) {
            variable[i].var_type = type;
        }
    }
}

/* Find variable by name. Returns index or -1. */
int get_var_index(const char* name) {
    int i;
    for (i = 0; i < no_var; i++) {
        if (strcmp(variable[i].var_name, name) == 0) {
            return i;
        }
    }
    return -1;
}
