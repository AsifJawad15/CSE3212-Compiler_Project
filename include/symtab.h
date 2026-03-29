#ifndef SYMTAB_H
#define SYMTAB_H

#include "common.h"

/* ========= Variable Symbol Table ========= */
extern struct variable_structure variable[100];
extern int no_var;

/* Check if variable name already exists. Returns 1 if found, 0 otherwise. */
int search_var(char name[20]);

/* Set type for all variables whose type is still TYPE_UNKNOWN (-1). */
void set_var_type(int type);

/* Find variable by name. Returns index or -1 if not found. */
int get_var_index(const char* name);

#endif /* SYMTAB_H */
