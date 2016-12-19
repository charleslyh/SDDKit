%{
 #include "y.tab.h"
 #include <stdio.h>
 #include <string.h>
%}

lbracket \[
rbracket \]
lparen   \(
rparen	 \)
uline    _
digit    [0-9]
alpha    [a-zA-Z]
colon    :
space    [ \t]
tilde    "~"
slash    "/"
comma    ","
ocmark   "@"
entry    "e:"
exit     "x:"
default  "d:"
arrow    "->"
vbar     "|"
logics   [&^!]

%%
{entry}						{ return SDD_ENTRY;    }
{exit} 					   	{ return SDD_EXIT;     }
{default}					{ return SDD_DEFAULT;  }
{lbracket}					{ return *yytext;  } 
{rbracket}					{ return *yytext;  } 
{colon}						{ return *yytext;  }
{tilde}						{ return *yytext;  }
{lparen}					{ return *yytext;  }
{rparen}					{ return *yytext;  }
{arrow}					    { return SDD_ARROW;    }
{slash}						{ return *yytext;  }
{comma}						{ return *yytext;  }
{vbar}						{ return *yytext;  }
{logics}                    { return *yytext;  }
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