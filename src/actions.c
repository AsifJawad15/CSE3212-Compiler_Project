#include "actions.h"
#include "symtab.h"
#include "functab.h"
#include "tac.h"
#include "runtime.h"
#include "parser_ctx.h"
#include "io_runtime.h"
#include "semantic.h"

extern int line_num;
extern int code_result;

/* ================================================================
   DECLARATION HELPERS
   ================================================================ */

int act_declare_var(const char* name, int decl_type) {
    if (g_ctx.suppress_exec > 0) return 0;
    if (search_var((char*)name) != 0) {
        printf("\nWarning: Variable '%s' already declared", name);
        return 0;
    }
    strcpy(variable[no_var].var_name, name);
    variable[no_var].var_type = decl_type;
    printf("\nDeclared variable: %s", name);
    switch (decl_type) {
        case 1: variable[no_var].value.ival = 0; break;
        case 2: variable[no_var].value.fval = 0.0; break;
        case 0: variable[no_var].value.cval = '\0'; break;
        case 3: variable[no_var].value.sval = strdup(""); break;
        case 4: variable[no_var].value.dict.size = 0; break;
        case 5:
            variable[no_var].value.stack.top = -1;
            for (int j = 0; j < 100; j++) variable[no_var].value.stack.values[j] = 0;
            break;
        case 6: rt_init_queue(no_var); break;
    }
    no_var++;
    /* ICG */
    char buf[256];
    const char* type_names[] = {"char","int","float","string","dict","stack","queue"};
    if (decl_type >= 0 && decl_type <= 6)
        snprintf(buf, sizeof(buf), "declare %s %s", type_names[decl_type], name);
    else
        snprintf(buf, sizeof(buf), "declare unknown %s", name);
    emit(buf); store_icg_line(buf);
    return 0;
}

int act_declare_init_expr(const char* name, int decl_type, double value) {
    if (g_ctx.suppress_exec > 0) return 0;
    if (search_var((char*)name) != 0) {
        printf("\nWarning: Variable '%s' already declared", name);
        return 0;
    }
    strcpy(variable[no_var].var_name, name);
    variable[no_var].var_type = decl_type;
    printf("\nDeclared variable: %s with initialization", name);

    int compat = sem_check_assign_compat(decl_type, value);
    if (compat == SEM_ERR_FLOAT_INT) {
        printf("\nError: Type mismatch at line %d - cannot assign float value to int variable '%s'", line_num, name);
    } else {
        if (compat == SEM_IMPLICIT_CONV)
            printf("\nImplicit type conversion at line %d: int to float for variable '%s'", line_num, name);
        switch (variable[no_var].var_type) {
            case 1: variable[no_var].value.ival = (int)value;
                    printf("\nInitialized to integer: %d", variable[no_var].value.ival); break;
            case 2: variable[no_var].value.fval = (float)value;
                    printf("\nInitialized to float: %f", variable[no_var].value.fval); break;
            case 0: variable[no_var].value.cval = (char)(int)value;
                    printf("\nInitialized to char: %c", variable[no_var].value.cval); break;
        }
    }
    no_var++;
    /* ICG */
    char buf[256];
    snprintf(buf, sizeof(buf), "%s = %.6f", name, value);
    emit(buf); store_icg_line(buf);
    return 0;
}

int act_declare_init_str(const char* name, int decl_type, const char* str) {
    if (g_ctx.suppress_exec > 0) return 0;
    if (search_var((char*)name) != 0) {
        printf("\nWarning: Variable '%s' already declared", name);
        return 0;
    }
    strcpy(variable[no_var].var_name, name);
    variable[no_var].var_type = decl_type;
    if (variable[no_var].var_type == 3) {
        variable[no_var].value.sval = strdup(str);
        printf("\nDeclared string variable: %s with initialization", name);
        printf("\nInitialized to string: %s", str);
    } else {
        printf("\nError: Type mismatch at line %d - cannot assign string to non-string variable '%s'", line_num, name);
    }
    no_var++;
    /* ICG */
    char buf[256];
    snprintf(buf, sizeof(buf), "%s = \"%s\"", name, str);
    emit(buf); store_icg_line(buf);
    return 0;
}

/* ================================================================
   ASSIGNMENT HELPERS
   ================================================================ */

double act_assign_expr(const char* name, double value) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        return 0;
    }
    int compat = sem_check_assign_compat(variable[i].var_type, value);
    if (compat == SEM_ERR_FLOAT_INT) {
        printf("\nError: Type mismatch at line %d - cannot assign float value to int variable '%s'", line_num, name);
        return 0;
    } else if (compat == SEM_ERR_NUM_STR) {
        printf("\nError: Type mismatch at line %d - cannot assign numeric to string variable '%s'", line_num, name);
        return 0;
    }
    if (compat == SEM_IMPLICIT_CONV)
        printf("\nImplicit type conversion at line %d: int to float for variable '%s'", line_num, name);
    switch (variable[i].var_type) {
        case 1: variable[i].value.ival = (int)value;
                printf("\nAssigning value %d to %s", variable[i].value.ival, variable[i].var_name); break;
        case 2: variable[i].value.fval = (float)value;
                printf("\nAssigning value %f to %s", variable[i].value.fval, variable[i].var_name); break;
        case 0: variable[i].value.cval = (char)(int)value; break;
        default: break;
    }
    /* ICG */
    char buf[256];
    snprintf(buf, sizeof(buf), "%s = %.6f", name, value);
    emit(buf); store_icg_line(buf);
    return value;
}

double act_assign_increment(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        return 0;
    }
    double result = 0;
    if (variable[i].var_type == 1) {
        variable[i].value.ival++;
        printf("\nIncrementing %s to %d", variable[i].var_name, variable[i].value.ival);
        result = variable[i].value.ival;
    } else if (variable[i].var_type == 2) {
        variable[i].value.fval++;
        printf("\nIncrementing %s to %f", variable[i].var_name, variable[i].value.fval);
        result = variable[i].value.fval;
    }
    char buf[256];
    snprintf(buf, sizeof(buf), "%s = %s + 1", name, name);
    emit(buf); store_icg_line(buf);
    return result;
}

double act_assign_decrement(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        return 0;
    }
    double result = 0;
    if (variable[i].var_type == 1) {
        variable[i].value.ival--;
        printf("\nDecrementing %s to %d", variable[i].var_name, variable[i].value.ival);
        result = variable[i].value.ival;
    } else if (variable[i].var_type == 2) {
        variable[i].value.fval--;
        printf("\nDecrementing %s to %f", variable[i].var_name, variable[i].value.fval);
        result = variable[i].value.fval;
    }
    char buf[256];
    snprintf(buf, sizeof(buf), "%s = %s - 1", name, name);
    emit(buf); store_icg_line(buf);
    return result;
}

double act_assign_str(const char* name, const char* str) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        return 0;
    }
    if (variable[i].var_type == 3) {
        variable[i].value.sval = strdup(str);
        printf("\nAssigning string value: %s to %s", variable[i].value.sval, variable[i].var_name);
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = \"%s\"", name, str);
        emit(buf); store_icg_line(buf);
        return 1;
    }
    printf("\nError: Type mismatch at line %d - cannot assign string to non-string variable '%s'", line_num, name);
    return 0;
}

/* ================================================================
   I/O HELPERS
   ================================================================ */

double act_print_id(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nWarning: Variable '%s' not found in print statement", name);
        return 0;
    }
    io_print_var(i);
    char buf[256];
    snprintf(buf, sizeof(buf), "print %s", name);
    emit(buf); store_icg_line(buf);
    return 1;
}

double act_print_str(const char* str) {
    if (g_ctx.suppress_exec > 0) return 0;
    printf("\n%s", str);
    char buf[256];
    snprintf(buf, sizeof(buf), "print \"%s\"", str);
    emit(buf); store_icg_line(buf);
    return 1;
}

double act_read_id(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        return 0;
    }
    io_read_var(i);
    char buf[256];
    snprintf(buf, sizeof(buf), "read %s", name);
    emit(buf); store_icg_line(buf);
    return 1;
}

/* ================================================================
   BUILT-IN FUNCTION HELPERS
   ================================================================ */

double act_power(double base, double exp) {
    if (g_ctx.suppress_exec > 0) return 0;
    double result = pow(base, exp);
    printf("\nPower function value--> %f", result);
    char* t = new_temp(); char buf[256];
    snprintf(buf, sizeof(buf), "%s = %.6f ^ %.6f", t, base, exp);
    emit(buf); store_icg_line(buf); free(t);
    return result;
}

double act_factorial(int n) {
    if (g_ctx.suppress_exec > 0) return 0;
    int result = 1;
    if (n != 0) { for (int i = 1; i <= n; i++) result *= i; }
    printf("\nFactorial of %d is %d", n, result);
    char buf[256];
    snprintf(buf, sizeof(buf), "# facto(%d) = %d", n, result);
    emit(buf); store_icg_line(buf);
    return result;
}

double act_prime(int n) {
    if (g_ctx.suppress_exec > 0) return 0;
    int flag = 0;
    for (int i = 2; i <= n / 2; ++i) {
        if (n % i == 0) { flag = 1; break; }
    }
    printf("\n%d", flag);
    char buf[256];
    snprintf(buf, sizeof(buf), "# checkprime(%d) = %s", n, flag ? "not prime" : "prime");
    emit(buf); store_icg_line(buf);
    return flag;
}

double act_max(const char* name1, const char* name2) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name1);
    int j = get_var_index(name2);
    if (i == -1 || j == -1) {
        printf("\nError: Variable not declared in max()");
    } else if (variable[i].var_type == 1 && variable[j].var_type == 1) {
        int k = variable[i].value.ival, l = variable[j].value.ival;
        printf("\nMax value is--> %d", l > k ? l : k);
    } else if (variable[i].var_type == 2 && variable[j].var_type == 2) {
        float k = variable[i].value.fval, l = variable[j].value.fval;
        printf("\nMax value is--> %f", l > k ? l : k);
    } else {
        printf("\nNot integer or float variable");
    }
    char buf[256]; char* t = new_temp();
    snprintf(buf, sizeof(buf), "%s = max(%s, %s)", t, name1, name2);
    emit(buf); store_icg_line(buf); free(t);
    return 0;
}

double act_min(const char* name1, const char* name2) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name1);
    int j = get_var_index(name2);
    if (i == -1 || j == -1) {
        printf("\nError: Variable not declared in min()");
    } else if (variable[i].var_type == 1 && variable[j].var_type == 1) {
        int k = variable[i].value.ival, l = variable[j].value.ival;
        printf("\nMin value is--> %d", l < k ? l : k);
    } else if (variable[i].var_type == 2 && variable[j].var_type == 2) {
        float k = variable[i].value.fval, l = variable[j].value.fval;
        printf("\nMin value is--> %f", l < k ? l : k);
    } else {
        printf("\nNot integer or float variable");
    }
    char buf[256]; char* t = new_temp();
    snprintf(buf, sizeof(buf), "%s = min(%s, %s)", t, name1, name2);
    emit(buf); store_icg_line(buf); free(t);
    return 0;
}

/* ================================================================
   FUNCTION DEFINITION & CALL
   ================================================================ */

void act_func_define(const char* name, double retval) {
    if (func_count >= 100) return;
    if (get_function_index((char*)name) != -1) {
        printf("\nError: Function %s already defined", name);
        return;
    }
    strcpy(functions[func_count].func_name, name);
    functions[func_count].return_value = retval;
    strcpy(function_results[result_count].name, name);
    function_results[result_count].value = retval;
    func_count++; result_count++;
    printf("\nFunction defined: %s with return value: %f", name, retval);
    char buf[256];
    snprintf(buf, sizeof(buf), "# --- FUNCTION %s ---", name);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "func_begin %s", name);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "return %.6f", retval);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "func_end %s", name);
    emit(buf); store_icg_line(buf);
}

double act_func_call(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_function_index((char*)name);
    if (idx == -1) {
        printf("\nError: Function %s not defined", name);
        return 0;
    }
    printf("\nFunction %s called and returned: %f",
           functions[idx].func_name, functions[idx].return_value);
    char buf[256];
    snprintf(buf, sizeof(buf), "call %s", name);
    emit(buf); store_icg_line(buf);
    return functions[idx].return_value;
}

/* ================================================================
   EXPRESSION ICG HELPERS
   ================================================================ */

void act_icg_binop(double left, const char* op, double right) {
    char* t = new_temp(); char buf[256];
    snprintf(buf, sizeof(buf), "%s = %.6f %s %.6f", t, left, op, right);
    emit(buf); store_icg_line(buf); free(t);
}

void act_icg_unary(const char* func, double arg) {
    char* t = new_temp(); char buf[256];
    snprintf(buf, sizeof(buf), "%s = %s(%.6f)", t, func, arg);
    emit(buf); store_icg_line(buf); free(t);
}

double act_load_var(const char* name, int* ok) {
    int i = get_var_index(name);
    if (i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", name, line_num);
        *ok = 0; return 0;
    }
    if (!sem_check_numeric(variable[i].var_type)) {
        printf("\nError: Invalid type for mathematical operation");
        *ok = 0; return 0;
    }
    *ok = 1;
    switch (variable[i].var_type) {
        case 1: return (double)variable[i].value.ival;
        case 2: return variable[i].value.fval;
        case 0: return (double)variable[i].value.cval;
        default: return 0;
    }
}

void act_icg_div(double left, double right) {
    if (right != 0) {
        char* t = new_temp(); char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f / %.6f", t, left, right);
        emit(buf); store_icg_line(buf); free(t);
    }
}

void act_icg_mod(int left, int right) {
    if (right != 0) {
        char* t = new_temp(); char buf[256];
        snprintf(buf, sizeof(buf), "%s = %d %% %d", t, left, right);
        emit(buf); store_icg_line(buf); free(t);
    }
}

/* ================================================================
   LOOP HELPERS
   ================================================================ */

double act_for_inc(const char* varname, int limit, int inc, double body_result) {
    if (g_ctx.suppress_exec > 0) return 0;
    printf("\nFor loop detected");
    int ii = get_var_index(varname);
    if (ii == -1) { printf("\nWarning: Loop variable '%s' not declared", varname); return 0; }
    if (variable[ii].var_type != 1) { printf("\nWarning: Loop variable must be an integer"); return 0; }

    int start = variable[ii].value.ival;
    printf("\nStarting loop with %s = %d to %d increment %d", variable[ii].var_name, start, limit, inc);

    char* lstart = new_label(); char* lend = new_label(); char buf[256];
    snprintf(buf, sizeof(buf), "%s:", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "if %s >= %d goto %s", varname, limit, lend); emit(buf); store_icg_line(buf);

    for (int k = start; k < limit; k += inc) {
        variable[ii].value.ival = k;
        code_result = body_result;
        printf("\nLoop iteration %d: %s = %d", k, variable[ii].var_name, variable[ii].value.ival);
    }

    snprintf(buf, sizeof(buf), "%s = %s + %d", varname, varname, inc); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "goto %s", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "%s:", lend); emit(buf); store_icg_line(buf);
    free(lstart); free(lend);

    variable[ii].value.ival = limit;
    printf("\nLoop completed. Final value of %s = %d", variable[ii].var_name, variable[ii].value.ival);
    return variable[ii].value.ival;
}

double act_for_dec(const char* varname, int limit, int dec_val, double body_result) {
    if (g_ctx.suppress_exec > 0) return 0;
    printf("\nFor loop detected");
    int ii = get_var_index(varname);
    if (ii == -1) { printf("\nWarning: Loop variable '%s' not declared", varname); return 0; }
    if (variable[ii].var_type != 1) { printf("\nWarning: Loop variable must be an integer"); return 0; }

    int start = variable[ii].value.ival;
    printf("\nStarting loop with %s = %d to %d decrement %d", variable[ii].var_name, start, limit, dec_val);

    char* lstart = new_label(); char* lend = new_label(); char buf[256];
    snprintf(buf, sizeof(buf), "%s:", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "if %s <= %d goto %s", varname, limit, lend); emit(buf); store_icg_line(buf);

    for (int k = start; k > limit; k -= dec_val) {
        variable[ii].value.ival = k;
        code_result = body_result;
        printf("\nLoop iteration %d: %s = %d", k, variable[ii].var_name, variable[ii].value.ival);
    }

    snprintf(buf, sizeof(buf), "%s = %s - %d", varname, varname, dec_val); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "goto %s", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "%s:", lend); emit(buf); store_icg_line(buf);
    free(lstart); free(lend);

    variable[ii].value.ival = limit;
    printf("\nLoop completed. Final value of %s = %d", variable[ii].var_name, variable[ii].value.ival);
    return variable[ii].value.ival;
}

void act_while_icg(void) {
    char* lstart = new_label(); char* lend = new_label(); char buf[256];
    snprintf(buf, sizeof(buf), "%s:    # while loop start", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "if_false goto %s", lend); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "goto %s", lstart); emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "%s:    # while loop end", lend); emit(buf); store_icg_line(buf);
    free(lstart); free(lend);
}

/* ================================================================
   SWITCH-CASE
   ================================================================ */

void act_switch_end(const char* varname) {
    char buf[256];
    snprintf(buf, sizeof(buf), "# switch(%s) end", varname);
    emit(buf); store_icg_line(buf);
}

void act_case_icg(int caseval) {
    char buf[256];
    snprintf(buf, sizeof(buf), "# case %d:", caseval);
    emit(buf); store_icg_line(buf);
}

/* ================================================================
   DATA STRUCTURE HELPERS
   ================================================================ */

double act_dict_set(const char* name, int index, double value) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i != -1 && variable[i].var_type == 4) {
        if (index >= 0 && index < 100) {
            variable[i].value.dict.values[index] = value;
            if (index >= variable[i].value.dict.size) variable[i].value.dict.size = index + 1;
            printf("\nSet value %f at index %d in dictionary %s", value, index, variable[i].var_name);
        } else { printf("\nError: Index out of bounds"); }
    }
    return 0;
}

double act_dict_get(const char* name, int index) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i != -1 && variable[i].var_type == 4) {
        if (index >= 0 && index < variable[i].value.dict.size)
            printf("\nValue at index %d in dictionary %s: %f", index, variable[i].var_name, variable[i].value.dict.values[index]);
        else printf("\nError: Index out of bounds");
    }
    return 0;
}

double act_dict_concat(const char* name1, const char* name2) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i1 = get_var_index(name1), i2 = get_var_index(name2);
    if (i1 != -1 && i2 != -1 && variable[i1].var_type == 4 && variable[i2].var_type == 4) {
        int new_size = variable[i1].value.dict.size + variable[i2].value.dict.size;
        if (new_size <= 100) {
            for (int j = 0; j < variable[i2].value.dict.size; j++)
                variable[i1].value.dict.values[variable[i1].value.dict.size + j] = variable[i2].value.dict.values[j];
            variable[i1].value.dict.size = new_size;
            printf("\nConcatenated dictionary %s to %s", variable[i2].var_name, variable[i1].var_name);
        }
    }
    return 0;
}

double act_dict_copy(const char* name1, const char* name2) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i1 = get_var_index(name1), i2 = get_var_index(name2);
    if (i1 != -1 && i2 != -1 && variable[i1].var_type == 4 && variable[i2].var_type == 4) {
        variable[i2].value.dict.size = variable[i1].value.dict.size;
        for (int j = 0; j < variable[i1].value.dict.size; j++)
            variable[i2].value.dict.values[j] = variable[i1].value.dict.values[j];
        printf("\nCopied dictionary %s to %s", variable[i1].var_name, variable[i2].var_name);
    }
    return 0;
}

double act_dict_size(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i = get_var_index(name);
    if (i != -1 && variable[i].var_type == 4)
        printf("\nSize of dictionary %s: %d", variable[i].var_name, variable[i].value.dict.size);
    return 0;
}

double act_dict_compare(const char* name1, const char* name2) {
    if (g_ctx.suppress_exec > 0) return 0;
    int i1 = get_var_index(name1), i2 = get_var_index(name2);
    if (i1 != -1 && i2 != -1 && variable[i1].var_type == 4 && variable[i2].var_type == 4) {
        if (variable[i1].value.dict.size != variable[i2].value.dict.size) {
            printf("\nDictionaries are different (different sizes)");
        } else {
            int same = 1;
            for (int j = 0; j < variable[i1].value.dict.size; j++) {
                if (variable[i1].value.dict.values[j] != variable[i2].value.dict.values[j]) { same = 0; break; }
            }
            printf("\nDictionaries are %s", same ? "same" : "different");
        }
    }
    return 0;
}

/* ---- Stack ---- */

double act_stack_push(const char* name, double value) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 5) {
        if (rt_push(idx, value))
            printf("\nSuccessfully pushed %f to stack %s", value, variable[idx].var_name);
    } else {
        printf("\nError: Invalid stack operation - %s is not a stack", name);
    }
    return value;
}

double act_stack_pop(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 5) {
        if (variable[idx].value.stack.top >= 0) {
            double value = rt_pop(idx);
            printf("\nSuccessfully popped %f from stack %s", value, variable[idx].var_name);
            return value;
        }
        printf("\nError: Cannot pop from empty stack %s", variable[idx].var_name);
        return 0;
    }
    printf("\nError: Invalid stack operation - %s is not a stack", name);
    return 0;
}

double act_stack_top(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 5) {
        if (variable[idx].value.stack.top >= 0) {
            double value = rt_top(idx);
            printf("\nTop of stack %s: %f (position: %d)", variable[idx].var_name, value, variable[idx].value.stack.top);
            return value;
        }
        printf("\nError: Stack %s is empty", variable[idx].var_name);
        return 0;
    }
    printf("\nError: Invalid stack operation - %s is not a stack", name);
    return 0;
}

double act_stack_isempty(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 5) {
        int empty = rt_is_empty(idx);
        printf("\nStack %s is %s (top: %d)", variable[idx].var_name, empty ? "empty" : "not empty", variable[idx].value.stack.top);
        return empty;
    }
    if (idx == -1) printf("\nError: Stack %s not declared", name);
    else           printf("\nError: Variable %s is not a stack", name);
    return 1;
}

double act_stack_size(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 5) {
        int size = rt_stack_size(idx);
        printf("\nStack %s size: %d", variable[idx].var_name, size);
        return size;
    }
    if (idx == -1) printf("\nError: Stack %s not declared", name);
    else           printf("\nError: Variable %s is not a stack", name);
    return 0;
}

/* ---- Queue ---- */

double act_queue_enqueue(const char* name, double value) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        if (rt_enqueue(idx, value))
            printf("\nSuccessfully enqueued %f to queue %s", value, variable[idx].var_name);
    } else {
        printf("\nError: Invalid queue operation - %s is not a queue", name);
    }
    return value;
}

double act_queue_dequeue(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        double value = rt_dequeue(idx);
        printf("\nSuccessfully dequeued %f from queue %s", value, variable[idx].var_name);
        return value;
    }
    printf("\nError: Invalid queue operation - %s is not a queue", name);
    return 0;
}

double act_queue_front(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        double value = rt_get_front(idx);
        printf("\nFront of queue %s: %f", variable[idx].var_name, value);
        return value;
    }
    printf("\nError: Invalid queue operation - %s is not a queue", name);
    return 0;
}

double act_queue_rear(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        double value = rt_get_rear(idx);
        printf("\nRear of queue %s: %f", variable[idx].var_name, value);
        return value;
    }
    printf("\nError: Invalid queue operation - %s is not a queue", name);
    return 0;
}

double act_queue_qempty(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        int empty = rt_is_queue_empty(idx);
        printf("\nQueue %s is %s", variable[idx].var_name, empty ? "empty" : "not empty");
        return empty;
    }
    printf("\nError: Invalid queue operation - %s is not a queue", name);
    return 1;
}

double act_queue_qsize(const char* name) {
    if (g_ctx.suppress_exec > 0) return 0;
    int idx = get_var_index(name);
    if (idx != -1 && variable[idx].var_type == 6) {
        int size = rt_queue_size(idx);
        printf("\nQueue %s size: %d", variable[idx].var_name, size);
        return size;
    }
    printf("\nError: Invalid queue operation - %s is not a queue", name);
    return 0;
}
