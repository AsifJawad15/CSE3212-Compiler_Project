#include "semantic.h"

/* Determine whether a numeric value looks like an integer or float */
int get_expression_type(double value) {
    if (value == (int)value) {
        return 1;  /* Integer type */
    }
    return 2;  /* Float type */
}

/* Check whether a numeric value can be assigned to a variable of the
   given type.  Returns SEM_OK, SEM_IMPLICIT_CONV, SEM_ERR_FLOAT_INT,
   or SEM_ERR_NUM_STR. */
int sem_check_assign_compat(int var_type, double value) {
    switch (var_type) {
        case 1: /* int */
            if (value != (int)value)
                return SEM_ERR_FLOAT_INT;
            return SEM_OK;
        case 2: /* float */
            if (value == (int)value)
                return SEM_IMPLICIT_CONV;
            return SEM_OK;
        case 0: /* char */
            return SEM_OK;
        case 3: /* string */
            return SEM_ERR_NUM_STR;
        default:
            return SEM_OK;
    }
}

/* Return 1 if var_type supports numeric/mathematical operations */
int sem_check_numeric(int var_type) {
    return (var_type == 0 || var_type == 1 || var_type == 2);
}
