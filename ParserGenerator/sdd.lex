%{
 #include "y.tab.h"
 #include <stdio.h>
 #include <string.h>
%}

space    [ \t]
digit    [0-9]
alpha    [a-zA-Z]
uline    _
colon    :
lbracket "["
rbracket "]"
lparen   "("
rparen	 ")"
slash    "/"
entry    "e:"
exit     "x:"
arrow    "->"
vbar     "|"
logics   [&^!]
dollar   "$"
period   "."

%%
{entry}						{ return SDD_ENTRY;    }
{exit} 					   	{ return SDD_EXIT;     }
{arrow}					    { return SDD_ARROW;    }
{dollar}					{ return SDD_DOLLAR;   }
{lbracket}					{ return *yytext; } 
{rbracket}					{ return *yytext; } 
{colon}						{ return *yytext; }
{lparen}					{ return *yytext; }
{rparen}					{ return *yytext; }
{slash}						{ return *yytext; }
{vbar}						{ return *yytext; }
{logics}                    { return *yytext; }
{period}					{ return *yytext; }
({alpha}|{uline})({alpha}|{uline}|{digit})*  {
	strcpy(yylval.stval, yytext);
	yylval.stval[yyleng] = '\0';
	return SDD_IDENTIFIER; 
}

{space}+  					{ /* Eat all spaces */ }
.                           { printf("Unkown character %s\n", yytext); }
%%
/*** C Code section ***/

int yywrap(void) {
	return 1;
}