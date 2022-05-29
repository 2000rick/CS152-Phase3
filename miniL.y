/* cs152-miniL phase3 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <sstream>
#include <cstring>
#include "lib.h"
using namespace std;
void yyerror(const char *msg);
extern int currLine;
extern int currPos;
extern int yylex();
FILE* fin;
std::string code = "";
bool mainFlag = false; //program must have a 'main' function
%}

%union {
  int ival;
  char* str;

  struct attr {
    char* code;
    bool isArray;
    char* s_name; //symbol_names? don't know what to call it, need something analogus to .place in lecture
  } attributes;

}

%error-verbose

%start prog_start
%token <str> FUNCTION "function" SEMICOLON ";" BEGIN_PARAMS "beginparams" END_PARAMS "endparams" BEGIN_LOCALS "beginlocals" END_LOCALS "endlocals" BEGIN_BODY "beginbody" END_BODY "endbody"
%token <str> COMMA ","  COLON ":" INTEGER "integer" ARRAY "array" L_SQUARE_BRACKET "[" R_SQUARE_BRACKET "]" OF "of" ENUM "enum" ASSIGN ":=" 
%token <str> IF "if" THEN "then" ELSE "else" ENDIF "endif" FOR "for" WHILE "while" BEGINLOOP "beginloop" ENDLOOP "endloop" DO "do" READ "read" WRITE "write" CONTINUE "continue"
%token <str> OR "or" AND "and" NOT "not" TRUE "true" FALSE "false" EQ "==" NEQ "<>" LT "<" GT ">" LTE "<=" GTE ">=" ADD "+" SUB "-" MULT "*" DIV "/" MOD "%" L_PAREN "(" R_PAREN ")" RETURN "return" ERROR "symbol" EQSIGN "="
%token <ival> NUMBER "nunmber"
%token <str> IDENT "identifier"
%type <attributes> functions function declarations declaration statements statement vars var expressions expression bool_exp relation_and_exp relation_exp comp multiplicative_expression term identifiers ident
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
  functions   {std::cout << code << std::endl;} |
  error '\n'  {yyerrok; yyclearin;}
  ;

functions:
    {
       //functions go to epsilon
       mainFlag = true; //testing purposes (to be removed later)
       if(!mainFlag) {
         cout << "Function 'main' is missing" << endl;
         exit(1);
       }
    } | 
    function functions  {}
    ;

function:
  FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
  {
    stringstream tmp;
    // tmp << "func " << $2.s_name << "\n" << $5.code << $8.code << $11.code << "endfunc\n";
    tmp << "func " << $2.s_name << "\n" << $5.code << $8.code << "endfunc\n";
    code.append(tmp.str().c_str());
  }
  ;

declarations:
    {
      //decs -> epsilon
      $$.code = strdup("");
      $$.s_name = strdup("");
    } | 
    declaration SEMICOLON declarations {
      stringstream tmp;
      tmp << $1.code << $3.code;
      $$.code = strdup(tmp.str().c_str());
      $$.s_name = strdup("");
    }
    ;

declaration:
  identifiers COLON INTEGER                                                     {
    stringstream tmp;   tmp << $1.s_name;
    string st = tmp.str();
    string code_str = "";
    while(st.find(' ') != string::npos) {
      int i = st.find(' ');
      code_str.append(". "+st.substr(0,i)+"\n");
      // cout << ". " << st.substr(0, i) << endl;
      st = st.substr(i+1);
    }
    code_str.append(". "+st+"\n");
    // cout << ". " << st << endl;
    $$.code = strdup(code_str.c_str());
    $$.s_name = strdup("");
  } |
  identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER   {
    string name($1.s_name);
    string code_str = "";
    code_str.append(".[] "+name+", "+to_string($5)+"\n");
    // cout << ".[] " << $1.s_name << ", " << $5 << endl;
    $$.code = strdup(code_str.c_str());
    $$.s_name = strdup("");
  } |
  identifiers COLON ENUM L_PAREN identifiers R_PAREN                            {
    //Implementation not required since not specificed https://cs152-ucr-gupta.github.io/website/mil.html
  }
  ;

statements:
    {} |
    statement SEMICOLON statements  {}
    ;

statement:
  var ASSIGN expression                               {} |
  IF bool_exp THEN statements ENDIF                   {} |
  IF bool_exp THEN statements ELSE statements ENDIF   {} |
  WHILE bool_exp BEGINLOOP statements ENDLOOP         {} |
  DO BEGINLOOP statements ENDLOOP WHILE bool_exp      {} |
  READ vars                                           {} |
  WRITE vars                                          {} |
  CONTINUE                                            {} |
  RETURN expression                                   {}
  ;

bool_exp:
  relation_and_exp                      {} |
  relation_and_exp OR bool_exp          {}
  ;

relation_and_exp:
  relation_exp                        {} |
  relation_exp AND relation_and_exp   {}
  ;

relation_exp:
  expression comp expression      {} |
  TRUE                            {} |
  FALSE                           {} |
  L_PAREN bool_exp R_PAREN        {} |
  NOT expression comp expression  {} |
  NOT TRUE                        {} |
  NOT FALSE                       {} |
  NOT L_PAREN bool_exp R_PAREN    {}
  ;

comp:
  EQ  {} |
  NEQ {} |
  LT  {} |
  GT  {} |
  LTE {} |
  GTE {}
  ;

expressions:
    {} | 
    expression                      {} |
    expression COMMA expressions    {}
    ;

expression:
  multiplicative_expression                  {} |
  multiplicative_expression ADD expression   {} |
  multiplicative_expression SUB expression   {}
  ;

multiplicative_expression:
  term                                     {} |
  term MULT multiplicative_expression      {} |
  term DIV multiplicative_expression       {} |
  term MOD multiplicative_expression       {}
  ;

term:
  ident L_PAREN expressions R_PAREN   {} |
  var                                 {} |
  NUMBER                              {} |
  L_PAREN expression R_PAREN          {} |
  SUB var                          {} %prec UMINUS    |
  SUB NUMBER                       {} %prec UMINUS    |
  SUB L_PAREN expression R_PAREN   {} %prec UMINUS
  ;

vars:
  var             {}  |
  var COMMA vars  {}
  ;

var:
  ident                                                 {} |
  ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET    {}
  ;

identifiers:
  ident                     {
    $$.code = strdup("");
    $$.s_name = strdup($1.s_name);
  } |
  ident COMMA identifiers   {
    $$.code = strdup("");
    stringstream tmp;   //Use stringstream for easy conversion between char*/cstrings and strings
    tmp << $1.s_name << " " << $3.s_name; //the space character in between is a delimiter for different identifiers
    $$.s_name = strdup(tmp.str().c_str());
  }
  ;

ident:
  IDENT {
    /* ISO C++ forbids converting a string constant to ‘char*’, so can't do code=""
    Using (char*) type conversion was also a bad idea (didn't work properly).
    Using strdup seems to work and is probably the best option. */ 
    $$.code = strdup("");
    $$.s_name = strdup($1); 
  }
  ;

%% 

int main(int argc, char **argv)
{
   if(argc >= 2) {
      fin = fopen(argv[1], "r");
      if(fin == NULL) {
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