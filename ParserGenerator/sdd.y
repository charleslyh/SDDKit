%{
 #include <stdio.h>
 #include <string.h>
 #include <stdlib.h>
 #include "sdd_ast.h"
 #include "sdd_parser.h"

 void yyerror(char*);
 int yylex();

 sdd_ast __ast;
%}

%token SDD_IDENTIFIER SDD_ENTRY SDD_EXIT SDD_DEFAULT SDD_ARROW SDD_DOLLAR

%union {
    char stval[256];
}

%type<stval> id SDD_IDENTIFIER bool_expr
%left  '|' '&' '^'
%right '!'
%% 


sdd_dsl
    : state                     { sdd_ast_make_dsl(&__ast, 0); }
    | state transitions         { sdd_ast_make_dsl(&__ast, 1); }
    ;

transitions
    : transition
    | transitions transition
    ;

transition
    : state_stub SDD_ARROW state_stub ':' signal conditions post_actions {
            sdd_ast_make_transition(&__ast);
        }
    ;

signal
    : id                      { sdd_ast_make_signal(&__ast, SDD_SIG_USER);     }
    | SDD_DOLLAR id           { sdd_ast_make_signal(&__ast, SDD_SIG_INTERNAL); }
    ;

post_actions
    : /* empty */             { sdd_ast_make_postactions(&__ast, 1); }
    | beg_trans_act id_group  { sdd_ast_make_postactions(&__ast, 0); }
    ;

beg_trans_act
    : '/'           {}
    ;

conditions
    : /* empty */                              { 
                                                    sdd_ast_begin_condition(&__ast);
                                                    sdd_ast_end_condition(&__ast);
                                                }
    | beg_condition bool_expr end_condition    {}
    ;

beg_condition
    : '('                         { sdd_ast_begin_condition(&__ast); }
    ;

end_condition
    : ')'                         { sdd_ast_end_condition(&__ast); }
    ;

bool_expr
    : id                          { sdd_ast_make_expr(&__ast, SDD_EXPR_VAL); }
    | '(' bool_expr ')'           { }
    | bool_expr '|' bool_expr     { sdd_ast_make_expr(&__ast, SDD_EXPR_OR ); }
    | bool_expr '&' bool_expr     { sdd_ast_make_expr(&__ast, SDD_EXPR_AND); }
    | bool_expr '^' bool_expr     { sdd_ast_make_expr(&__ast, SDD_EXPR_XOR); }
    | '!' bool_expr               { sdd_ast_make_expr(&__ast, SDD_EXPR_NOT); }
    ;

bucket
    : state '|' state       { sdd_ast_make_bucket(&__ast, 1); }
    | bucket '|' state      { sdd_ast_make_bucket(&__ast, 0); }
    ;

cluster
    : state                 { sdd_ast_make_cluster(&__ast, 1); }
    | cluster state         { sdd_ast_make_cluster(&__ast, 0); }
    ;

state
    : '[' state_name state_actions ']'           { sdd_ast_make_state(&__ast, 0); }
    | '[' state_name state_actions cluster ']'   { sdd_ast_make_state(&__ast, 1); }
    | '[' state_name state_actions bucket ']'    { sdd_ast_make_state(&__ast, 2); }
    ;

state_name
    : id                            { sdd_ast_make_state_name(&__ast); }
    ;

state_actions
    : entry exit default            {}
    ;

default
    : /* empty */                   { sdd_ast_make_default(&__ast, 1); }
    | '~' state_stub                { sdd_ast_make_default(&__ast, 0); }
    ;

entry
    : /* empty */                   { sdd_ast_make_entry(&__ast, 1);    }
    | SDD_ENTRY procedures          { sdd_ast_make_entry(&__ast, 0);    }
    ;

exit
    : /* empty */                   { sdd_ast_make_exit(&__ast, 1);     }
    | SDD_EXIT  procedures          { sdd_ast_make_exit(&__ast, 0);     }
    ;

state_stub
    : '[' id ']'                    { sdd_ast_make_stub(&__ast); }
    ;

procedures
    : id_group                      { sdd_ast_make_procedure(&__ast, 0); }
    ;

id_group 
    : id                            { sdd_ast_make_id_group(&__ast, 1);   }
    | id_group id                   { sdd_ast_make_id_group(&__ast, 0);   }
    ;

id
    : SDD_IDENTIFIER                { sdd_ast_push_id(&__ast, $1);   }
    ;
%%
