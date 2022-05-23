/* cs152-miniL phase3 */


%{
#include <stdio.h>
#include <stdlib.h>
#include "lib.h"
#include <string>
#include <iostream>
void yyerror(const char *msg);
extern int currLine;
extern int currPos;
FILE* yyin;
extern int yylex();
std::string code = "";
%}

%union {
  int int_val;
  double dval;
  char* str;
}

%error-verbose

%token<int_val> DIGIT
%start prog_start
%token FUNCTION "function" SEMICOLON ";" BEGIN_PARAMS "beginparams" END_PARAMS "endparams" BEGIN_LOCALS "beginlocals" END_LOCALS "endlocals" BEGIN_BODY "beginbody" END_BODY "endbody"
%token COMMA ","  COLON ":" INTEGER "integer" ARRAY "array" L_SQUARE_BRACKET "[" R_SQUARE_BRACKET "]" OF "of" ENUM "enum" ASSIGN ":=" 
%token IF "if" THEN "then" ELSE "else" ENDIF "endif" FOR "for" WHILE "while" BEGINLOOP "beginloop" ENDLOOP "endloop" DO "do" READ "read" WRITE "write" CONTINUE "continue"
%token OR "or" AND "and" NOT "not" TRUE "true" FALSE "false" EQ "==" NEQ "<>" LT "<" GT ">" LTE "<=" GTE ">=" ADD "+" SUB "-" MULT "*" DIV "/" MOD "%" L_PAREN "(" R_PAREN ")" RETURN "return" ERROR "symbol" EQSIGN "="
%token <dval> NUMBER "nunmber"
%token <str> IDENT "identifier"
%type functions function declarations declaration statements statement vars var expressions expression bool_exp relation_and_exp relation_exp comp multiplicative_expression term identifiers ident
%right ASSIGN
%left OR
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MULT DIV MOD
%right UMINUS
%left L_SQUARE_BRACKET R_SQUARE_BRACKET
%left L_PAREN R_PAREN

%% 

  /* write your rules here */
prog_start:
  functions   {printf("prog_start -> functions\n");} |
  error '\n'  {yyerrok; yyclearin;}
  ;

functions:
    {printf("functions -> epsilon\n");} | 
    function functions  {printf("functions -> function functions\n");}
    ;

function:
  FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
  {printf("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");
  code.append("Hello World this will output code\n"); std::cout << code << std::endl;}
  ;

declarations:
    { printf("declarations -> epsilon\n");} | 
    declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
    ;

declaration:
  identifiers COLON INTEGER                                                     {printf("declaration -> identifiers COLON INTEGER\n");} |
  identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER   {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");} |
  identifiers COLON ENUM L_PAREN identifiers R_PAREN                            {printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n");}
  ;

statements:
    { printf("statements -> epsilon\n");} |
    statement SEMICOLON statements  {printf("statements -> statement SEMICOLON statements\n");}
    ;

statement:
  var ASSIGN expression                               {printf("statement -> var ASSIGN expression\n");} |
  IF bool_exp THEN statements ENDIF                   {printf("statement -> IF bool_exp THEN statements ENDIF\n");} |
  IF bool_exp THEN statements ELSE statements ENDIF   {printf("statement -> IF bool_exp THEN statements ELSE statements ENDIF\n");} |
  WHILE bool_exp BEGINLOOP statements ENDLOOP         {printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");} |
  DO BEGINLOOP statements ENDLOOP WHILE bool_exp      {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");} |
  READ vars                                           {printf("statement -> READ vars\n");} |
  WRITE vars                                          {printf("statement -> WRITE vars\n");} |
  CONTINUE                                            {printf("statement -> CONTINUE\n");}  |
  RETURN expression                                   {printf("statement -> RETURN expression\n");}
  ;

bool_exp:
  relation_and_exp                      {printf("bool_exp -> relation_and_exp\n");} |
  relation_and_exp OR bool_exp          {printf("bool_exp -> relation_and_exp OR relation_and_exp\n");}
  ;

relation_and_exp:
  relation_exp                        {printf("relation_and_exp -> relation_exp\n");} |
  relation_exp AND relation_and_exp   {printf("relation_and_exp -> relation_exp AND relation_exp\n");}
  ;

relation_exp:
  expression comp expression      {printf("relation_exp -> expression comp expression\n");} |
  TRUE                            {printf("relation_exp -> TRUE\n");} |
  FALSE                           {printf("relation_exp -> FALSE\n");} |
  L_PAREN bool_exp R_PAREN        {printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}  |
  NOT expression comp expression  {printf("relation_exp -> NOT expression comp expression\n");} |
  NOT TRUE                        {printf("relation_exp -> NOT TRUE\n");} |
  NOT FALSE                       {printf("relation_exp -> NOT FALSE\n");} |
  NOT L_PAREN bool_exp R_PAREN    {printf("relation_exp -> NOT L_PAREN bool_exp R_PAREN\n");}
  ;

comp:
  EQ  {printf("comp -> EQ\n");} |
  NEQ {printf("comp -> NEQ\n");} |
  LT  {printf("comp -> LT\n");} |
  GT  {printf("comp -> GT\n");} |
  LTE {printf("comp -> LTE\n");} |
  GTE {printf("comp -> GTE\n");}
  ;

expressions:
    {printf("expressions -> epsilon\n");} | 
    expression                      {printf("expressions -> expression\n");} |
    expression COMMA expressions    {printf("expressions -> expression COMMA expressions\n");}
    ;

expression:
  multiplicative_expression                  {printf("expression -> multiplicative_expression\n");} |
  multiplicative_expression ADD expression   {printf("expression -> multiplicative_expression ADD multiplicative_expression\n");} |
  multiplicative_expression SUB expression   {printf("expression -> multiplicative_expression SUB multiplicative_expression\n");}
  ;

multiplicative_expression:
  term                                     {printf("multiplicative_expression -> term\n");} |
  term MULT multiplicative_expression      {printf("multiplicative_expression -> term MULT term\n");} |
  term DIV multiplicative_expression       {printf("multiplicative_expression -> term DIV term\n");}  |
  term MOD multiplicative_expression       {printf("multiplicative_expression -> term MOD term\n");}
  ;

term:
  ident L_PAREN expressions R_PAREN   {printf("term -> ident L_PAREN expressions R_PAREN\n");} |
  var                                 {printf("term -> var\n");}    |
  NUMBER                              {printf("term -> NUMBER\n");} |
  L_PAREN expression R_PAREN          {printf("term -> L_PAREN expression R_PAREN\n");} |
  SUB var                          {printf("term -> UMINUS var\n");} %prec UMINUS       |
  SUB NUMBER                       {printf("term -> UMINUS NUMBER\n");} %prec UMINUS    |
  SUB L_PAREN expression R_PAREN   {printf("term -> UMINUS L_PAREN expression R_PAREN\n");} %prec UMINUS
  ;

vars:
  var             {printf("vars -> var\n");}  |
  var COMMA vars  {printf("vars -> var COMMA vars\n");}
  ;

var:
  ident                                                 {printf("var -> ident\n");} |
  ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET    {printf("var -> ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
  ;

identifiers:
  ident                     {printf("identifiers -> ident\n");} |
  ident COMMA identifiers   {printf("identifiers -> ident COMMA identifiers\n");}
  ;

ident:
  IDENT { printf("ident -> IDENT %s\n", $1);}
  ;

%% 

int main(int argc, char **argv)
{
   if(argc >= 2) {
      yyin = fopen(argv[1], "r");
      if(yyin == NULL) {
          printf("syntax: %s filename\n", argv[0]);
      }
   }

   yyparse(); // Calls yylex() for tokens.

   return 0;
}

void yyerror(const char *msg) {
  int flag = 0;
  const char* c = msg;
  while(*c) {
    if(*c++ == ':') {
      if(*c == 0) { //colon is the last character
        flag = 1;
        break;
      }
    }
  }
  if(flag) {
    printf("** Line %d, position %d: invalid declaration\n", currLine, currPos);
    return;
  }
  printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}