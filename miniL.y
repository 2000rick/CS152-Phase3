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
std::string code = "";  //This will contain all mil code for a program after parsing finishes
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
    string fname($2.s_name);
    if(fname == "main") mainFlag = true;

    string build = ""; string params($5.code);
    int count = 0; int space = 0;
    for(int i=0; i<params.size(); ++i) {
      if(params[i] == ' ') { space = i; }
      if(params[i] == '\n') {
        string s = params.substr(space, i-space);
        build.append("."+s+"\n");
        build.append("="+s+", $"+to_string(count++)+"\n");
      }
    }

    stringstream tmp;
    tmp << "func " << $2.s_name << "\n" << build << $8.code << $11.code << "endfunc\n\n";
    code.append(tmp.str());
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
  identifiers COLON INTEGER {
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
  identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
    string name($1.s_name);
    string code_str = "";
    code_str.append(".[] "+name+", "+to_string($5)+"\n");
    // cout << ".[] " << $1.s_name << ", " << $5 << endl;
    $$.code = strdup(code_str.c_str());
    $$.s_name = strdup("");
  } |
  identifiers COLON ENUM L_PAREN identifiers R_PAREN {
    //Implementation not required since not specificed https://cs152-ucr-gupta.github.io/website/mil.html
  }
  ;

statements:
    {
      //stms -> epsilon
      $$.code = strdup("");
      $$.s_name = strdup("");
    } |
    statement SEMICOLON statements {
      stringstream stream;
      stream << $1.code << $3.code;
      $$.code = strdup(stream.str().c_str());
      $$.s_name = strdup("");
    }
    ;

statement:
  var ASSIGN expression {
    // cout << $1.code << $3.code;
    // cout << "= " << $1.s_name << ", " << $3.s_name << "\n";
    stringstream stream;
    stream << $1.code << $3.code;
    if($1.isArray) {stream << "[]= " << $1.s_name << ", " << $3.s_name << "\n";}
    else {stream << "= " << $1.s_name << ", " << $3.s_name << "\n";} 
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  } |
  IF bool_exp THEN statements ENDIF {
    string lab1 = newlabel();
    string lab2 = newlabel();
    stringstream stream;
    stream << $2.code << "?:= " << lab1 << ", " << $2.s_name << "\n";
    stream << ":= " << lab2 << "\n";
    stream << ": " << lab1 << "\n" << $4.code << ": " << lab2 << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  } |
  IF bool_exp THEN statements ELSE statements ENDIF {
    string lab1 = newlabel();
    string lab2 = newlabel();
    stringstream stream;
    stream << $2.code << "?:= " << lab1 << ", " << $2.s_name << "\n";
    stream << $6.code; //else condition
    stream << ":= " << lab2 << "\n";
    stream << ": " << lab1 << "\n" << $4.code << ": " << lab2 << "\n"; //If condition 
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  } |
  WHILE bool_exp BEGINLOOP statements ENDLOOP {
    string lab1 = newlabel();
    string lab2 = newlabel();
    string lab3 = newlabel();
    stringstream stream;
    string codeblock($4.code);
    while (codeblock.find("continue") != string::npos) {
      unsigned i = codeblock.find("continue");
      codeblock.replace(i, 8, ":= " + lab1); //replace continue with goto label1
    }
    stream << ": " << lab1 << "\n";               //label 1 is here
    stream << $2.code << "?:= " << lab2 << ", " << $2.s_name << "\n";   //If boolexp evaluates to true go to label2
    stream << ":= " << lab3 << "\n";              //If false go to label3, ending the loop
    stream << ": " << lab2 << "\n" << codeblock;  //reaching label2 executes the codeblock
    stream << ":= " << lab1 << "\n";              //go to label 1 (loop)
    stream << ": " << lab3 << "\n";               //label3 is here
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  } |
  DO BEGINLOOP statements ENDLOOP WHILE bool_exp {
    string lab1 = newlabel();
    string lab2 = newlabel();
    stringstream stream;
    string codeblock($3.code);
    while (codeblock.find("continue") != string::npos) {
      unsigned i = codeblock.find("continue");
      codeblock.replace(i, 8, ":= " + lab2); //replace continue with goto label
    }
    stream << ": " << lab1 << "\n" << codeblock;  //label1, will execute codeblock
    stream << ": " << lab2 << "\n";               //for 'continue'
    stream << $6.code << "?:= " << lab1 << ", " << $6.s_name << "\n";             //if boolexp goto label1                             
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  } |
  READ vars {
    string temp($2.code);
    int left = temp.find('$'); //left is index of char '$' (used as delimiter)
    while(left != string::npos) {
      temp.at(left) = '<';
      left = temp.find('$', left); //find next delimieter starting at left
    }
    $$.code = strdup(temp.c_str());
    $$.s_name = strdup("");
  } |
  WRITE vars {
    string temp($2.code);
    int left = temp.find('$'); //left is index of char '$' (used as delimiter)
    while(left != string::npos) {
      temp.at(left) = '>';
      left = temp.find('$', left); //find next delimieter starting at left
    }
    $$.code = strdup(temp.c_str());
    $$.s_name = strdup("");
  } |
  CONTINUE {
    $$.code = strdup("continue\n");
    $$.s_name = strdup("");
  } |
  RETURN expression {
    stringstream stream;
    stream << $2.code << "ret " << $2.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup($2.s_name);
  }
  ;

bool_exp:
  relation_and_exp {
    $$.code = strdup($1.code);
    $$.s_name = strdup($1.s_name);
  } |
  relation_and_exp OR bool_exp {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n";
    stream << "|| " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  }
  ;

relation_and_exp:
  relation_exp {
    $$.code = strdup($1.code);
    $$.s_name = strdup($1.s_name);
  } |
  relation_exp AND relation_and_exp {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n";
    stream << "&& " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  }
  ;

relation_exp:
  expression comp expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << $2.code << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  TRUE {
    string temp("1");
    $$.code = strdup("");
    $$.s_name = strdup(temp.c_str());
  } |
  FALSE {
    string temp("0");
    $$.code = strdup("");
    $$.s_name = strdup(temp.c_str());
  } |
  L_PAREN bool_exp R_PAREN {
    $$.code = strdup($2.code);
    $$.s_name = strdup($2.s_name);
  } |
  NOT expression comp expression {
    string temp = newtemp();
    stringstream stream;
    stream << $2.code << $4.code << ". " << temp << "\n" << $3.code << temp << ", " << $2.s_name << ", " << $4.s_name << "\n";
    stream << "! " << temp << ", " << temp << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  NOT TRUE {
    string temp("0");
    $$.code = strdup("");
    $$.s_name = strdup(temp.c_str());
  } |
  NOT FALSE {
    string temp("1");
    $$.code = strdup("");
    $$.s_name = strdup(temp.c_str());
  } |
  NOT L_PAREN bool_exp R_PAREN {
    stringstream stream;
    stream << $3.code << "! " << $3.s_name << ", " << $3.s_name << "\n";;
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup($3.s_name);
  }
  ;

comp:
  EQ {
    $$.code = strdup("== ");
    $$.s_name = strdup("");
  } |
  NEQ {
    $$.code = strdup("!= ");
    $$.s_name = strdup("");
  } |
  LT {
    $$.code = strdup("< ");
    $$.s_name = strdup("");
  } |
  GT {
    $$.code = strdup("> ");
    $$.s_name = strdup("");
  } |
  LTE {
    $$.code = strdup("<= ");
    $$.s_name = strdup("");
  } |
  GTE {
    $$.code = strdup(">= ");
    $$.s_name = strdup("");
  }
  ;

expressions:
    {
      //exps->epsilon
      $$.code = strdup("");
      $$.s_name = strdup("");
    } | 
    expression {
      /*expressions must come from 'ident L_PAREN expressions R_PAREN'
      so it's the parameters of a function call*/
      stringstream stream;
      stream << $1.code << "param " << $1.s_name << "\n";
      $$.code = strdup(stream.str().c_str());
      $$.s_name = strdup("");
    } |
    expression COMMA expressions {
      stringstream stream;
      stream << $1.code << "param " << $1.s_name << "\n" << $3.code;
      $$.code = strdup(stream.str().c_str());
      $$.s_name = strdup("");
    }
    ;

expression:
  multiplicative_expression {
    $$.code = strdup($1.code);
    $$.s_name = strdup($1.s_name);
  } |
  multiplicative_expression ADD expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << "+ " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  multiplicative_expression SUB expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << "- " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  }
  ;

multiplicative_expression:
  term {
    $$.code = strdup($1.code);
    $$.s_name = strdup($1.s_name);
  } |
  term MULT multiplicative_expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << "* " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  term DIV multiplicative_expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << "/ " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  term MOD multiplicative_expression {
    string temp = newtemp();
    stringstream stream;
    stream << $1.code << $3.code << ". " << temp << "\n" << "% " << temp << ", " << $1.s_name << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  }
  ;

term:
  ident L_PAREN expressions R_PAREN {
    //this must be a function call?
    string temp = newtemp();
    stringstream stream;
    stream << $3.code << ". " << temp << "\ncall " << $1.s_name << ", " << temp << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  var {
    string temp = newtemp();
    stringstream stream;
    if($1.isArray) { stream << $1.code << ". " << temp << "\n=[] " << temp << ", " << $1.s_name << "\n"; }
    else { stream << ". " << temp << "\n= " << temp << ", " << $1.s_name << "\n" << $1.code;}
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  NUMBER {
    string temp = newtemp();
    stringstream stream;
    stream << ". " << temp << "\n= " << temp << ", " << $1 << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } |
  L_PAREN expression R_PAREN {
    $$.code = strdup($2.code);
    $$.s_name = strdup($2.s_name);
  } |
  SUB var {
    string temp = newtemp();
    stringstream stream;
    if($2.isArray) { stream << $2.code << ". " << temp << "\n=[] " << temp << ", " << $2.s_name << "\n"; }
    else { stream << ". " << temp << "\n= " << temp << ", " << $2.s_name << "\n" << $2.code; }
    stream << "- " << temp << ", " << 0 << ", " << temp << "\n"; //-v = 0 - v
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } %prec UMINUS    |
  SUB NUMBER {
    string temp = newtemp();
    stringstream stream;
    stream << ". " << temp << "\n= " << temp << ", -" << $2 << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } %prec UMINUS    |
  SUB L_PAREN expression R_PAREN {
    string temp = newtemp();
    stringstream stream;
    stream << $3.code << ". " << temp << "\n-" << temp << ", " << 0 << ", " << $3.s_name << "\n";
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup(temp.c_str());
  } %prec UMINUS
  ;

vars:
  var {
    stringstream stream;
    if($1.isArray) { stream << $1.code << ".[]$ " << $1.s_name << "\n"; }
    else { stream << ".$ " << $1.s_name << "\n" << $1.code; }
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  }  |
  var COMMA vars {
    stringstream stream;
    if($1.isArray) { stream << $1.code << ".[]$ " << $1.s_name << "\n" << $3.code; }
    else { stream << $1.code << ".$ " << $1.s_name << "\n" << $3.code; }
    $$.code = strdup(stream.str().c_str());
    $$.s_name = strdup("");
  }
  ;

var:
  ident {
    $$.isArray = false;
    $$.code = strdup("");
    $$.s_name = strdup($1.s_name);
  } |
  ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
    $$.isArray = true;
    $$.code = strdup($3.code);
    stringstream temp;
    temp << $1.s_name << ", " << $3.s_name;
    $$.s_name = strdup(temp.str().c_str());
  }
  ;

identifiers:
  ident {
    $$.code = strdup("");
    $$.s_name = strdup($1.s_name);
  } |
  ident COMMA identifiers {
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
