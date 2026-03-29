%{
	#include<stdio.h>
	#include<string.h>
	#include<stdlib.h>
	#include "2107007.tab.h"
	extern char* strdup(const char*);
	void yyerror(char *s);
	extern FILE *yyin;
	int line_num = 1;
%}

ID	[_a-zA-Z][_a-zA-Z0-9]*
HEADER	[u][s][i][n][g][ ][a-z]+.[h]
NU	[-]?[0-9][0-9]*[.]?[0-9]*
CH	@[a-zA-Z]@
STR \"[^\"]*\"

%%

[ \t]+
"start()" {return(MAIN);}
"main()"  {return(MAIN);}
"func"   {return(FUNCTION);}
"return" {return(RETURN);}
"string" {return(STRING);}
"int"	{return(INT);}
"char"	{return(CHAR);}
"float"	{return(FLOAT);}
"power"	{return(POWER);}
"facto"	{return(FACTO);}
"checkprime"	{return(PRIME);}
"read"	{return(READ);}
"print"	{return(PRINT);}
"switch"	{return(SWITCH);}
"state"	{return(CASE);}
"complementary"	{return(DEFAULT);}
"if"	{return(IF);}
"elif"	{return(ELIF);}
"otherwise"	{return(ELSE);}
"from"	{return(FROM);}
"to"	{return(TO);}
"inc"	{return(INC);}
"dec"	{return(DEC);}
"max"	{return(MAX);}
"min"	{return(MIN);}
"while"  {return(WHILE);}

"dict"    {return(DICT);}
"get"     {return(GET);}
"set"     {return(SET);}
"concat"  {return(CONCAT);}
"copy"    {return(COPY);}
"size"    {return(SIZE);}
"compare" {return(COMPARE);}

"sqrt"  {return(SQRT);}
"abs"   {return(ABS);}
"log"   {return(LOG);}
"sin"   {return(SIN);}
"cos"   {return(COS);}
"tan"   {return(TAN);}

"==="   {return(STRICT_EQUAL);}
"!=="   {return(STRICT_NEQ);}
"&&"    {return(AND);}
"||"    {return(OR);}
"<>"    {return(NEQ);}
"++"    {return(INCREMENT);}
"--"    {return(DECREMENT);}
">="    {return(GOE);}
"<="    {return(LOE);}
"=="    {return(EQUAL);}
"!="    {return(NOTEQUAL);}
"!"     {return(NOT);}
">"     {return(GT);}
"<"     {return(LT);}
"+"     {return(PLUS);}
"-"     {return(MINUS);}
"*"     {return(MUL);}
"/"     {return(DIV);}
"%"     {return(MOD);}
"^"     {return(POW);}
"="     {return('=');}

"("     {return('(');}
")"     {return(')');}
"{"     {return('{');}
"}"     {return('}');}
","     {return(',');}
";"     {return(';');}

"stack"   {return(STACK);}
"push"    {return(PUSH);}
"pop"     {return(POP);}
"top"     {return(TOP);}
"isempty" {return(ISEMPTY);}
"stacksize" {return(STACKSIZE);}

"queue"    {return(QUEUE);}
"enqueue"  {return(ENQUEUE);}
"dequeue"  {return(DEQUEUE);}
"front"    {return(FRONT);}
"rear"     {return(REAR);}
"qsize"    {return(QSIZE);}
"qempty"   {return(QEMPTY);}

{HEADER}	{ /* ignore header lines */ }

{ID}	{
	yylval.stringValue = strdup(yytext);
	return(ID);
}
{NU}	{	
    int length = strlen(yytext);
    int i = 0;
    while(i<length){
        if(yytext[i]=='.'){
            yylval.val = atof(yytext); 
            return(NUM);
        }
        i++;
    }
    yylval.val = atoi(yytext); 
    return(NUM);
}
{CH}    {yylval.val = (double)yytext[1]; return NUM;}
{STR}   {
    yylval.stringValue = strdup(yytext + 1);
    yylval.stringValue[strlen(yylval.stringValue) - 1] = '\0';
    return STRING_LITERAL;
}

[#].*	{ /* ignore comments */ }
[\n]	{ line_num++; }
.		{ fprintf(stderr, "\nLexical Error: Invalid character '%s' at line %d", yytext, line_num); exit(1); }

%% 

int yywrap(void){
	return 1;
}