%{
	#include "symtab.h"
	#include "functab.h"

	int yylex(void);
	void yyerror(char *s);
	extern FILE *yyin;
	extern FILE *yyout;
	extern int line_num;

	// Helper function to determine expression type
	int get_expression_type(double value) {
		if(value == (int)value) {
			return 1;  // Integer type
		}
		return 2;  // Float type
	}

	int code_result = 0;

	/* Execution suppression counter: when > 0, all side effects are skipped
	   (used to prevent dead branches in if/elif/else from executing) */
	int suppress_exec = 0;

	/* Stack for conditionMatched to support nested if-chains */
	int cm_stack[50];
	int cm_top_idx = -1;
	#define CM_PUSH(v)  (cm_stack[++cm_top_idx] = (v))
	#define CM_POP()    (cm_stack[cm_top_idx--])
	#define CM_SET(v)   (cm_stack[cm_top_idx]  = (v))
	#define CM_GET()    (cm_stack[cm_top_idx])

	/* File handle for read() — values read from input.txt */
	FILE *input_file = NULL;

	/* Current declaration type — used by init_item for correct type in comma-separated lists */
	int current_decl_type = -1;

	/* ICG suppression counter: when > 0, emit()/store_icg_line() are skipped.
	   Used so that false-branch body statements don't emit ICG before the if_false goto. */
	int suppress_icg = 0;

	/* ICG label stack for if/elif/else control flow */
	#define MAX_LABEL_STACK 50
	char* icg_label_stack[MAX_LABEL_STACK];
	int icg_label_top = -1;
	#define ICG_LPUSH(l)  (icg_label_stack[++icg_label_top] = (l))
	#define ICG_LPOP()    (icg_label_stack[icg_label_top--])
	#define ICG_LPEEK()   (icg_label_stack[icg_label_top])

	// ============================
	// Stack operations
	// ============================
	void init_stack(int idx) {
	    variable[idx].value.stack.top = -1;
	}

	int push(int stack_idx, double value) {
	    if(variable[stack_idx].value.stack.top >= 99) {
	        printf("\nStack overflow! Cannot push %f", value);
	        return 0;
	    }
	    variable[stack_idx].value.stack.top++;
	    variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top] = value;
	    printf("\nPushed %f to stack (position: %d)", value, variable[stack_idx].value.stack.top);
	    return 1;
	}

	double pop(int stack_idx) {
	    if(variable[stack_idx].value.stack.top < 0) {
	        printf("\nStack underflow! Cannot pop from empty stack");
	        return 0;
	    }
	    double value = variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top];
	    variable[stack_idx].value.stack.top--;
	    printf("\nPopped %f from stack (new top: %d)", value, variable[stack_idx].value.stack.top);
	    return value;
	}

	double top(int stack_idx) {
	    if(variable[stack_idx].value.stack.top < 0) {
	        printf("\nStack is empty! No top element");
	        return 0;
	    }
	    return variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top];
	}

	int is_empty(int stack_idx) {
	    if (stack_idx < 0 || stack_idx >= no_var) {
	        return 1;  
	    }
	    return (variable[stack_idx].value.stack.top == -1);
	}

	int stack_size(int stack_idx) {
	    if(stack_idx < 0 || stack_idx >= no_var) {
	        printf("\nError: Invalid stack index");
	        return 0;
	    }
	    return variable[stack_idx].value.stack.top + 1;  
	}

	// ============================
	// Queue operations
	// ============================
	void init_queue(int idx) {
	    variable[idx].value.queue.front = 0;
	    variable[idx].value.queue.rear = -1;
	    variable[idx].value.queue.size = 0;
	}

	int enqueue(int queue_idx, double value) {
	    if(variable[queue_idx].value.queue.size >= 100) {
	        printf("\nQueue overflow! Cannot enqueue %f", value);
	        return 0;
	    }
	    variable[queue_idx].value.queue.rear = (variable[queue_idx].value.queue.rear + 1) % 100;
	    variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.rear] = value;
	    variable[queue_idx].value.queue.size++;
	    printf("\nEnqueued %f to queue (rear: %d)", value, variable[queue_idx].value.queue.rear);
	    return 1;
	}

	double dequeue(int queue_idx) {
	    if(variable[queue_idx].value.queue.size <= 0) {
	        printf("\nQueue underflow! Cannot dequeue from empty queue");
	        return 0;
	    }
	    double value = variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.front];
	    variable[queue_idx].value.queue.front = (variable[queue_idx].value.queue.front + 1) % 100;
	    variable[queue_idx].value.queue.size--;
	    printf("\nDequeued %f from queue (new front: %d)", value, variable[queue_idx].value.queue.front);
	    return value;
	}

	double get_front(int queue_idx) {
	    if(variable[queue_idx].value.queue.size <= 0) {
	        printf("\nQueue is empty! No front element");
	        return 0;
	    }
	    return variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.front];
	}

	double get_rear(int queue_idx) {
	    if(variable[queue_idx].value.queue.size <= 0) {
	        printf("\nQueue is empty! No rear element");
	        return 0;
	    }
	    return variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.rear];
	}

	int is_queue_empty(int queue_idx) {
	    return (variable[queue_idx].value.queue.size == 0);
	}

	int queue_size(int queue_idx) {
	    return variable[queue_idx].value.queue.size;
	}

	// =====================================================
	// INTERMEDIATE CODE GENERATION (Three-Address Code)
	// =====================================================
	
	FILE *icg_file;       // File pointer for intermediate code output
	int temp_count = 0;   // Counter for temporary variables (t0, t1, t2, ...)
	int label_count = 0;  // Counter for labels (L0, L1, L2, ...)
	
	// Generate a new temporary variable name
	char* new_temp() {
	    char* temp = (char*)malloc(10);
	    snprintf(temp, 10, "t%d", temp_count++);
	    return temp;
	}
	
	// Generate a new label name
	char* new_label() {
	    char* label = (char*)malloc(10);
	    snprintf(label, 10, "L%d", label_count++);
	    return label;
	}
	
	// Emit a line of three-address code to the ICG file
	void emit(const char* code) {
	    if(suppress_icg > 0) return;
	    if(icg_file != NULL) {
	        fprintf(icg_file, "%s\n", code);
	    }
	}
	
	// Emit formatted three-address code
	void emit_fmt(const char* fmt, ...) {
	    if(icg_file != NULL) {
	        va_list args;
	        va_start(args, fmt);
	        vfprintf(icg_file, fmt, args);
	        va_end(args);
	        fprintf(icg_file, "\n");
	    }
	}

	// =====================================================
	// CODE OPTIMIZATION (Constant Folding & Strength Reduction)
	// =====================================================
	
	FILE *opt_file;  // File pointer for optimized code output
	
	#define MAX_ICG_LINES 1000
	char* icg_lines[MAX_ICG_LINES];
	int icg_line_count = 0;
	
	// Store ICG line for later optimization
	void store_icg_line(const char* line) {
	    if(suppress_icg > 0) return;
	    if(icg_line_count < MAX_ICG_LINES) {
	        icg_lines[icg_line_count] = strdup(line);
	        icg_line_count++;
	    }
	}
	
	// Check if a string is a numeric constant
	int is_constant(const char* s) {
	    if(s == NULL || *s == '\0') return 0;
	    if(*s == '-') s++;
	    int has_dot = 0;
	    while(*s) {
	        if(*s == '.') {
	            if(has_dot) return 0;
	            has_dot = 1;
	        } else if(*s < '0' || *s > '9') {
	            return 0;
	        }
	        s++;
	    }
	    return 1;
	}
	
	// Perform constant folding optimization
	void optimize_constant_folding() {
	    if(opt_file == NULL) return;
	    
	    fprintf(opt_file, "========================================\n");
	    fprintf(opt_file, "   OPTIMIZED INTERMEDIATE CODE\n");
	    fprintf(opt_file, "   (Constant Folding Applied)\n");
	    fprintf(opt_file, "========================================\n\n");
	    
	    int optimizations_done = 0;
	    
	    for(int i = 0; i < icg_line_count; i++) {
	        char line[256];
	        strncpy(line, icg_lines[i], sizeof(line) - 1);
	        line[sizeof(line) - 1] = '\0';
	        
	        // Try to match pattern: tX = A op B where A and B are constants
	        char dest[32], op1[32], operator_str[8], op2[32];
	        int matched = 0;
	        
	        if(sscanf(line, "%31s = %31s %7s %31s", dest, op1, operator_str, op2) == 4) {
	            if(is_constant(op1) && is_constant(op2)) {
	                double a = atof(op1);
	                double b = atof(op2);
	                double result = 0;
	                int can_fold = 1;
	                
	                if(strcmp(operator_str, "+") == 0) result = a + b;
	                else if(strcmp(operator_str, "-") == 0) result = a - b;
	                else if(strcmp(operator_str, "*") == 0) result = a * b;
	                else if(strcmp(operator_str, "/") == 0) {
	                    if(b != 0) result = a / b;
	                    else can_fold = 0;
	                }
	                else if(strcmp(operator_str, "%") == 0) {
	                    if(b != 0) result = (int)a % (int)b;
	                    else can_fold = 0;
	                }
	                else if(strcmp(operator_str, "^") == 0) result = pow(a, b);
	                else can_fold = 0;
	                
	                if(can_fold) {
	                    if(result == (int)result) {
	                        fprintf(opt_file, "%s = %d    # folded from: %s\n", dest, (int)result, icg_lines[i]);
	                    } else {
	                        fprintf(opt_file, "%s = %.6f    # folded from: %s\n", dest, result, icg_lines[i]);
	                    }
	                    optimizations_done++;
	                    matched = 1;
	                }
	            }
	            
	            // Strength reduction: x * 2 => x + x, x * 1 => x, x + 0 => x
	            if(!matched && is_constant(op2)) {
	                double b = atof(op2);
	                if(strcmp(operator_str, "*") == 0 && b == 2.0) {
	                    fprintf(opt_file, "%s = %s + %s    # strength reduction: *2 => +self\n", dest, op1, op1);
	                    optimizations_done++;
	                    matched = 1;
	                }
	                else if(strcmp(operator_str, "*") == 0 && b == 1.0) {
	                    fprintf(opt_file, "%s = %s    # strength reduction: *1 => identity\n", dest, op1);
	                    optimizations_done++;
	                    matched = 1;
	                }
	                else if(strcmp(operator_str, "+") == 0 && b == 0.0) {
	                    fprintf(opt_file, "%s = %s    # strength reduction: +0 => identity\n", dest, op1);
	                    optimizations_done++;
	                    matched = 1;
	                }
	                else if(strcmp(operator_str, "-") == 0 && b == 0.0) {
	                    fprintf(opt_file, "%s = %s    # strength reduction: -0 => identity\n", dest, op1);
	                    optimizations_done++;
	                    matched = 1;
	                }
	                else if(strcmp(operator_str, "*") == 0 && b == 0.0) {
	                    fprintf(opt_file, "%s = 0    # strength reduction: *0 => 0\n", dest);
	                    optimizations_done++;
	                    matched = 1;
	                }
	            }
	        }
	        
	        if(!matched) {
	            fprintf(opt_file, "%s\n", icg_lines[i]);
	        }
	    }
	    
	    fprintf(opt_file, "\n========================================\n");
	    fprintf(opt_file, "   Total optimizations applied: %d\n", optimizations_done);
	    fprintf(opt_file, "========================================\n");
	}

%}

%union {
	double val;
	char* stringValue;
	char* type;
}

// =====================================================
// TOKEN DEFINITIONS & OPERATOR PRECEDENCE
// =====================================================

%error-verbose
%token MAIN INT CHAR FLOAT POWER FACTO PRIME READ PRINT IF ELIF ELSE SWITCH CASE DEFAULT FROM TO INC DEC MAX MIN ID NUM PLUS MINUS MUL DIV EQUAL NOTEQUAL GT GOE LT LOE STRING STRING_LITERAL FUNCTION RETURN MOD POW SQRT ABS LOG SIN COS TAN INCREMENT DECREMENT AND OR NOT NEQ STRICT_EQUAL STRICT_NEQ WHILE
%left OR
%left AND
%right NOT
%left EQUAL NOTEQUAL NEQ STRICT_EQUAL STRICT_NEQ
%left GT GOE LT LOE
%left PLUS MINUS
%left MUL DIV MOD
%right POW
%right UMINUS
%right INCREMENT DECREMENT
%token DICT GET SET CONCAT COPY SIZE COMPARE
%token STACK PUSH POP TOP ISEMPTY
%token STACKSIZE  
%token QUEUE ENQUEUE DEQUEUE FRONT REAR QSIZE QEMPTY
	// Defining token type

%type<val> prime_code factorial_code casenum_code default_code case_code switch_code e f t expression bool_expression power_code min_code max_code declaration assignment condition for_code print_code read_code program code TYPE MAIN INT CHAR FLOAT POWER FACTO PRIME READ PRINT SWITCH CASE DEFAULT IF ELIF ELSE FROM TO INC DEC MAX MIN NUM PLUS MINUS MUL DIV EQUAL NOTEQUAL GT GOE LT LOE STRING return_statement function_call function_list function main if_statement elif_list if_prefix else_opt else_part
%type<val>while_code
%type<val>dict_operation
%type<val>stack_operation
%type<val>queue_operation
%type<stringValue> ID STRING_LITERAL

%%

// =====================================================
// PROGRAM STRUCTURE
// =====================================================

program: function_list main {
            printf("\nValid program\n");
            printf("\nNo of variables--> %d", no_var);
            $$ = $1;
        }
        | main {
            printf("\nValid program\n");
            printf("\nNo of variables--> %d", no_var);
            $$ = $1;
        }
        ;

main: MAIN '{' code '}' {
    emit("# --- END OF MAIN ---");
    $$ = $3;  
}
    | MAIN '(' ')' '{' code '}' {
    emit("# --- END OF MAIN ---");
    $$ = $5;
}
    ;

// =====================================================
// FUNCTION DEFINITION & CALL
// =====================================================

function_list: function_list function {
        $$ = $2;
    }
    | function {
        $$ = $1;
    }
    ;

function: FUNCTION ID '(' ')' '{' code return_statement '}' {
    if (func_count < 100) {
        if (get_function_index($2) != -1) {
            printf("\nError: Function %s already defined", $2);
        } else {
            strcpy(functions[func_count].func_name, $2);
            functions[func_count].return_value = $7;
            
            strcpy(function_results[result_count].name, $2);
            function_results[result_count].value = $7;
            
            func_count++;
            result_count++;
            
            printf("\nFunction defined: %s with return value: %f", $2, $7);
            
            // ICG: function definition
            char buf[256];
            snprintf(buf, sizeof(buf), "# --- FUNCTION %s ---", $2);
            emit(buf);
            store_icg_line(buf);
            snprintf(buf, sizeof(buf), "func_begin %s", $2);
            emit(buf);
            store_icg_line(buf);
            snprintf(buf, sizeof(buf), "return %.6f", $7);
            emit(buf);
            store_icg_line(buf);
            snprintf(buf, sizeof(buf), "func_end %s", $2);
            emit(buf);
            store_icg_line(buf);
        }
    }
}
;

return_statement: RETURN expression ';' {
    $$ = $2;
    printf("\nFunction returning value: %f", $2);
}
;

code: declaration code    { $$ = $1; }
    | assignment code     { $$ = $1; }
    | dict_operation code { $$ = $1; }
    | condition code      { $$ = $1; }
    | for_code code       { $$ = $1; }
    | while_code code     { $$ = $1; }
    | switch_code code    { $$ = $1; }
    | print_code code     { $$ = $1; }
    | read_code code      { $$ = $1; }
    | power_code code     { $$ = $1; }
    | factorial_code code { $$ = $1; }
    | prime_code code     { $$ = $1; }
    | min_code code       { $$ = $1; }
    | max_code code       { $$ = $1; }
    | function_call code  { $$ = $1; }
    | stack_operation code { $$ = $1; }
    | queue_operation code { $$ = $1; }
    | /* empty */         { $$ = 0; }
    ;

function_call: ID '(' ')' ';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int idx = get_function_index($1);
    if(idx != -1) {
        printf("\nFunction %s called and returned: %f", 
               functions[idx].func_name, functions[idx].return_value);
        $$ = functions[idx].return_value;
        
        // ICG: function call
        char buf[256];
        snprintf(buf, sizeof(buf), "call %s", $1);
        emit(buf);
        store_icg_line(buf);
    } else {
        printf("\nError: Function %s not defined", $1);
        $$ = 0;
    }
    }
}
;

// =====================================================
// BUILT-IN FUNCTIONS (power, factorial, prime, max, min)
// =====================================================

power_code: POWER '(' NUM ',' NUM ')'';'	{		
	if(suppress_exec > 0) { $$ = 0; }
	else {
	double result = pow($3, $5);
	printf("\nPower function value--> %f", result);
	$$ = result;
	
	// ICG
	char* t = new_temp();
	char buf[256];
	snprintf(buf, sizeof(buf), "%s = %.6f ^ %.6f", t, $3, $5);
	emit(buf);
	store_icg_line(buf);
	free(t);
	}
}
	;

	// CFG for calculating factorial of a number

factorial_code: FACTO '(' NUM ')' ';'	{
	if(suppress_exec > 0) { $$ = 0; }
	else {
	int j = $3;
	int i, result;
	result = 1;
	if(j==0){
		printf("\nFactorial of %d is %d", j, result);
	}
	else{
		for(i = 1; i <= j; i++){
			result = result*i;
		}
		printf("\nFactorial of %d is %d", j, result);
	}
	
	// ICG
	char buf[256];
	snprintf(buf, sizeof(buf), "# facto(%d) = %d", j, result);
	emit(buf);
	store_icg_line(buf);
	}
}
	;
	
	// CFG for checking if a number is prime or not
	
prime_code: PRIME '(' NUM ')' ';'{
	if(suppress_exec > 0) { $$ = 0; }
	else {
	int n, i, flag = 0;
	n = $3;
	for (i = 2; i <= n / 2; ++i) {
		if (n % i == 0) {
			flag = 1;
			break;
		}
	}
    printf("\n%d", flag);
    
    // ICG
    char buf[256];
    snprintf(buf, sizeof(buf), "# checkprime(%d) = %s", n, flag ? "not prime" : "prime");
    emit(buf);
    store_icg_line(buf);
	}
}
	;

	// CFG for max() function

max_code: MAX '(' ID ',' ID')'';'{
	if(suppress_exec > 0) { $$ = 0; }
	else {
	int i = get_var_index($3);
	int j = get_var_index($5);
	if(i == -1 || j == -1) {
		printf("\nError: Variable not declared in max()");
	}
	else if((variable[i].var_type == 1) &&(variable[j].var_type == 1) ){
		int k = variable[i].value.ival;
		int l = variable[j].value.ival;
		if(l>k){
			printf("\nMax value is--> %d", l);
		}
		else{
			printf("\nMax value is--> %d", k);
		}
	}
	else if((variable[i].var_type == 2) &&(variable[j].var_type == 2) ){
		float k = variable[i].value.fval;
		float l = variable[j].value.fval;
		if(l>k){
			printf("\nMax value is--> %f", l);
		}
		else{
			printf("\nMax value is--> %f", k);
		}
	}
	else{
		printf("\nNot integer or float variable");
	}
	
	// ICG
	char buf[256];
	char* t = new_temp();
	snprintf(buf, sizeof(buf), "%s = max(%s, %s)", t, $3, $5);
	emit(buf);
	store_icg_line(buf);
	free(t);
	}
}
	;
	
	// CFG for min() function
	
min_code: MIN '(' ID ',' ID')'';'{
	if(suppress_exec > 0) { $$ = 0; }
	else {
	int i = get_var_index($3);
	int j = get_var_index($5);
	if(i == -1 || j == -1) {
		printf("\nError: Variable not declared in min()");
	}
	else if((variable[i].var_type == 1) &&(variable[j].var_type == 1) ){
		int k = variable[i].value.ival;
		int l = variable[j].value.ival;
		if(l<k){
			printf("\nMin value is--> %d", l);
		}
		else{
			printf("\nMin value is--> %d", k);
		}
	}
	else if((variable[i].var_type == 2) &&(variable[j].var_type == 2) ){
		float k = variable[i].value.fval;
		float l = variable[j].value.fval;
		if(l<k){
			printf("\nMin value is--> %f", l);
		}
		else{
			printf("\nMin value is--> %f", k);
		}
	}
	else{
		printf("\nNot integer or float variable");
	}
	
	// ICG
	char buf[256];
	char* t = new_temp();
	snprintf(buf, sizeof(buf), "%s = min(%s, %s)", t, $3, $5);
	emit(buf);
	store_icg_line(buf);
	free(t);
	}
}
	;
	
// =====================================================
// I/O OPERATIONS (print, read)
// =====================================================

print_code: PRINT '(' ID ')'';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int i = get_var_index($3);
    if(i == -1) {
        printf("\nWarning: Variable '%s' not found in print statement", $3);
        $$ = 0;
    } else {
        printf("\nPrinting variable %s: ", variable[i].var_name);
        if(variable[i].var_type == 0){
            printf("%c", variable[i].value.cval);
        }
        else if(variable[i].var_type == 1){
            printf("%d", variable[i].value.ival);
        }
        else if(variable[i].var_type == 2){
            printf("%f", variable[i].value.fval);
        }
        else if(variable[i].var_type == 3){
            printf("%s", variable[i].value.sval ? variable[i].value.sval : "");
        }
        $$ = 1;
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "print %s", $3);
        emit(buf);
        store_icg_line(buf);
    }
    }
}
| PRINT '(' STRING_LITERAL ')'';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    printf("\n%s", $3);
    $$ = 1;
    
    // ICG
    char buf[256];
    snprintf(buf, sizeof(buf), "print \"%s\"", $3);
    emit(buf);
    store_icg_line(buf);
    }
}
;
	
	// CFG for read() function
	
read_code: READ'(' ID ')'';'{
	if(suppress_exec > 0) { $$ = 0; }
	else {
	int i = get_var_index($3);
	if(i == -1) {
		printf("\nError: Variable '%s' not declared at line %d", $3, line_num);
		$$ = 0;
	} else {
		FILE *src = input_file ? input_file : stdin;
		printf("\nReading value for variable '%s'", variable[i].var_name);
		if(variable[i].var_type == 1) {
			if(fscanf(src, "%d", &variable[i].value.ival) == 1)
				printf("\nRead integer: %d", variable[i].value.ival);
			else printf("\nWarning: Could not read integer for '%s'", variable[i].var_name);
		} else if(variable[i].var_type == 2) {
			if(fscanf(src, "%f", &variable[i].value.fval) == 1)
				printf("\nRead float: %f", variable[i].value.fval);
			else printf("\nWarning: Could not read float for '%s'", variable[i].var_name);
		} else if(variable[i].var_type == 0) {
			char tmp; fscanf(src, " %c", &tmp);
			variable[i].value.cval = tmp;
			printf("\nRead char: %c", variable[i].value.cval);
		} else if(variable[i].var_type == 3) {
			char rbuf[256];
			if(fscanf(src, "%255s", rbuf) == 1) {
				variable[i].value.sval = strdup(rbuf);
				printf("\nRead string: %s", variable[i].value.sval);
			} else printf("\nWarning: Could not read string for '%s'", variable[i].var_name);
		}
		$$ = 1;
		// ICG
		char buf[256];
		snprintf(buf, sizeof(buf), "read %s", $3);
		emit(buf);
		store_icg_line(buf);
	}
	}
}
	;
	
// =====================================================
// SWITCH-CASE
// =====================================================

switch_code: SWITCH '(' ID ')' '{' case_code '}' {
	printf("\nSwitch-case structure detected.");
	
	// ICG
	char buf[256];
	snprintf(buf, sizeof(buf), "# switch(%s) end", $3);
	emit(buf);
	store_icg_line(buf);
}
	;
case_code: casenum_code default_code
	;

casenum_code: CASE NUM '{' code '}' casenum_code {
        printf("\nCase no--> %d", (int)$2);
        $$ = $4;
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "# case %d:", (int)$2);
        emit(buf);
        store_icg_line(buf);
    }
    | /* empty */ {
        $$ = 0;
    }
    ;
default_code: DEFAULT '{' code '}' {
    // ICG
    emit("# default:");
    store_icg_line("# default:");
}
	;


// =====================================================
// LOOPS (from-to loop, while loop)
// =====================================================

for_code: FROM ID TO NUM INC NUM '{' code '}' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    printf("\nFor loop detected");
    int ii = get_var_index($2);
    if(ii == -1) {
        printf("\nWarning: Loop variable '%s' not declared", $2);
        $$ = 0;
    } else if(variable[ii].var_type != 1) {  
        printf("\nWarning: Loop variable must be an integer");
        $$ = 0;
    } else {
        int i = variable[ii].value.ival;
        int j = (int)$4;
        int inc = (int)$6;
        
        printf("\nStarting loop with %s = %d to %d increment %d", 
               variable[ii].var_name, i, j, inc);
        
        // ICG: for loop
        char* lstart = new_label();
        char* lend = new_label();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s:", lstart);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "if %s >= %d goto %s", $2, j, lend);
        emit(buf); store_icg_line(buf);
        
        for(int k=i; k<j; k=k+inc){
            variable[ii].value.ival = k;
            code_result = $8;
            printf("\nLoop iteration %d: %s = %d", 
                   k, variable[ii].var_name, variable[ii].value.ival);
        }
        
        snprintf(buf, sizeof(buf), "%s = %s + %d", $2, $2, inc);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "goto %s", lstart);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "%s:", lend);
        emit(buf); store_icg_line(buf);
        
        free(lstart);
        free(lend);
        
        variable[ii].value.ival = j;
        printf("\nLoop completed. Final value of %s = %d", 
               variable[ii].var_name, variable[ii].value.ival);
        $$ = variable[ii].value.ival;
    }
    }  /* end else (suppress_exec) */
}
| FROM ID TO NUM DEC NUM '{' code '}' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    printf("\nFor loop detected");
    int ii = get_var_index($2);
    if(ii == -1) {
        printf("\nWarning: Loop variable '%s' not declared", $2);
        $$ = 0;
    } else if(variable[ii].var_type != 1) {
        printf("\nWarning: Loop variable must be an integer");
        $$ = 0;
    } else {
        int i = variable[ii].value.ival;
        int j = (int)$4;
        int dec = (int)$6;
        
        printf("\nStarting loop with %s = %d to %d decrement %d", 
               variable[ii].var_name, i, j, dec);
        
        // ICG: for loop (decrement)
        char* lstart = new_label();
        char* lend = new_label();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s:", lstart);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "if %s <= %d goto %s", $2, j, lend);
        emit(buf); store_icg_line(buf);
        
        for(int k=i; k>j; k=k-dec){
            variable[ii].value.ival = k;
            code_result = $8;
            printf("\nLoop iteration %d: %s = %d", 
                   k, variable[ii].var_name, variable[ii].value.ival);
        }
        
        snprintf(buf, sizeof(buf), "%s = %s - %d", $2, $2, dec);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "goto %s", lstart);
        emit(buf); store_icg_line(buf);
        snprintf(buf, sizeof(buf), "%s:", lend);
        emit(buf); store_icg_line(buf);
        
        free(lstart);
        free(lend);
        
        variable[ii].value.ival = j;
        printf("\nLoop completed. Final value of %s = %d", 
               variable[ii].var_name, variable[ii].value.ival);
        $$ = variable[ii].value.ival;
    }
    }  /* end else (suppress_exec) */
}
;

	// CFG for while loop (now supports general boolean expressions)
	
while_code: WHILE '(' bool_expression ')' '{' code '}' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    printf("\nWhile loop detected");
    
    // ICG: while loop
    char* lstart = new_label();
    char* lend = new_label();
    char buf[256];
    snprintf(buf, sizeof(buf), "%s:    # while loop start", lstart);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "if_false goto %s", lend);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "goto %s", lstart);
    emit(buf); store_icg_line(buf);
    snprintf(buf, sizeof(buf), "%s:    # while loop end", lend);
    emit(buf); store_icg_line(buf);
    
    free(lstart);
    free(lend);
    
    printf("\nWhile loop body executed with condition result: %d", (int)$3);
    printf("\nWhile loop finished\n");
    $$ = $6;
    }  /* end else (suppress_exec) */
}
;

// =====================================================
// CONTROL FLOW (if / elif / otherwise)
// Nested condition support via cm_stack (condition-matched stack).
// suppress_exec prevents dead branches from executing.
// =====================================================

condition:
    { CM_PUSH(0); } if_statement
    {
        CM_POP();
        $$ = $2;
    }
    ;

/* Helper: evaluates condition, emits if_false goto, then suppresses if false */
if_prefix: IF '(' bool_expression ')'
    {
        $$ = $3;
        // ICG: emit conditional jump BEFORE body code
        char* lfalse = new_label();
        char buf_ip[256];
        snprintf(buf_ip, sizeof(buf_ip), "if_false goto %s", lfalse);
        emit(buf_ip); store_icg_line(buf_ip);
        ICG_LPUSH(lfalse);
        // Now suppress execution + ICG for false branch
        if($3 != 1) { suppress_exec++; suppress_icg++; }
    }
    ;

if_statement:
    /* 1. Simple if */
    if_prefix '{' code '}'
    {
        if($1 != 1) { suppress_exec--; suppress_icg--; }
        if($1 == 1) { CM_SET(1); }
        // ICG: emit false-label after body
        char* lfalse = ICG_LPOP();
        char buf_s[256];
        snprintf(buf_s, sizeof(buf_s), "%s:", lfalse);
        emit(buf_s); store_icg_line(buf_s);
        free(lfalse);
        $$ = $3;
    }
    /* 2. if-else */
    | if_prefix '{' code '}'
    {                                   /* $5: swap suppression at else boundary */
        if($1 != 1) { suppress_exec--; suppress_icg--; }
        // ICG: jump over else, emit else-label
        char* lfalse = ICG_LPOP();
        char* lend = new_label();
        char buf_ie[256];
        snprintf(buf_ie, sizeof(buf_ie), "goto %s", lend);
        emit(buf_ie); store_icg_line(buf_ie);
        snprintf(buf_ie, sizeof(buf_ie), "%s:    # otherwise", lfalse);
        emit(buf_ie); store_icg_line(buf_ie);
        free(lfalse);
        ICG_LPUSH(lend);
        if($1 == 1) { suppress_exec++; suppress_icg++; }
    }
    ELSE '{' code '}'
    {
        if($1 == 1) { suppress_exec--; suppress_icg--; }
        // ICG: emit end-label
        char* lend = ICG_LPOP();
        char buf_ie[256];
        snprintf(buf_ie, sizeof(buf_ie), "%s:", lend);
        emit(buf_ie); store_icg_line(buf_ie);
        free(lend);
        if($1 == 1) { CM_SET(1); $$ = $3; }
        else        { CM_SET(1); $$ = $8; }
    }
    /* 3+4. if + elif_list (with or without optional else) */
    | if_prefix '{' code '}'
    {                                   /* $5: restore if-body suppression; mark if taken */
        if($1 != 1) { suppress_exec--; suppress_icg--; }
        if($1 == 1) CM_SET(1);
        // ICG: jump to end, emit if-false label
        char* lfalse = ICG_LPOP();
        char* lend = new_label();
        char buf_34[256];
        snprintf(buf_34, sizeof(buf_34), "goto %s", lend);
        emit(buf_34); store_icg_line(buf_34);
        snprintf(buf_34, sizeof(buf_34), "%s:", lfalse);
        emit(buf_34); store_icg_line(buf_34);
        free(lfalse);
        ICG_LPUSH(lend);
    }
    elif_list else_opt
    {
        /* $6 = elif_list, $7 = else_opt */
        // ICG: emit end-label
        char* lend = ICG_LPOP();
        char buf_34[256];
        snprintf(buf_34, sizeof(buf_34), "%s:", lend);
        emit(buf_34); store_icg_line(buf_34);
        free(lend);
        if($1 == 1) { $$ = $3; }
        else $$ = $7;
    }
    ;

/* Optional else clause after an elif chain.
   Using a named non-terminal avoids the reduce/reduce conflict that arises
   when an anonymous mid-rule action (empty reduce) appears at the same position
   as the end of the elif-only alternative. */
else_opt:
    /* no else */
    { $$ = 0; }
    | else_part
    { $$ = $1; }
    ;

/* else_part fires a mid-rule action BEFORE ELSE is shifted so that suppress_exec
   is correctly set before the else body is parsed. */
else_part:
    { if(CM_GET()) { suppress_exec++; suppress_icg++; } }   /* $1: suppress else body if any branch already matched */
    ELSE '{' code '}'
    {
        /* $2=ELSE $3='{' $4=code $5='}' */
        if(CM_GET()) { suppress_exec--; suppress_icg--; }
        if(!CM_GET()) { CM_SET(1); }
        $$ = $4;
    }
    ;

elif_list:
    /* chained elifs */
    elif_list ELIF '(' bool_expression ')'
    {
        // ICG: emit conditional jump BEFORE suppressing
        char* lnext = new_label();
        char buf_el[256];
        snprintf(buf_el, sizeof(buf_el), "if_false goto %s", lnext);
        emit(buf_el); store_icg_line(buf_el);
        ICG_LPUSH(lnext);
        if(CM_GET() || $4 != 1) { suppress_exec++; suppress_icg++; }
    }   /* $6 */
    '{' code '}'
    {
        if(CM_GET() || $4 != 1) { suppress_exec--; suppress_icg--; }
        // ICG: jump to end, emit next-elif label
        char* lnext = ICG_LPOP();
        char* lend = ICG_LPEEK();
        char buf_el[256];
        snprintf(buf_el, sizeof(buf_el), "goto %s", lend);
        emit(buf_el); store_icg_line(buf_el);
        snprintf(buf_el, sizeof(buf_el), "%s:", lnext);
        emit(buf_el); store_icg_line(buf_el);
        free(lnext);
        if(!CM_GET() && $4 == 1) {
            CM_SET(1);
            $$ = $8;
        } else {
            $$ = $1;
        }
    }
    /* first elif */
    | ELIF '(' bool_expression ')'
    {
        // ICG: emit conditional jump BEFORE suppressing
        char* lnext = new_label();
        char buf_el[256];
        snprintf(buf_el, sizeof(buf_el), "if_false goto %s", lnext);
        emit(buf_el); store_icg_line(buf_el);
        ICG_LPUSH(lnext);
        if(CM_GET() || $3 != 1) { suppress_exec++; suppress_icg++; }
    }   /* $5 */
    '{' code '}'
    {
        if(CM_GET() || $3 != 1) { suppress_exec--; suppress_icg--; }
        // ICG: jump to end, emit next-elif label
        char* lnext = ICG_LPOP();
        char* lend = ICG_LPEEK();
        char buf_el[256];
        snprintf(buf_el, sizeof(buf_el), "goto %s", lend);
        emit(buf_el); store_icg_line(buf_el);
        snprintf(buf_el, sizeof(buf_el), "%s:", lnext);
        emit(buf_el); store_icg_line(buf_el);
        free(lnext);
        if(!CM_GET() && $3 == 1) {
            CM_SET(1);
            $$ = $7;
        } else {
            $$ = 0;
        }
    }
    ;
	
// =====================================================
// EXPRESSION EVALUATION
// Precedence chain: e (add/sub) -> f (mul/div/mod/pow) -> t (atoms)
// e handles PLUS, MINUS
// f handles MUL, DIV, MOD, POW
// t handles NUM, ID, parenthesized expressions, math functions
// =====================================================

expression: e {$$ = $1;}
    ;

e: e PLUS f {
        $$ = $1 + $3;
        
        // ICG
        char* t = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f + %.6f", t, $1, $3);
        emit(buf); store_icg_line(buf);
        free(t);
    }
    | e MINUS f {
        $$ = $1 - $3;
        
        // ICG
        char* t = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f - %.6f", t, $1, $3);
        emit(buf); store_icg_line(buf);
        free(t);
    }
    | f {
        $$ = $1;
    }
    ;

f: f MUL t {
        $$ = $1 * $3;
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f * %.6f", t_name, $1, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    | f DIV t {
        if($3 != 0) {
            $$ = $1 / $3;
        } else {
            printf("\nError: Division by zero");
            $$ = 0;
        }
        
        // ICG
        if($3 != 0) {
            char* t_name = new_temp();
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = %.6f / %.6f", t_name, $1, $3);
            emit(buf); store_icg_line(buf);
            free(t_name);
        }
    }
    | f MOD t {
        if($3 != 0) {
            $$ = (int)$1 % (int)$3; 
            printf("\nModulo operation: %d", (int)$$);
        } else {
            printf("\nError: Modulo by zero");
            $$ = 0;
        }
        
        // ICG
        if($3 != 0) {
            char* t_name = new_temp();
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = %d %% %d", t_name, (int)$1, (int)$3);
            emit(buf); store_icg_line(buf);
            free(t_name);
        }
    }
    | t POW f {
        $$ = pow($1, $3);
        printf("\nPower operation: %f ^ %f = %f", $1, $3, $$);
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f ^ %.6f", t_name, $1, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    | t {
        $$ = $1;
    }
    ;

t: '(' e ')' {
        $$ = $2;
    }
    | NUM {
        $$ = $1;
    }
    | ID {
        int i = get_var_index($1);
        if(i != -1) {
            switch(variable[i].var_type) {
                case 1:
                    $$ = (double)variable[i].value.ival;
                    break;
                case 2:
                    $$ = variable[i].value.fval;
                    break;
                case 0:
                    $$ = (double)variable[i].value.cval;
                    break;
                default:
                    printf("\nError: Invalid type for mathematical operation");
                    $$ = 0;
                    break;
            }
        } else {
            printf("\nError: Variable '%s' not declared at line %d", $1, line_num);
            $$ = 0;
        }
    }
    | SQRT '(' e ')' {
        if($3 >= 0) {
            $$ = sqrt($3);
            printf("\nSquare root operation: sqrt(%f) = %f", $3, $$);
        } else {
            printf("\nError: Square root of negative number");
            $$ = 0;
        }
        
        // ICG
        if($3 >= 0) {
            char* t_name = new_temp();
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = sqrt(%.6f)", t_name, $3);
            emit(buf); store_icg_line(buf);
            free(t_name);
        }
    }
    | ABS '(' e ')' {
        $$ = fabs($3);
        printf("\nAbsolute value operation: |%f| = %f", $3, $$);
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = abs(%.6f)", t_name, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    | LOG '(' e ')' {
        if($3 > 0) {
            $$ = log($3);
            printf("\nLogarithm operation: log(%f) = %f", $3, $$);
        } else {
            printf("\nError: Logarithm of non-positive number");
            $$ = 0;
        }
        
        // ICG
        if($3 > 0) {
            char* t_name = new_temp();
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = log(%.6f)", t_name, $3);
            emit(buf); store_icg_line(buf);
            free(t_name);
        }
    }
    | SIN '(' e ')' {
        $$ = sin($3);
        printf("\nSine operation: sin(%f) = %f", $3, $$);
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = sin(%.6f)", t_name, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    | COS '(' e ')' {
        $$ = cos($3);
        printf("\nCosine operation: cos(%f) = %f", $3, $$);
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = cos(%.6f)", t_name, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    | TAN '(' e ')' {
        $$ = tan($3);
        printf("\nTangent operation: tan(%f) = %f", $3, $$);
        
        // ICG
        char* t_name = new_temp();
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = tan(%.6f)", t_name, $3);
        emit(buf); store_icg_line(buf);
        free(t_name);
    }
    ;

// =====================================================
// BOOLEAN EXPRESSIONS
// Supports: AND (&&), OR (||), NOT (!)
// Comparison: >, <, >=, <=, ==, !=, <>, ===, !==
// =====================================================

bool_expression: 
    bool_expression AND bool_expression {
        $$ = ($1 && $3) ? 1 : 0;
    }
    | bool_expression OR bool_expression {
        $$ = ($1 || $3) ? 1 : 0;
    }
    | NOT bool_expression {
        $$ = !$2 ? 1 : 0;
    }
    | '(' bool_expression ')' {
        $$ = $2;
    }
    | expression GT expression {
        $$ = ($1 > $3) ? 1 : 0;
    }
    | expression LT expression {
        $$ = ($1 < $3) ? 1 : 0;
    }
    | expression GOE expression {
        $$ = ($1 >= $3) ? 1 : 0;
    }
    | expression LOE expression {
        $$ = ($1 <= $3) ? 1 : 0;
    }
    | expression EQUAL expression {
        $$ = ($1==$3) ? 1 : 0;
    }
    | expression STRICT_EQUAL expression {
        $$ = ($1==$3 && get_expression_type($1) == get_expression_type($3)) ? 1 : 0;
    }
    | expression STRICT_NEQ expression {
        $$ = ($1!=$3 || get_expression_type($1) != get_expression_type($3)) ? 1 : 0;
    }
    | expression NOTEQUAL expression {
        $$ = ($1!=$3) ? 1 : 0;
    }
    | expression NEQ expression {
        $$ = ($1!=$3) ? 1 : 0;
    }
    ;

// =====================================================
// VARIABLE DECLARATION & INITIALIZATION
// Supports: int, float, char, string, dict, stack, queue
// Multiple declarations: int a=10, b=20, c;
// Type checking enforced during initialization.
// =====================================================

declaration: TYPE { current_decl_type = (int)$1; } init_list ';' {
    set_var_type(current_decl_type);
    printf("\nVariable(s) declared and initialized");
    current_decl_type = -1;
    $$ = 0;
}
;

init_list: init_list ',' init_item {
    $<val>$ = $<val>0;
}
| init_item {
    $<val>$ = $<val>0;
}
;

init_item: ID {
    if(suppress_exec > 0) { /* skip declaration in dead branch */ }
    else if(search_var($1)==0){
        strcpy(variable[no_var].var_name, $1);
        variable[no_var].var_type = current_decl_type;
        printf("\nDeclared variable: %s", $1);
        
        switch(variable[no_var].var_type) {
            case 1:
                variable[no_var].value.ival = 0;
                break;
            case 2:
                variable[no_var].value.fval = 0.0;
                break;
            case 0:
                variable[no_var].value.cval = '\0';
                break;
            case 3:
                variable[no_var].value.sval = strdup("");
                break;
            case 4:
                variable[no_var].value.dict.size = 0;
                break;
            case 5:
                variable[no_var].value.stack.top = -1;
                for(int j = 0; j < 100; j++) variable[no_var].value.stack.values[j] = 0;
                break;
            case 6:
                init_queue(no_var);
                break;
        }
        no_var++;
        
        // ICG
        char buf[256];
        const char* type_names[] = {"char", "int", "float", "string", "dict", "stack", "queue"};
        int t = current_decl_type;
        if(t >= 0 && t <= 6) {
            snprintf(buf, sizeof(buf), "declare %s %s", type_names[t], $1);
        } else {
            snprintf(buf, sizeof(buf), "declare unknown %s", $1);
        }
        emit(buf); store_icg_line(buf);
    }
    else{
        printf("\nWarning: Variable '%s' already declared", $1);
    }
}
| ID '=' expression {
    if(suppress_exec > 0) { /* skip in dead branch */ }
    else if(search_var($1)==0){
        strcpy(variable[no_var].var_name, $1);
        variable[no_var].var_type = current_decl_type;  
        printf("\nDeclared variable: %s with initialization", $1);
        
        switch(variable[no_var].var_type) {
            case 1:
                if($3 != (int)$3) {
                    printf("\nError: Type mismatch at line %d - cannot assign float value to int variable '%s'", line_num, $1);
                } else {
                    variable[no_var].value.ival = (int)$3;
                    printf("\nInitialized to integer: %d", variable[no_var].value.ival);
                }
                break;
            case 2:
                if($3 == (int)$3) {
                    printf("\nImplicit type conversion at line %d: int to float for variable '%s'", line_num, $1);
                }
                variable[no_var].value.fval = (float)$3;
                printf("\nInitialized to float: %f", variable[no_var].value.fval);
                break;
            case 0:
                variable[no_var].value.cval = (char)(int)$3;
                printf("\nInitialized to char: %c", variable[no_var].value.cval);
                break;
        }
        no_var++;
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %.6f", $1, $3);
        emit(buf); store_icg_line(buf);
    }
    else{
        printf("\nWarning: Variable '%s' already declared", $1);
    }
}
| ID '=' STRING_LITERAL {
    if(suppress_exec > 0) { /* skip in dead branch */ }
    else if(search_var($1)==0){
        strcpy(variable[no_var].var_name, $1);
        variable[no_var].var_type = current_decl_type;
        
        if(variable[no_var].var_type == 3) {
            variable[no_var].value.sval = strdup($3);
            printf("\nDeclared string variable: %s with initialization", $1);
            printf("\nInitialized to string: %s", $3);
        } else {
            printf("\nError: Type mismatch at line %d - cannot assign string to non-string variable '%s'", line_num, $1);
        }
        no_var++;
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = \"%s\"", $1, $3);
        emit(buf); store_icg_line(buf);
    }
    else{
        printf("\nWarning: Variable '%s' already declared", $1);
    }
}
;

// =====================================================
// ASSIGNMENT (with type checking)
// Policy:
//   int <- float   => Error (no implicit truncation)
//   float <- int   => OK (implicit conversion, message printed)
//   string <- num  => Error (type mismatch)
//   num <- string  => Error (type mismatch)
// =====================================================

assignment: ID '=' expression ';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int i = get_var_index($1);
    if(i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", $1, line_num);
        $$ = 0;
    } else {
        int assign_ok = 1;
        switch(variable[i].var_type) {
            case 1:
                if($3 != (int)$3) {
                    printf("\nError: Type mismatch at line %d - cannot assign float value to int variable '%s'", line_num, $1);
                    assign_ok = 0;
                    $$ = 0;
                } else {
                    variable[i].value.ival = (int)$3;
                    printf("\nAssigning value %d to %s", variable[i].value.ival, variable[i].var_name);
                    $$ = $3;
                }
                break;
            case 2:
                if($3 == (int)$3) {
                    printf("\nImplicit type conversion at line %d: int to float for variable '%s'", line_num, $1);
                }
                variable[i].value.fval = (float)$3;
                printf("\nAssigning value %f to %s", variable[i].value.fval, variable[i].var_name);
                $$ = $3;
                break;
            case 0:
                variable[i].value.cval = (char)(int)$3;
                $$ = $3;
                break;
            case 3: // string
                printf("\nError: Type mismatch at line %d - cannot assign numeric to string variable '%s'", line_num, $1);
                assign_ok = 0;
                $$ = 0;
                break;
            default:
                $$ = $3;
        }
        
        // ICG: only emit if assignment succeeded
        if(assign_ok) {
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = %.6f", $1, $3);
            emit(buf); store_icg_line(buf);
        }
    }
    }
}
| ID INCREMENT ';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int i = get_var_index($1);
    if(i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", $1, line_num);
        $$ = 0;
    } else {
        if(variable[i].var_type==1){
            variable[i].value.ival++;
            printf("\nIncrementing %s to %d", variable[i].var_name, variable[i].value.ival);
            $$ = variable[i].value.ival;
        }
        else if(variable[i].var_type==2){
            variable[i].value.fval++;
            printf("\nIncrementing %s to %f", variable[i].var_name, variable[i].value.fval);
            $$ = variable[i].value.fval;
        }
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s + 1", $1, $1);
        emit(buf); store_icg_line(buf);
    }
    }
}
| ID DECREMENT ';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int i = get_var_index($1);
    if(i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", $1, line_num);
        $$ = 0;
    } else {
        if(variable[i].var_type==1){
            variable[i].value.ival--;
            printf("\nDecrementing %s to %d", variable[i].var_name, variable[i].value.ival);
            $$ = variable[i].value.ival;
        }
        else if(variable[i].var_type==2){
            variable[i].value.fval--;
            printf("\nDecrementing %s to %f", variable[i].var_name, variable[i].value.fval);
            $$ = variable[i].value.fval;
        }
        
        // ICG
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s - 1", $1, $1);
        emit(buf); store_icg_line(buf);
    }
    }
}
| ID '=' STRING_LITERAL ';' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    int i = get_var_index($1);
    if(i == -1) {
        printf("\nError: Variable '%s' not declared at line %d", $1, line_num);
        $$ = 0;
    } else {
        if(variable[i].var_type == 3){
            variable[i].value.sval = strdup($3);
            printf("\nAssigning string value: %s to %s", variable[i].value.sval, variable[i].var_name);
            $$ = 1;
            // ICG
            char buf[256];
            snprintf(buf, sizeof(buf), "%s = \"%s\"", $1, $3);
            emit(buf); store_icg_line(buf);
        } else {
            printf("\nError: Type mismatch at line %d - cannot assign string to non-string variable '%s'", line_num, $1);
            $$ = 0;
        }
        
    }
    }
}
;

TYPE: INT	{$$ = 1; printf("\nVariable type--> Integer");}
	| FLOAT	{$$ = 2; printf("\nVariable type--> Float");}
	| CHAR	{$$ = 0; printf("\nVariable type--> Character");}
	| STRING {$$ = 3; printf("\nVariable type--> String");}
	| DICT {
		$$ = 4;
		printf("\nVariable type--> Dictionary");
	}
	| STACK {
		$$ = 5;
		printf("\nVariable type--> Stack");
	}
	| QUEUE {
		$$ = 6; 
		printf("\nVariable type--> Queue");
	}
	;

// =====================================================
// DATA STRUCTURES (Dictionary, Stack, Queue)
// =====================================================

dict_operation: 
    SET '(' ID ',' NUM ',' expression ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i = get_var_index($3);
        if(i != -1 && variable[i].var_type == 4) {
            int index = (int)$5;
            if(index >= 0 && index < 100) {
                variable[i].value.dict.values[index] = $7;
                if(index >= variable[i].value.dict.size) {
                    variable[i].value.dict.size = index + 1;
                }
                printf("\nSet value %f at index %d in dictionary %s", $7, index, variable[i].var_name);
            } else {
                printf("\nError: Index out of bounds");
            }
        }
        $$ = 0;
        }
    }
    | GET '(' ID ',' NUM ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i = get_var_index($3);
        if(i != -1 && variable[i].var_type == 4) {
            int index = (int)$5;
            if(index >= 0 && index < variable[i].value.dict.size) {
                printf("\nValue at index %d in dictionary %s: %f", 
                       index, variable[i].var_name, 
                       variable[i].value.dict.values[index]);
            } else {
                printf("\nError: Index out of bounds");
            }
        }
        $$ = 0;
        }
    }
    | CONCAT '(' ID ',' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i1 = get_var_index($3);
        int i2 = get_var_index($5);
        if(i1 != -1 && i2 != -1 && 
           variable[i1].var_type == 4 && variable[i2].var_type == 4) {
            int new_size = variable[i1].value.dict.size + variable[i2].value.dict.size;
            if(new_size <= 100) {
                for(int j = 0; j < variable[i2].value.dict.size; j++) {
                    variable[i1].value.dict.values[variable[i1].value.dict.size + j] = 
                        variable[i2].value.dict.values[j];
                }
                variable[i1].value.dict.size = new_size;
                printf("\nConcatenated dictionary %s to %s", 
                       variable[i2].var_name, variable[i1].var_name);
            }
        }
        $$ = 0;
        }
    }
    | COPY '(' ID ',' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i1 = get_var_index($3);
        int i2 = get_var_index($5);
        if(i1 != -1 && i2 != -1 && 
           variable[i1].var_type == 4 && variable[i2].var_type == 4) {
            variable[i2].value.dict.size = variable[i1].value.dict.size;
            for(int j = 0; j < variable[i1].value.dict.size; j++) {
                variable[i2].value.dict.values[j] = variable[i1].value.dict.values[j];
            }
            printf("\nCopied dictionary %s to %s", 
                   variable[i1].var_name, variable[i2].var_name);
        }
        $$ = 0;
        }
    }
    | SIZE '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i = get_var_index($3);
        if(i != -1 && variable[i].var_type == 4) {
            printf("\nSize of dictionary %s: %d", 
                   variable[i].var_name, variable[i].value.dict.size);
        }
        $$ = 0;
        }
    }
    | COMPARE '(' ID ',' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int i1 = get_var_index($3);
        int i2 = get_var_index($5);
        if(i1 != -1 && i2 != -1 && 
           variable[i1].var_type == 4 && variable[i2].var_type == 4) {
            if(variable[i1].value.dict.size != variable[i2].value.dict.size) {
                printf("\nDictionaries are different (different sizes)");
            } else {
                int same = 1;
                for(int j = 0; j < variable[i1].value.dict.size; j++) {
                    if(variable[i1].value.dict.values[j] != 
                       variable[i2].value.dict.values[j]) {
                        same = 0;
                        break;
                    }
                }
                printf("\nDictionaries are %s", same ? "same" : "different");
            }
        }
        $$ = 0;
        }
    }
    ;

stack_operation:
    PUSH '(' ID ',' expression ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 5) {
            if(push(idx, $5)) {
                printf("\nSuccessfully pushed %f to stack %s", $5, variable[idx].var_name);
            }
        } else {
            printf("\nError: Invalid stack operation - %s is not a stack", $3);
        }
        $$ = $5;
        }
    }
    | POP '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 5) {
            if(variable[idx].value.stack.top >= 0) {
                double value = pop(idx);
                printf("\nSuccessfully popped %f from stack %s", value, variable[idx].var_name);
                $$ = value;
            } else {
                printf("\nError: Cannot pop from empty stack %s", variable[idx].var_name);
                $$ = 0;
            }
        } else {
            printf("\nError: Invalid stack operation - %s is not a stack", $3);
            $$ = 0;
        }
        }
    }
    | TOP '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 5) {
            if(variable[idx].value.stack.top >= 0) {
                double value = top(idx);
                printf("\nTop of stack %s: %f (position: %d)", 
                       variable[idx].var_name, value, variable[idx].value.stack.top);
                $$ = value;
            } else {
                printf("\nError: Stack %s is empty", variable[idx].var_name);
                $$ = 0;
            }
        } else {
            printf("\nError: Invalid stack operation - %s is not a stack", $3);
            $$ = 0;
        }
        }
    }
    | ISEMPTY '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 5) {
            int empty = is_empty(idx);
            printf("\nStack %s is %s (top: %d)", 
                   variable[idx].var_name, 
                   empty ? "empty" : "not empty",
                   variable[idx].value.stack.top);
            $$ = empty;
        } else {
            if(idx == -1) {
                printf("\nError: Stack %s not declared", $3);
            } else {
                printf("\nError: Variable %s is not a stack", $3);
            }
            $$ = 1;
        }
        }
    }
    | STACKSIZE '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 5) {
            int size = stack_size(idx);
            printf("\nStack %s size: %d", variable[idx].var_name, size);
            $$ = size;
        } else {
            if(idx == -1) {
                printf("\nError: Stack %s not declared", $3);
            } else {
                printf("\nError: Variable %s is not a stack", $3);
            }
            $$ = 0;
        }
        }
    }
    ;

queue_operation:
    ENQUEUE '(' ID ',' expression ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            if(enqueue(idx, $5)) {
                printf("\nSuccessfully enqueued %f to queue %s", $5, variable[idx].var_name);
            }
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
        }
        $$ = $5;
        }
    }
    | DEQUEUE '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            double value = dequeue(idx);
            printf("\nSuccessfully dequeued %f from queue %s", value, variable[idx].var_name);
            $$ = value;
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
            $$ = 0;
        }
        }
    }
    | FRONT '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            double value = get_front(idx);
            printf("\nFront of queue %s: %f", variable[idx].var_name, value);
            $$ = value;
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
            $$ = 0;
        }
        }
    }
    | REAR '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            double value = get_rear(idx);
            printf("\nRear of queue %s: %f", variable[idx].var_name, value);
            $$ = value;
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
            $$ = 0;
        }
        }
    }
    | QEMPTY '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            int empty = is_queue_empty(idx);
            printf("\nQueue %s is %s", variable[idx].var_name, 
                   empty ? "empty" : "not empty");
            $$ = empty;
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
            $$ = 1;
        }
        }
    }
    | QSIZE '(' ID ')' ';' {
        if(suppress_exec > 0) { $$ = 0; }
        else {
        int idx = get_var_index($3);
        if(idx != -1 && variable[idx].var_type == 6) {
            int size = queue_size(idx);
            printf("\nQueue %s size: %d", variable[idx].var_name, size);
            $$ = size;
        } else {
            printf("\nError: Invalid queue operation - %s is not a queue", $3);
            $$ = 0;
        }
        }
    }
    ;

%%

void yyerror(char *s)
{
	fprintf(stderr, "\nSyntax Error: %s at line %d", s, line_num);
}

int main(){
	// Open input file
	yyin = fopen("test.txt", "r");
	if(!yyin) {
	    fprintf(stderr, "Error: Cannot open test.txt\n");
	    return 1;
	}

	// Open input.txt for read() statements
	input_file = fopen("input.txt", "r");
	if(!input_file) {
	    fprintf(stderr, "Note: input.txt not found; read() will use stdin\n");
	}
	
	// Redirect stdout to testout.txt for execution output
	yyout = freopen("testout.txt", "w", stdout);
	
	// Open ICG output file
	icg_file = fopen("intermediate_code.txt", "w");
	if(icg_file) {
	    fprintf(icg_file, "========================================\n");
	    fprintf(icg_file, "   THREE-ADDRESS INTERMEDIATE CODE\n");
	    fprintf(icg_file, "   Generated by CSE-3212 Compiler\n");
	    fprintf(icg_file, "========================================\n\n");
	}
	
	// Parse
	yyparse();
	
	// Close ICG file
	if(icg_file) {
	    fprintf(icg_file, "\n========================================\n");
	    fprintf(icg_file, "   Total temporaries used: %d\n", temp_count);
	    fprintf(icg_file, "   Total labels used: %d\n", label_count);
	    fprintf(icg_file, "========================================\n");
	    fclose(icg_file);
	}
	
	// Run optimization pass and write optimized code
	opt_file = fopen("optimized_code.txt", "w");
	if(opt_file) {
	    optimize_constant_folding();
	    fclose(opt_file);
	}

	// Close input file if it was opened
	if(input_file) fclose(input_file);

	// Write summary to stderr (which is still console)
	fprintf(stderr, "\n\n=== Compilation Summary ===\n");
	fprintf(stderr, "Execution output: testout.txt\n");
	fprintf(stderr, "Intermediate code: intermediate_code.txt\n");
	fprintf(stderr, "Optimized code: optimized_code.txt\n");
	fprintf(stderr, "===========================\n");
	
	return 0;
}
