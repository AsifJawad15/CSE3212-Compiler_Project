#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "common.h"

/* Determine whether a numeric value looks like an integer or float.
   Returns TYPE_INT (1) if value == (int)value, else TYPE_FLOAT (2). */
int get_expression_type(double value);

/* Assignment-compatibility result codes */
#define SEM_OK              0   /* assignment is fine                    */
#define SEM_IMPLICIT_CONV   1   /* int -> float widening (prints msg)    */
#define SEM_ERR_FLOAT_INT  -1   /* float -> int truncation (error)       */
#define SEM_ERR_NUM_STR    -2   /* numeric -> string (error)             */

/* Check whether a numeric value can be assigned to a variable of the
   given type (TYPE_INT, TYPE_FLOAT, TYPE_CHAR, TYPE_STRING, ...).
   Returns one of the SEM_* codes above.  */
int sem_check_assign_compat(int var_type, double value);

/* Return 1 if var_type supports numeric/mathematical operations
   (int, float, char), 0 otherwise. */
int sem_check_numeric(int var_type);

#endif /* SEMANTIC_H */
