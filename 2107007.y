%{
	#include "symtab.h"
	#include "functab.h"
	#include "tac.h"
	#include "runtime.h"
	#include "parser_ctx.h"
	#include "io_runtime.h"
	#include "semantic.h"
	#include "actions.h"

	/* Convenience aliases so grammar actions can use the short names */
	#define suppress_exec    g_ctx.suppress_exec
	#define suppress_icg     g_ctx.suppress_icg
	#define current_decl_type g_ctx.current_decl_type

	int yylex(void);
	void yyerror(char *s);
	extern FILE *yyin;
	extern FILE *yyout;
	extern int line_num;

	int code_result = 0;

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
            if(verbose) printf("\nValid program\n");
            if(verbose) printf("\nNo of variables--> %d", no_var);
            $$ = $1;
        }
        | main {
            if(verbose) printf("\nValid program\n");
            if(verbose) printf("\nNo of variables--> %d", no_var);
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
    act_func_define($2, $7);
}
;

return_statement: RETURN expression ';' {
    $$ = $2;
    if(verbose) printf("\nFunction returning value: %f", $2);
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
    $$ = act_func_call($1);
}
;

// =====================================================
// BUILT-IN FUNCTIONS (power, factorial, prime, max, min)
// =====================================================

power_code: POWER '(' NUM ',' NUM ')'';'	{
	$$ = act_power($3, $5);
}
	;

	// CFG for calculating factorial of a number

factorial_code: FACTO '(' NUM ')' ';'	{
	$$ = act_factorial((int)$3);
}
	;
	
	// CFG for checking if a number is prime or not
	
prime_code: PRIME '(' NUM ')' ';'{
	$$ = act_prime((int)$3);
}
	;

	// CFG for max() function

max_code: MAX '(' ID ',' ID')'';'{
	$$ = act_max($3, $5);
}
	;
	
	// CFG for min() function
	
min_code: MIN '(' ID ',' ID')'';'{
	$$ = act_min($3, $5);
}
	;
	
// =====================================================
// I/O OPERATIONS (print, read)
// =====================================================

print_code: PRINT '(' ID ')'';' {
    $$ = act_print_id($3);
}
| PRINT '(' STRING_LITERAL ')'';' {
    $$ = act_print_str($3);
}
;
	
	// CFG for read() function
	
read_code: READ'(' ID ')'';'{
	$$ = act_read_id($3);
}
	;
	
// =====================================================
// SWITCH-CASE
// =====================================================

switch_code: SWITCH '(' ID ')' '{' case_code '}' {
	if(verbose) printf("\nSwitch-case structure detected.");
	act_switch_end($3);
}
	;
case_code: casenum_code default_code
	;

casenum_code: CASE NUM '{' code '}' casenum_code {
        if(verbose) printf("\nCase no--> %d", (int)$2);
        $$ = $4;
        act_case_icg((int)$2);
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
    $$ = act_for_inc($2, (int)$4, (int)$6, $8);
}
| FROM ID TO NUM DEC NUM '{' code '}' {
    $$ = act_for_dec($2, (int)$4, (int)$6, $8);
}
;

	// CFG for while loop (now supports general boolean expressions)
	
while_code: WHILE '(' bool_expression ')' '{' code '}' {
    if(suppress_exec > 0) { $$ = 0; }
    else {
    if(verbose) printf("\nWhile loop detected");
    act_while_icg();
    if(verbose) printf("\nWhile loop body executed with condition result: %d", (int)$3);
    if(verbose) printf("\nWhile loop finished\n");
    $$ = $6;
    }
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
        act_icg_binop($1, "+", $3);
    }
    | e MINUS f {
        $$ = $1 - $3;
        act_icg_binop($1, "-", $3);
    }
    | f {
        $$ = $1;
    }
    ;

f: f MUL t {
        $$ = $1 * $3;
        act_icg_binop($1, "*", $3);
    }
    | f DIV t {
        if($3 != 0) { $$ = $1 / $3; }
        else { printf("\nError: Division by zero"); $$ = 0; }
        act_icg_div($1, $3);
    }
    | f MOD t {
        if($3 != 0) { $$ = (int)$1 % (int)$3; if(verbose) printf("\nModulo operation: %d", (int)$$); }
        else { printf("\nError: Modulo by zero"); $$ = 0; }
        act_icg_mod((int)$1, (int)$3);
    }
    | t POW f {
        $$ = pow($1, $3);
        if(verbose) printf("\nPower operation: %f ^ %f = %f", $1, $3, $$);
        act_icg_binop($1, "^", $3);
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
        int ok; $$ = act_load_var($1, &ok);
    }
    | SQRT '(' e ')' {
        if($3 >= 0) { $$ = sqrt($3); if(verbose) printf("\nSquare root operation: sqrt(%f) = %f", $3, $$); act_icg_unary("sqrt", $3); }
        else { printf("\nError: Square root of negative number"); $$ = 0; }
    }
    | ABS '(' e ')' {
        $$ = fabs($3);
        if(verbose) printf("\nAbsolute value operation: |%f| = %f", $3, $$);
        act_icg_unary("abs", $3);
    }
    | LOG '(' e ')' {
        if($3 > 0) { $$ = log($3); if(verbose) printf("\nLogarithm operation: log(%f) = %f", $3, $$); act_icg_unary("log", $3); }
        else { printf("\nError: Logarithm of non-positive number"); $$ = 0; }
    }
    | SIN '(' e ')' {
        $$ = sin($3);
        if(verbose) printf("\nSine operation: sin(%f) = %f", $3, $$);
        act_icg_unary("sin", $3);
    }
    | COS '(' e ')' {
        $$ = cos($3);
        if(verbose) printf("\nCosine operation: cos(%f) = %f", $3, $$);
        act_icg_unary("cos", $3);
    }
    | TAN '(' e ')' {
        $$ = tan($3);
        if(verbose) printf("\nTangent operation: tan(%f) = %f", $3, $$);
        act_icg_unary("tan", $3);
    }
    | POWER '(' e ',' e ')' {
        $$ = act_power($3, $5);
    }
    | FACTO '(' e ')' {
        $$ = act_factorial((int)$3);
    }
    | PRIME '(' e ')' {
        $$ = act_prime((int)$3);
    }
    | MAX '(' ID ',' ID ')' {
        $$ = act_max($3, $5);
    }
    | MIN '(' ID ',' ID ')' {
        $$ = act_min($3, $5);
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
    if(verbose) printf("\nVariable(s) declared and initialized");
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
    act_declare_var($1, current_decl_type);
}
| ID '=' expression {
    act_declare_init_expr($1, current_decl_type, $3);
}
| ID '=' STRING_LITERAL {
    act_declare_init_str($1, current_decl_type, $3);
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
    $$ = act_assign_expr($1, $3);
}
| ID INCREMENT ';' {
    $$ = act_assign_increment($1);
}
| ID DECREMENT ';' {
    $$ = act_assign_decrement($1);
}
| ID '=' STRING_LITERAL ';' {
    $$ = act_assign_str($1, $3);
}
;

TYPE: INT	{$$ = 1; if(verbose) printf("\nVariable type--> Integer");}
	| FLOAT	{$$ = 2; if(verbose) printf("\nVariable type--> Float");}
	| CHAR	{$$ = 0; if(verbose) printf("\nVariable type--> Character");}
	| STRING {$$ = 3; if(verbose) printf("\nVariable type--> String");}
	| DICT {
		$$ = 4;
		if(verbose) printf("\nVariable type--> Dictionary");
	}
	| STACK {
		$$ = 5;
		if(verbose) printf("\nVariable type--> Stack");
	}
	| QUEUE {
		$$ = 6; 
		if(verbose) printf("\nVariable type--> Queue");
	}
	;

// =====================================================
// DATA STRUCTURES (Dictionary, Stack, Queue)
// =====================================================

dict_operation: 
    SET '(' ID ',' NUM ',' expression ')' ';' {
        $$ = act_dict_set($3, (int)$5, $7);
    }
    | GET '(' ID ',' NUM ')' ';' {
        $$ = act_dict_get($3, (int)$5);
    }
    | CONCAT '(' ID ',' ID ')' ';' {
        $$ = act_dict_concat($3, $5);
    }
    | COPY '(' ID ',' ID ')' ';' {
        $$ = act_dict_copy($3, $5);
    }
    | SIZE '(' ID ')' ';' {
        $$ = act_dict_size($3);
    }
    | COMPARE '(' ID ',' ID ')' ';' {
        $$ = act_dict_compare($3, $5);
    }
    ;

stack_operation:
    PUSH '(' ID ',' expression ')' ';' {
        $$ = act_stack_push($3, $5);
    }
    | POP '(' ID ')' ';' {
        $$ = act_stack_pop($3);
    }
    | TOP '(' ID ')' ';' {
        $$ = act_stack_top($3);
    }
    | ISEMPTY '(' ID ')' ';' {
        $$ = act_stack_isempty($3);
    }
    | STACKSIZE '(' ID ')' ';' {
        $$ = act_stack_size($3);
    }
    ;

queue_operation:
    ENQUEUE '(' ID ',' expression ')' ';' {
        $$ = act_queue_enqueue($3, $5);
    }
    | DEQUEUE '(' ID ')' ';' {
        $$ = act_queue_dequeue($3);
    }
    | FRONT '(' ID ')' ';' {
        $$ = act_queue_front($3);
    }
    | REAR '(' ID ')' ';' {
        $$ = act_queue_rear($3);
    }
    | QEMPTY '(' ID ')' ';' {
        $$ = act_queue_qempty($3);
    }
    | QSIZE '(' ID ')' ';' {
        $$ = act_queue_qsize($3);
    }
    ;

%%
