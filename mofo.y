%{

/* C/C++ skilgreiningar */

#include <math.h>
#include <cstring>
#include <iostream>
#include <cstdio>
#include "AsmCreator.h"

using namespace std;

int yylex();
int yyerror(char *s);

extern FILE *yyin;
extern int line;

bool error = false;

AsmCreator codegen;

#define YYSTYPE string

%}
/* Bison skilgreiningar */

%token NAME
%token OP
%token BINOP7
%token BINOP6
%token BINOP5
%token BINOP4
%token BINOP3
%token BINOP2
%token BINOP1
%token INTEGER
%token DOUBLE
%token STRING
%token CHARACTER

%token COLON
%token COMMA
%token EQUALS

%token PAROPEN
%token PARCLOSE
%token BRACKOPEN
%token BRACKCLOSE
%token CURLOPEN
%token CURLCLOSE

%token KEY_DEF
%token KEY_PASS
%token KEY_IF
%token KEY_ELSE
%token KEY_IN
%token KEY_WHILE
%token KEY_BREAK
%token KEY_CONTINUE
%token KEY_RETURN
%token KEY_AND
%token KEY_OR
%token KEY_TRUE
%token KEY_FALSE
%token KEY_NOT
%token KEY_NULL
%token KEY_ENDMODULE

%token INDENT
%token DEDENT
%token NEWLINE

%token ERROR


%token-table

%%
start
    : program { codegen.endProgram(); } KEY_ENDMODULE newlines
    ;

program
    : newlines functions
    | functions
    ;

functions
    : function functions
    |
    ;

function
    : KEY_DEF NAME PAROPEN { codegen.beginArglist(); } arglist { codegen.beginFunction($2); } PARCLOSE COLON newlines INDENT statements { codegen.endFunction(); } DEDENT
    ;

arglist
    : NAME { codegen.assignArg($1); } arglistcontinue
    |
    ;

arglistcontinue
    : COMMA NAME { codegen.assignArg($2); } arglistcontinue
    |
    ;

/* -------------------------------- */

statements
    : statement statements
    | statement
    ;

statement
    : passstatement
    | varassign
    | ifstatement
    | whileloop
    | breakstatement
    | continuestatement
    | expressions newlines
    | returnstatement
    ;

/* -------------------------------- */

passstatement
    : KEY_PASS newlines
	;

varassign
    : NAME EQUALS expressions newlines { codegen.assignVar($1); }
    ;

ifstatement
    : KEY_IF { codegen.startif(); } expressions COLON newlines INDENT { codegen.statements(); } statements { codegen.endif(); } DEDENT elsestatement
    ;

elsestatement
    : KEY_ELSE { codegen.startelseif(); } expressions COLON newlines INDENT { codegen.statements(); } statements { codegen.endif(); } DEDENT elsestatement
    | KEY_ELSE COLON newlines INDENT { codegen.startelse(); } statements { codegen.endelse(); } DEDENT
    | { codegen.noelse(); }
    ;

whileloop
    : KEY_WHILE { codegen.startwhile(); } expressions COLON newlines INDENT { codegen.whileStatements(); } statements { codegen.endwhile(); } DEDENT
    ;

breakstatement
    : KEY_BREAK { codegen.dobreak(); } newlines
    ;

continuestatement
    : KEY_CONTINUE { codegen.docontinue(); } newlines
    ;

expressions
    : or
    ;

or
	: or { codegen.pushJump(); codegen.jumpTrue(); } KEY_OR and { codegen.popJump(); }
	| and
	;

and
	: and { codegen.pushJump(); codegen.jumpFalse(); } KEY_AND binop1 { codegen.popJump(); }
	| binop1
	;

binop1
	: binop1 { codegen.beginBinop(); } BINOP1 binop2 { codegen.endBinop($3); }
	| binop2
	;

binop2
	: binop3 { codegen.beginBinop(); } BINOP2 binop2 { codegen.endBinop($3); }
	//| binop3 COLON binop2
	| binop3
	;

binop3
	: binop3 { codegen.beginBinop(); } BINOP3 binop4 { codegen.endBinop($3); }
	| binop4
	;

binop4
	: binop4 { codegen.beginBinop(); } BINOP4 binop5 { codegen.endBinop($3); }
	| binop5
	;

binop5
	: binop5 { codegen.beginBinop(); } BINOP5 binop6 { codegen.endBinop($3); }
	| binop6
	;

binop6
	: binop6 { codegen.beginBinop(); } BINOP6 binop7 { codegen.endBinop($3); }
	| binop7
	;

binop7
	: binop7 { codegen.beginBinop(); } BINOP7 expression { codegen.endBinop($3); }
	| expression
	;

expression
	: KEY_NOT { codegen.Not(); } expression
    | PAROPEN expressions PARCLOSE
    | literal { codegen.MakeVal($1); }
    | NAME { codegen.Fetch($1); }
    | functioncall
    ;

functioncall
    : NAME { codegen.beginFunctioncall($1); } PAROPEN parameterlist PARCLOSE { codegen.endFunctioncall(); }
    ;

parameterlist
    : expressions parameterlistrest
    |
    ;

parameterlistrest
    : COMMA expressions parameterlistrest
    |
    ;

returnstatement
    : KEY_RETURN { codegen.Return(); } newlines
    | KEY_RETURN expression { codegen.Return(); } newlines
    ;

newlines
    : newlines NEWLINE
    | NEWLINE
    ;

/* -------------------------------- */

literal
    : INTEGER
    | DOUBLE
    | STRING
    | CHARACTER
    | KEY_TRUE
    | KEY_FALSE
    | KEY_NULL
    ;

%%

// Hjalparstef fyrir bison
int yyerror(char *s)
{
    error = true;
    cerr << "Villa í línu " << line << endl;
    return 0;
}

// Forritið les formúlu af aðalinntaki (stdin), reiknar
// niðurstöðu með bison þáttaranum og skrifar útkomuna á 
// aðalúttak (stdout).
int main( int argc, char **argv ) 
{
    bool flex_output = false;
    char* in_file = 0;
    
    for(int i = 1; i < argc; i++) {
        if(strcmp(argv[i], "-f") == 0)
            flex_output = true;
        else
            in_file = argv[i];
    }
    
    if(in_file == 0) {
        cerr << "Engin skrá skilgreind" << endl;
        return 1;
    }
    
    yyin = fopen(in_file, "r");
    
    if(flex_output) {
        for(int token = yylex(); token; token = yylex())
            cout << line << ": " << yytname[token-255] << "\t\"" << yylval << "\" " << endl;
    } else {
		string in_file_str(in_file);
		
		size_t place = in_file_str.find(".mof");
		if(place != string::npos)
			in_file_str.replace(place, 4, "");
		
		codegen.beginProgram(in_file_str);
        yyparse();
        if(!error)
            cout << codegen.getCode().str() << endl;
    }
    
    return 0;
}
