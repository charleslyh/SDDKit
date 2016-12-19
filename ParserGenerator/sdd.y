%{
 #include <stdio.h>
 #include <string.h>
 #include <stdlib.h>
 #include "sdd_builder.h"

 void yyerror(char*);
 int yylex();

 SDDBuilder __secret_builder;
%}

%token SDD_IDENTIFIER SDD_ENTRY SDD_EXIT SDD_DEFAULT SDD_ARROW

%union {
    char stval[256];
}

%type<stval> id SDD_IDENTIFIER bool_expr
%left  '|' '&' '^'
%right '!'
%% 


sdd_dsl
    : state                     { SDDBuilderMakeDSL(&__secret_builder, 0); }
    | state transitions         { SDDBuilderMakeDSL(&__secret_builder, 1); }
    ;

transitions
    : transition
    | transitions transition
    ;

transition
    : state_stub SDD_ARROW state_stub ':' id conditions post_actions {
            SDDBuilderMakeTransition(&__secret_builder);
        }
    ;

post_actions
    : /* empty */             { SDDBuilderMakePostActions(&__secret_builder, 1); }
    | beg_trans_act id_group  { SDDBuilderMakePostActions(&__secret_builder, 0); }
    ;

beg_trans_act
    : '/'           {}
    ;

conditions
    : /* empty */                              { 
                                                    SDDBuilderBeginCondition(&__secret_builder);
                                                    SDDBuilderEndCondition(&__secret_builder);
                                                }
    | beg_condition bool_expr end_condition    {}
    ;

beg_condition
    : '('                         { SDDBuilderBeginCondition(&__secret_builder); }
    ;

end_condition
    : ')'                         { SDDBuilderEndCondition(&__secret_builder); }
    ;

bool_expr
    : id                          { SDDBuilderMakeExpr(&__secret_builder, SDD_EXPR_VAL); }
    | '(' bool_expr ')'           { }
    | bool_expr '|' bool_expr     { SDDBuilderMakeExpr(&__secret_builder, SDD_EXPR_OR ); }
    | bool_expr '&' bool_expr     { SDDBuilderMakeExpr(&__secret_builder, SDD_EXPR_AND); }
    | bool_expr '^' bool_expr     { SDDBuilderMakeExpr(&__secret_builder, SDD_EXPR_XOR); }
    | '!' bool_expr               { SDDBuilderMakeExpr(&__secret_builder, SDD_EXPR_NOT); }
    ;

bucket
    : state '|' state       { SDDBuilderMakeBucket(&__secret_builder, 1); }
    | bucket '|' state      { SDDBuilderMakeBucket(&__secret_builder, 0); }
    ;

cluster
    : state                 { SDDBuilderMakeCluster(&__secret_builder, 1); }
    | cluster state         { SDDBuilderMakeCluster(&__secret_builder, 0); }
    ;

state
    : '[' state_name state_actions ']'           { SDDBuilderMakeState(&__secret_builder, 0); }
    | '[' state_name state_actions cluster ']'   { SDDBuilderMakeState(&__secret_builder, 1); }
    | '[' state_name state_actions bucket ']'    { SDDBuilderMakeState(&__secret_builder, 2); }
    ;

state_name
    : id                            { SDDBuilderMakeStateName(&__secret_builder); }
    ;

state_actions
    : entry exit default            {}
    ;

default
    : /* empty */                   { SDDBuilderMakeDefault(&__secret_builder, 1); }
    | '~' state_stub                { SDDBuilderMakeDefault(&__secret_builder, 0); }
    ;

entry
    : /* empty */                   { SDDBuilderMakeEntry(&__secret_builder, 1);    }
    | SDD_ENTRY procedures          { SDDBuilderMakeEntry(&__secret_builder, 0);    }
    ;

exit
    : /* empty */                   { SDDBuilderMakeExit(&__secret_builder, 1);     }
    | SDD_EXIT  procedures          { SDDBuilderMakeExit(&__secret_builder, 0);     }
    ;

state_stub
    : '[' id ']'                    { SDDBuilderMakeStub(&__secret_builder); }
    ;

procedures
    : id_group                      {   SDDBuilderMakeProcedure(&__secret_builder, 0); }
    ;

id_group 
    : id                            {   SDDBuilderMakeIDGroup(&__secret_builder, 1);   }
    | id_group id                   {   SDDBuilderMakeIDGroup(&__secret_builder, 0);   }
    ;

id
    : SDD_IDENTIFIER                {   SDDBuilderPushIdentifier(&__secret_builder, $1);   }
    ;
%%
