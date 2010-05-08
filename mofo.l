/*
 *  Beinagrind fyrir lesgreini.
 *
 *  Höfundur: Snorri Agnarsson
 *
 *  Athugið að hér er verið að nota C++ í stað C.
 *  Þessa skrá má þýða t.d. með Cygwin með eftirfarandi skipunum:
 *     flex -omorpholexer.cpp morpho.flex
 *     g++ -o morpholexer.exe morpholexer.cpp -lfl
 */

%{
#include <string>
#include <iostream>
using namespace std;

#define YYSTYPE string
extern YYSTYPE yylval;
#include "mofo.tab.hpp"


int line = 1;
int currIndent = 0;
int lastIndent = 0;
bool stillIndent = true;
int indentTemp = 0;

int lol = 1;

static void copy() {
    char temptext[yyleng+1];
    strncpy(temptext,yytext,yyleng);
    temptext[yyleng] = 0;
    yylval = temptext;
}

static int stopIndent();

#define INDENTS if(indentTemp = stopIndent()) { yyless(0); return indentTemp; }

%}

/* Reglulegar skilgreiningar */

OPCHAR  [!%\-&/=?~^+*:<>|]
ALPHA   [a-zA-ZþæöðáéýúíóÞÆÖÐÁÉÝÚÍÓ]
DIGIT   [0-9]

NAME      {ALPHA}({ALPHA}|{DIGIT}|_)*
BINOP7    [*/%]{OPCHAR}*
BINOP6    [+-]{OPCHAR}*
BINOP5    [<>!=]{OPCHAR}*
BINOP4    &{OPCHAR}*
BINOP3    \|{OPCHAR}*
BINOP2    :{OPCHAR}*
BINOP1    [~\^\?]{OPCHAR}*
INTEGER   {DIGIT}+
DOUBLE    {DIGIT}+\.{DIGIT}+
STRING    \"([^\"\\]|\\b|\\t|\\f|\\r|\\\"|\\\\|(\\[0-3][0-7][0-7])|\\[0-7][0-7]|\\[0-7])*\"
CHARACTER \'([^\'\\]|\\b|\\t|\\n|\\f|\\r|\\\'|\\\\|(\\[0-3][0-7][0-7])|(\\[0-7][0-7])|(\\[0-7]))\'

COLON :
COMMA ,
EQUALS =

PAROPEN \(
PARCLOSE \)
BRACKOPEN \[
BRACKCLOSE \]
CURLOPEN \{
CURLCLOSE \}

KEY_DEF def
KEY_PASS pass
KEY_IF if
KEY_ELSE else
KEY_IN in
KEY_WHILE while
KEY_BREAK break
KEY_CONTINUE continue
KEY_RETURN return
KEY_AND and
KEY_OR or
KEY_TRUE true
KEY_FALSE false
KEY_NOT not
KEY_NULL null
KEY_ENDMODULE endmodule

INDENT \x20\x20\x20\x20
NEWLINE \r|\n|\r\n
WHITESPACE [\ \t\b\012]

%%

  /* JFlex/Flex/Lex reglur -- athugið að hér vantar mikið á til
   * að þetta nálgist að vera lexgreinir fyrir Morpho
   */

{INDENT} {
    currIndent++;
}

{COLON} {
    INDENTS;
    copy();
    return(COLON);
}

{COMMA} {
    INDENTS;
    copy();
    return(COMMA);
}

{EQUALS} {
    INDENTS;
    copy();
    return(EQUALS);
}


{KEY_DEF} {
    INDENTS;
    copy();
    return(KEY_DEF);
}

{KEY_PASS} {
    INDENTS;
    copy();
    return(KEY_PASS);
}

{KEY_IF} {
    INDENTS;
    copy();
    return(KEY_IF);
}

{KEY_ELSE} {
    INDENTS;
    copy();
    return(KEY_ELSE);
}

{KEY_IN} {
    INDENTS;
    copy();
    return(KEY_IN);
}

{KEY_WHILE} {
    INDENTS;
    copy();
    return(KEY_WHILE);
}

{KEY_BREAK} {
    INDENTS;
    copy();
    return(KEY_BREAK);
}

{KEY_CONTINUE} {
    INDENTS;
    copy();
    return(KEY_CONTINUE);
}

{KEY_RETURN} {
    INDENTS;
    copy();
    return(KEY_RETURN);
}

{KEY_AND} {
    INDENTS;
    copy();
    return(KEY_AND);
}

{KEY_OR} {
    INDENTS;
    copy();
    return(KEY_OR);
}

{KEY_TRUE} {
    INDENTS;
    copy();
    return(KEY_TRUE);
}

{KEY_FALSE} {
    INDENTS;
    copy();
    return(KEY_FALSE);
}

{KEY_NOT} {
    INDENTS;
    copy();
    return(KEY_NOT);
}

{KEY_NULL} {
    INDENTS;
    copy();
    return(KEY_NULL);
}

{KEY_ENDMODULE} {
    INDENTS;
    copy();
    return(KEY_ENDMODULE);
}


{NAME} {
    INDENTS;
    copy();
    return(NAME);
}

{BINOP7} {
	INDENTS;
	copy();
	return(BINOP7);
}

{BINOP6} {
	INDENTS;
	copy();
	return(BINOP6);
}

{BINOP5} {
	INDENTS;
	copy();
	return(BINOP5);
}

{BINOP4} {
	INDENTS;
	copy();
	return(BINOP4);
}

{BINOP3} {
	INDENTS;
	copy();
	return(BINOP3);
}

{BINOP2} {
	INDENTS;
	copy();
	return(BINOP2);
}

{BINOP1} {
	INDENTS;
	copy();
	return(BINOP1);
}

{INTEGER} {
    INDENTS;
    copy();
    return(INTEGER);
}

{DOUBLE} {
    INDENTS;
    copy();
    return(DOUBLE);
}

{STRING} {
    INDENTS;
    copy();
    return(STRING);
}

{CHARACTER} {
    INDENTS;
    copy();
    return(CHARACTER);
}


{PAROPEN} {
    INDENTS;
    copy();
    return(PAROPEN);
}

{PARCLOSE} {
    INDENTS;
    copy();
    return(PARCLOSE);
}

{BRACKOPEN} {
    INDENTS;
    copy();
    return(BRACKOPEN);
}

{BRACKCLOSE} {
    INDENTS;
    copy();
    return(BRACKCLOSE);
}

{CURLOPEN} {
    INDENTS;
    copy();
    return(CURLOPEN);
}

{CURLCLOSE} {
    INDENTS;
    copy();
    return(CURLCLOSE);
}


{NEWLINE} {
    //cout << "lol: " << yy_get_next_buffer() << endl;
    
    if(!stillIndent)
        lastIndent = currIndent;
    currIndent = 0;
    stillIndent = true;
    // Ignore newlines, but increment line counter
    line++;
    return(NEWLINE);
}

{WHITESPACE} {
    // Ignore whitespace
}

. {
    INDENTS;
    copy();
    return(ERROR);
}

%%

static int stopIndent() {
    if(YY_CURRENT_BUFFER->yy_buffer_status == 0) {
        yyless(0);
    }
    
    stillIndent = false;
    if(currIndent < lastIndent) {
        --lastIndent;
        return(DEDENT);
    }
    if(lastIndent < currIndent) {
        ++lastIndent;
        return(INDENT);
    }
    return 0;
}