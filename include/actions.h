#ifndef ACTIONS_H
#define ACTIONS_H

#include "common.h"

/* ======== Declaration Helpers ======== */
/* Declare a variable with default initialization. Returns 0. */
int act_declare_var(const char* name, int decl_type);

/* Declare a variable and initialize with numeric expression. Returns 0. */
int act_declare_init_expr(const char* name, int decl_type, double value);

/* Declare a variable and initialize with string. Returns 0. */
int act_declare_init_str(const char* name, int decl_type, const char* str);

/* ======== Assignment Helpers ======== */
/* Assign numeric expression to existing variable. Returns assigned value or 0. */
double act_assign_expr(const char* name, double value);

/* Increment variable (++). Returns new value or 0. */
double act_assign_increment(const char* name);

/* Decrement variable (--). Returns new value or 0. */
double act_assign_decrement(const char* name);

/* Assign string to existing variable. Returns 1 on success, 0 on error. */
double act_assign_str(const char* name, const char* str);

/* ======== I/O Helpers ======== */
/* Print variable by name with ICG. Returns 1 on success. */
double act_print_id(const char* name);

/* Print string literal with ICG. Returns 1. */
double act_print_str(const char* str);

/* Read into variable by name with ICG. Returns 1 on success. */
double act_read_id(const char* name);

/* ======== Built-in Function Helpers ======== */
double act_power(double base, double exp);
double act_factorial(int n);
double act_prime(int n);
double act_max(const char* name1, const char* name2);
double act_min(const char* name1, const char* name2);

/* ======== Function Definition & Call ======== */
/* Define a function with given name and return value. */
void act_func_define(const char* name, double retval);

/* Call a function by name. Returns its return value (or 0 if not found). */
double act_func_call(const char* name);

/* ======== Expression Helpers ======== */
/* Emit ICG for binary arithmetic: result = left op right. */
void act_icg_binop(double left, const char* op, double right);

/* Emit ICG for unary math function: result = func(arg). */
void act_icg_unary(const char* func, double arg);

/* Load variable value as double for expression evaluation. Returns value and sets *ok. */
double act_load_var(const char* name, int* ok);

/* Emit ICG for division (only if divisor != 0). */
void act_icg_div(double left, double right);

/* Emit ICG for modulo (only if divisor != 0). */
void act_icg_mod(int left, int right);

/* ======== Loop Helpers ======== */
/* Execute and emit ICG for for-loop (INC direction). Returns final var value. */
double act_for_inc(const char* varname, int limit, int inc, double body_result);

/* Execute and emit ICG for for-loop (DEC direction). Returns final var value. */
double act_for_dec(const char* varname, int limit, int dec_val, double body_result);

/* Emit ICG for while loop. */
void act_while_icg(void);

/* ======== Switch-Case ======== */
void act_switch_end(const char* varname);
void act_case_icg(int caseval);

/* ======== Data Structure Helpers ======== */
/* Dict operations - all return 0 */
double act_dict_set(const char* name, int index, double value);
double act_dict_get(const char* name, int index);
double act_dict_concat(const char* name1, const char* name2);
double act_dict_copy(const char* name1, const char* name2);
double act_dict_size(const char* name);
double act_dict_compare(const char* name1, const char* name2);

/* Stack operations */
double act_stack_push(const char* name, double value);
double act_stack_pop(const char* name);
double act_stack_top(const char* name);
double act_stack_isempty(const char* name);
double act_stack_size(const char* name);

/* Queue operations */
double act_queue_enqueue(const char* name, double value);
double act_queue_dequeue(const char* name);
double act_queue_front(const char* name);
double act_queue_rear(const char* name);
double act_queue_qempty(const char* name);
double act_queue_qsize(const char* name);

#endif /* ACTIONS_H */
