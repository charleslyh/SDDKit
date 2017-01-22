// sdd_ast.c
//
// Copyright (c) 2016 CharlesLee
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#include "sdd_ast.h"
#include "sdd_parser.h"
#include "sdd_array.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


void sdd_ast_construct(sdd_ast* ast, sdd_markdown markdown, sdd_parser_callback* callback) {
	ast->procedures  = sdd_array_new();
	ast->state_names = sdd_array_new();
	ast->entries     = sdd_array_new();
	ast->exits       = sdd_array_new();
	ast->defaults    = sdd_array_new();
	ast->states      = sdd_array_new();
	ast->clusters    = sdd_array_new();
	ast->buckets     = sdd_array_new();
	ast->ids         = sdd_array_new();
	ast->id_groups   = sdd_array_new();
	ast->stubs 	     = sdd_array_new();
	ast->post_acts   = sdd_array_new();
	ast->signals     = sdd_array_new();

	ast->markdown    = markdown;
	ast->callback    = callback;
}

void sdd_dump_state_by_names(void* context, void* element) {
	sdd_state* state = (sdd_state*)element;
    printf("[%s]", state->name);
}

void sdd_dump_string(void* context, void* element) {
	printf("%s ", (const char*)element);
}

void sdd_dump_array_count(void* context, void* array) {
	printf("%d ", sdd_array_count((sdd_array*)array));
}

void sdd_dump_signal(void* context, void *element) {
	sdd_signal *sig = (sdd_signal *)element;
	char str[256];
	sdd_describe_signal(sig, str);
	printf("%s\n", str);
}

void sdd_dump_elements(const char* name, sdd_bool isGroup, sdd_array* elements, sdd_array_element_handler handler) {
	printf("");
	printf(isGroup ? "[*]" : "   ");
	printf("[%d]%s\t", sdd_array_count(elements), name);
	sdd_array_foreach(elements, handler, 0);
	printf("\n");
}

void sdd_dump_ast(sdd_ast* ast, const char* tag) {
	printf ("_______ %s _______\n", tag);
	sdd_dump_elements("states",     sdd_no,  ast->states,     sdd_dump_state_by_names);
	sdd_dump_elements("buckets",    sdd_yes, ast->buckets,    sdd_dump_array_count);
	sdd_dump_elements("clusters",   sdd_yes, ast->clusters,   sdd_dump_array_count);
	sdd_dump_elements("state_names",sdd_no,  ast->state_names,sdd_dump_string);
	sdd_dump_elements("entries",    sdd_no,  ast->entries,    sdd_dump_string);
	sdd_dump_elements("exits",      sdd_no,  ast->exits,      sdd_dump_string);
	sdd_dump_elements("signals",    sdd_no,  ast->signals,	  sdd_dump_signal);
	// sdd_dump_elements("defaults",   sdd_no,  ast->defaults,   sdd_dump_string);
	sdd_dump_elements("stubs",      sdd_no,  ast->stubs,      sdd_dump_string);
	sdd_dump_elements("procedures", sdd_no,  ast->procedures, sdd_dump_string);
	sdd_dump_elements("id_groups",  sdd_yes, ast->id_groups,  sdd_dump_array_count);
	sdd_dump_elements("post_acts",  sdd_no,  ast->post_acts,  sdd_dump_string);
	sdd_dump_elements("ids", 		sdd_no,  ast->ids,        sdd_dump_string);
	printf ("________________________\n");
}

void sdd_ast_destruct(sdd_ast* ast) {
	sdd_array_delete(ast->signals);
	sdd_array_delete(ast->post_acts);
	sdd_array_delete(ast->ids);
	sdd_array_delete(ast->id_groups);
	sdd_array_delete(ast->procedures);
	sdd_array_delete(ast->state_names);
	sdd_array_delete(ast->entries);
	sdd_array_delete(ast->exits);
	sdd_array_delete(ast->defaults);
	sdd_array_delete(ast->stubs);
	sdd_array_delete(ast->clusters);
	sdd_array_delete(ast->buckets);
	sdd_array_delete(ast->states);
}

void sdd_ast_push_id(sdd_ast* ast, const char* identifier) {
	sdd_array_push(ast->ids, (void*)strdup(identifier));
	(*ast->markdown)("ids", identifier);
}

void sdd_ast_make_id_group(sdd_ast* ast, int gen_new) {
	sdd_array* group;
	if (gen_new) {
		group = sdd_array_new();
		sdd_array_push(ast->id_groups, group);
	} else {
		group = sdd_array_at(ast->id_groups, 0, sdd_no);
	}
	const char* id = sdd_array_pop(ast->ids);
	sdd_array_push(group, (void*)id);

	(*ast->markdown)("id_groups", id);
}

void sdd_ast_make_stub(sdd_ast* ast) {
	const char* stub = sdd_array_pop(ast->ids);
	sdd_array_push(ast->stubs, (void*)stub);

	ast->markdown("stub", stub);
}

void sdd_ast_make_pseudo_stub(sdd_ast *ast, const char *pseudo) {
	sdd_array_push(ast->stubs, (void*)strdup(pseudo));

	ast->markdown("stub", pseudo);
}

void sdd_ast_make_state_name(sdd_ast* ast) {
	const char* identifier = sdd_array_pop(ast->ids);
	sdd_array_push(ast->state_names, (void*)identifier);

	(*ast->markdown)("state_name", identifier);
}

void sdd_ast_array_delete(sdd_array* array) {
	while(sdd_array_count(array)>0) {
		free((void*)sdd_array_pop(array));
	}
	free(array);
}

char* sdd_ast_array_string_new(sdd_array* array) {
	char buffer[256];
	buffer[0] = 0;
	while(sdd_array_count(array) > 0) {
		const char* elem = sdd_array_pop_front(array);
		strcat(buffer, elem);

		if (sdd_array_count(array) > 0) {
			// Not the very last one
			strcat(buffer, " ");
		}
	}
	return strdup(buffer);
}

void sdd_ast_make_procedure(sdd_ast* ast, int empty) {
	if (empty != 0) {
		sdd_array_push(ast->procedures, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(ast->id_groups);
	const char* procedure = sdd_ast_array_string_new(id_group);
	sdd_array_push(ast->procedures, (void*)procedure);
	sdd_ast_array_delete(id_group);

	(*ast->markdown)("procedure", procedure);
}

void sdd_ast_make_entry(sdd_ast* ast, int empty) {
	const char* procs = empty == 0 ? sdd_array_pop(ast->procedures) : strdup("");
	sdd_array_push(ast->entries, (void*)procs);
	(*ast->markdown)("entry", procs);
}

void sdd_ast_make_exit(sdd_ast* ast, int empty) {
	char* procs = empty == 0 ? sdd_array_pop(ast->procedures) : strdup("");
	sdd_array_push(ast->exits, (void*)procs);

	(*ast->markdown)("exit", empty ? "<null>" : procs);
}

void sdd_ast_make_default(sdd_ast* ast, int empty) {
	char* stub = empty == 0 ? sdd_array_pop(ast->stubs) : strdup("");
	sdd_array_push(ast->defaults, (void*)stub);

	(*ast->markdown)("default", empty ? "<null>" : stub);
}

void sdd_ast_make_cluster(sdd_ast* ast, int gen_new) {
	if (gen_new) {
		sdd_array_push(ast->clusters, sdd_array_new());
	}
	sdd_array* clusters = (sdd_array*)sdd_array_at(ast->clusters, 0, sdd_no);
	sdd_state* state = (sdd_state*)sdd_array_pop(ast->states);
	sdd_array_push(clusters, state);
}

void sdd_ast_make_bucket(sdd_ast* ast, int gen_new) {
	sdd_array* bucket;
	if (gen_new) {
		bucket = sdd_array_new();
		sdd_array_push(ast->buckets, bucket);

		// 由于states是FIFO的（例如[S1, S2])，必须将通过“前插”操作，才能保证bucket中状态的顺序
		// 依旧是[S1, S2]。否则，如果使用push，则会变成[S2, S1]。另外，不能使用pop_front从ast->states中获取状态对象。因为栈中很可能还有很多早前被推入的状态。只有最后两个才是属于该bucket的
		sdd_array_push_front(bucket, sdd_array_pop(ast->states));
		sdd_array_push_front(bucket, sdd_array_pop(ast->states));
	} else {
		// peek，不应该pop出来
		bucket = sdd_array_at(ast->buckets, 0, sdd_no);

		sdd_array_push(bucket, sdd_array_pop(ast->states));
	}
}

sdd_state* sdd_ast_extract_state(sdd_ast* ast) {
	const char* name = sdd_array_pop(ast->state_names);
	const char* en   = sdd_array_pop(ast->entries);
	const char* ex   = sdd_array_pop(ast->exits);
	const char* def  = sdd_array_pop(ast->defaults);
	
	sdd_state* s = malloc(sizeof(sdd_state));
	sdd_state_construct(s, name, en, ex, def);

	free((void*)name);
	free((void*)en);
	free((void*)ex);
	free((void*)def);

	return s;
}

void sdd_md_make_state_desc(sdd_state* state, char* desc) {
	sprintf(desc, "[%s", state->name);

	if (strlen(state->entries) != 0) {
		strcat(desc, " e:");
		strcat(desc, state->entries);
	}

	if (strlen(state->exits) != 0) {
		strcat(desc, " x:");
		strcat(desc, state->exits);
	}

	if (strlen(state->default_stub) != 0) {
		strcat(desc, " d:[");
		strcat(desc, state->default_stub);
		strcat(desc, "]");
	}

	strcat(desc, "]");
}

void sdd_ast_make_state(sdd_ast* ast, int mode) {
	sdd_parser_callback* callback = ast->callback;

    sdd_state* state = sdd_ast_extract_state(ast);

    char text[1024];
    sdd_md_make_state_desc(state, text);
    (*ast->markdown)("state", text);

    callback->stateHandler(callback->context, state);

    sprintf(text, "[%-8s ", state->name);
    if (mode == 1) {
	    sdd_array* cluster = sdd_array_pop(ast->clusters);
	    callback->clusterHandler(callback->context, state, cluster);

	    while(sdd_array_count(cluster) > 0) {
	        sdd_state* cluster_state = sdd_array_pop_front(cluster);
	        strcat(text, "[");
	        strcat(text, cluster_state->name);
	        strcat(text, "]");
	        sdd_state_destruct(cluster_state);
	        free((void*)cluster_state);
	    }
	    strcat(text, "]");
	    (*ast->markdown)("cluster", text);

	    sdd_array_delete(cluster);
    } else if (mode == 2) {
    	sdd_array* bucket = sdd_array_pop(ast->buckets);

    	while(sdd_array_count(bucket) > 0) {
    		sdd_state* bucket_state = sdd_array_pop_front(bucket);
	        strcat(text, "[");
	        strcat(text, bucket_state->name);

	        if (sdd_array_count(bucket)!=0)
	        	strcat(text, "]|");
	        else
	        	strcat(text, "]");
	        sdd_state_destruct(bucket_state);
	        free((void*)bucket_state);
    	}
    	strcat(text, "]");
    	(*ast->markdown)("bucket", text);

    	sdd_array_delete(bucket);
    }

    sdd_array_push(ast->states, (void*)state);
}


void sdd_ast_begin_condition(sdd_ast* ast) {
	ast->postfix_exprs[0] = 0;
}

void sdd_ast_make_expr(sdd_ast* ast, sdd_expr_type type) {
	switch(type) {
		case SDD_EXPR_VAL:
		    if (ast->postfix_exprs[0] != 0) {    // strlen会导致大量计算，而我们只需要判断是否0长度即可
		    	strcat(ast->postfix_exprs, " "); // 只有第一个元素不需要在前面加上用于分隔的空格符
		    }
			strcat(ast->postfix_exprs, sdd_array_at(ast->ids, 0, sdd_no));
			free(sdd_array_pop(ast->ids));
			break;
		case SDD_EXPR_NOT:
			strcat(ast->postfix_exprs, " !");
			break;
		case SDD_EXPR_AND:
			strcat(ast->postfix_exprs, " &");
			break;
		case SDD_EXPR_OR:
			strcat(ast->postfix_exprs, " |");
			break;
		case SDD_EXPR_XOR:
			strcat(ast->postfix_exprs, " ^");
			break;
	}
}

void sdd_ast_end_condition(sdd_ast* ast) {
	(*ast->markdown)("condition", ast->postfix_exprs);
}

void sdd_ast_make_postactions(sdd_ast* ast, int empty) {
	if (empty) {
		sdd_array_push(ast->post_acts, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(ast->id_groups);
	const char* actions = sdd_ast_array_string_new(id_group);
	sdd_array_push(ast->post_acts, (void*)actions);
	sdd_ast_array_delete(id_group);

	(*ast->markdown)("post_acts", actions);
}

void sdd_ast_make_transition(sdd_ast* ast) {
	sdd_signal *sig       = sdd_array_pop(ast->signals);
	const char* to        = sdd_array_pop(ast->stubs);
	const char* from      = sdd_array_pop(ast->stubs);
	const char* post_acts = sdd_array_pop(ast->post_acts);

	char sig_desc[512];
	sdd_describe_signal(sig, sig_desc);

	char desc[512];
	if (ast->postfix_exprs[0] == 0) {
		sprintf(desc, "[%s] -> [%s]: %s", from, to, sig_desc);
	} else {
		sprintf(desc, "[%s] -> [%s]: %s (%s)", from, to, sig_desc, ast->postfix_exprs);
	}

	if (post_acts[0] != 0) {
		strcat(desc, "/");
		strcat(desc, post_acts);
	}
	(*ast->markdown)("trans", desc);

	sdd_transition* transition = sdd_transition_new(from, to, sig, ast->postfix_exprs, post_acts);
	(*ast->callback->transitionHandler)(ast->callback->context, transition);
	sdd_transition_delete(transition);

	free((void*)to);
	free((void*)from);
	free((void*)post_acts);
	sdd_signal_delete(sig);
}

void sdd_ast_make_signal(sdd_ast *ast, sdd_signal_type type) {
	const char *name = sdd_array_pop(ast->ids);
	sdd_signal *sig = sdd_signal_new(type, name);
	free((void *)name);

	sdd_array_push(ast->signals, sig);
}

void sdd_ast_make_top_state(sdd_ast *ast) {
	sdd_state* topstate = (sdd_state*)sdd_array_pop(ast->states);
	ast->callback->topstateHandler(ast->callback->context, topstate);

	sdd_state_destruct(topstate);
	free((void*)topstate);
}

void sdd_ast_make_dsl(sdd_ast* ast, int mode) {
	ast->callback->completionHandler(ast->callback->context);
}

void yyerror(char *msg) {
	printf("SDD error: %s \n", msg);
}

