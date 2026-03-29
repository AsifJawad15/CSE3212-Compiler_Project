#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stdarg.h>

/* ========= Verbose flag (0=clean, 1=trace) ========= */
extern int verbose;

/* ========= Type Tags ========= */
typedef enum {
    TYPE_UNKNOWN = -1,
    TYPE_CHAR    = 0,
    TYPE_INT     = 1,
    TYPE_FLOAT   = 2,
    TYPE_STRING  = 3,
    TYPE_DICT    = 4,
    TYPE_STACK   = 5,
    TYPE_QUEUE   = 6
} TypeTag;

/* ========= Variable Symbol Table Entry ========= */
struct variable_structure {
    char var_name[20];
    int var_type;
    union {
        int ival;
        float fval;
        char cval;
        char* sval;
        struct {
            double values[100];
            int size;
        } dict;
        struct {
            double values[100];
            int top;
        } stack;
        struct {
            double values[100];
            int front;
            int rear;
            int size;
        } queue;
    } value;
};

/* ========= Function Table Entry ========= */
struct function_structure {
    char func_name[20];
    int return_type;
    char* code_block;
    double return_value;
};

/* ========= Function Call Result ========= */
struct function_result {
    char name[50];
    double value;
};

#endif /* COMMON_H */
