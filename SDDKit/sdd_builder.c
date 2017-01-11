// sdd_builder.c
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

#include "sdd_parser.h"
#include "sdd_builder.h"
#include "sdd_array.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


void sdd_builder_construct(sdd_builder* builder, sdd_markdown markdown, sdd_parser_callback* callback) {
	builder->procedures  = sdd_array_new();
	builder->state_names = sdd_array_new();
	builder->entries     = sdd_array_new();
	builder->exits       = sdd_array_new();
	builder->defaults    = sdd_array_new();
	builder->states      = sdd_array_new();
	builder->clusters    = sdd_array_new();
	builder->buckets     = sdd_array_new();
	builder->ids         = sdd_array_new();
	builder->id_groups   = sdd_array_new();
	builder->stubs 	     = sdd_array_new();
	builder->post_acts   = sdd_array_new();

	builder->markdown    = markdown;
	builder->callback    = callback;
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

void sdd_dump_elements(const char* name, sdd_bool isGroup, sdd_array* elements, sdd_array_element_handler handler) {
	printf("");
	printf(isGroup ? "[*]" : "   ");
	printf("[%d]%s\t", sdd_array_count(elements), name);
	sdd_array_foreach(elements, handler, 0);
	printf("\n");
}

void sdd_dump_builder(sdd_builder* builder, const char* tag) {
	printf ("_______ %s _______\n", tag);
	sdd_dump_elements("states",     sdd_no,  builder->states,     sdd_dump_state_by_names);
	sdd_dump_elements("buckets",    sdd_yes, builder->buckets,    sdd_dump_array_count);
	sdd_dump_elements("clusters",   sdd_yes, builder->clusters,   sdd_dump_array_count);
	sdd_dump_elements("state_names",sdd_no,  builder->state_names,sdd_dump_string);
	sdd_dump_elements("entries",    sdd_no,  builder->entries,    sdd_dump_string);
	sdd_dump_elements("exits",      sdd_no,  builder->exits,      sdd_dump_string);
	sdd_dump_elements("defaults",   sdd_no,  builder->defaults,   sdd_dump_string);
	sdd_dump_elements("stubs",      sdd_no,  builder->stubs,      sdd_dump_string);
	sdd_dump_elements("procedures", sdd_no,  builder->procedures, sdd_dump_string);
	sdd_dump_elements("id_groups",  sdd_yes, builder->id_groups,  sdd_dump_array_count);
	sdd_dump_elements("post_acts",  sdd_no,  builder->post_acts,  sdd_dump_string);
	sdd_dump_elements("ids", 		sdd_no,  builder->ids,        sdd_dump_string);
	printf ("________________________\n");
}

void sdd_builder_destruct(sdd_builder* builder) {
	sdd_array_delete(builder->post_acts);
	sdd_array_delete(builder->ids);
	sdd_array_delete(builder->id_groups);
	sdd_array_delete(builder->procedures);
	sdd_array_delete(builder->state_names);
	sdd_array_delete(builder->entries);
	sdd_array_delete(builder->exits);
	sdd_array_delete(builder->defaults);
	sdd_array_delete(builder->stubs);
	sdd_array_delete(builder->clusters);
	sdd_array_delete(builder->buckets);
	sdd_array_delete(builder->states);
}

void sdd_builder_push_id(sdd_builder* builder, const char* identifier) {
	sdd_array_push(builder->ids, (void*)strdup(identifier));
	(*builder->markdown)("ids", identifier);
}

void sdd_builder_make_id_group(sdd_builder* builder, int gen_new) {
	sdd_array* group;
	if (gen_new) {
		group = sdd_array_new();
		sdd_array_push(builder->id_groups, group);
	} else {
		group = sdd_array_at(builder->id_groups, 0, sdd_no);
	}
	const char* id = sdd_array_pop(builder->ids);
	sdd_array_push(group, (void*)id);

	(*builder->markdown)("id_groups", id);
}

void sdd_builder_make_stub(sdd_builder* builder) {
	const char* stub = sdd_array_pop(builder->ids);
	sdd_array_push(builder->stubs, (void*)stub);

	builder->markdown("stub", stub);
}

void sdd_builder_make_state_name(sdd_builder* builder) {
	const char* identifier = sdd_array_pop(builder->ids);
	sdd_array_push(builder->state_names, (void*)identifier);

	(*builder->markdown)("state_name", identifier);
}

void sdd_builder_array_delete(sdd_array* array) {
	while(sdd_array_count(array)>0) {
		free((void*)sdd_array_pop(array));
	}
	free(array);
}

char* sdd_builder_array_string_new(sdd_array* array) {
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

void sdd_builder_make_procedure(sdd_builder* builder, int empty) {
	if (empty != 0) {
		sdd_array_push(builder->procedures, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(builder->id_groups);
	const char* procedure = sdd_builder_array_string_new(id_group);
	sdd_array_push(builder->procedures, (void*)procedure);
	sdd_builder_array_delete(id_group);

	(*builder->markdown)("procedure", procedure);
}

void sdd_builder_make_entry(sdd_builder* builder, int empty) {
	const char* procs = empty == 0 ? sdd_array_pop(builder->procedures) : strdup("");
	sdd_array_push(builder->entries, (void*)procs);
	(*builder->markdown)("entry", procs);
}

void sdd_builder_make_exit(sdd_builder* builder, int empty) {
	char* procs = empty == 0 ? sdd_array_pop(builder->procedures) : strdup("");
	sdd_array_push(builder->exits, (void*)procs);

	(*builder->markdown)("exit", empty ? "<null>" : procs);
}

void sdd_builder_make_default(sdd_builder* builder, int empty) {
	char* stub = empty == 0 ? sdd_array_pop(builder->stubs) : strdup("");
	sdd_array_push(builder->defaults, (void*)stub);

	(*builder->markdown)("default", empty ? "<null>" : stub);
}

void sdd_builder_make_cluster(sdd_builder* builder, int gen_new) {
	if (gen_new) {
		sdd_array_push(builder->clusters, sdd_array_new());
	}
	sdd_array* clusters = (sdd_array*)sdd_array_at(builder->clusters, 0, sdd_no);
	sdd_state* state = (sdd_state*)sdd_array_pop(builder->states);
	sdd_array_push(clusters, state);
}

void sdd_builder_make_bucket(sdd_builder* builder, int gen_new) {
	sdd_array* bucket;
	if (gen_new) {
		bucket = sdd_array_new();
		sdd_array_push(builder->buckets, bucket);

		// 由于states是FIFO的（例如[S1, S2])，必须将通过“前插”操作，才能保证bucket中状态的顺序
		// 依旧是[S1, S2]。否则，如果使用push，则会变成[S2, S1]。另外，不能使用pop_front从builder->states中获取状态对象。因为栈中很可能还有很多早前被推入的状态。只有最后两个才是属于该bucket的
		sdd_array_push_front(bucket, sdd_array_pop(builder->states));
		sdd_array_push_front(bucket, sdd_array_pop(builder->states));
	} else {
		// peek，不应该pop出来
		bucket = sdd_array_at(builder->buckets, 0, sdd_no);

		sdd_array_push(bucket, sdd_array_pop(builder->states));
	}
}

sdd_state* sdd_builder_extract_state(sdd_builder* builder) {
	const char* name = sdd_array_pop(builder->state_names);
	const char* en   = sdd_array_pop(builder->entries);
	const char* ex   = sdd_array_pop(builder->exits);
	const char* def  = sdd_array_pop(builder->defaults);
	
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

void sdd_builder_make_state(sdd_builder* builder, int mode) {
	sdd_parser_callback* callback = builder->callback;

    sdd_state* state = sdd_builder_extract_state(builder);

    char text[1024];
    sdd_md_make_state_desc(state, text);
    (*builder->markdown)("state", text);

    callback->stateHandler(callback->context, state);

    sprintf(text, "[%-8s ", state->name);
    if (mode == 1) {
	    sdd_array* cluster = sdd_array_pop(builder->clusters);
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
	    (*builder->markdown)("cluster", text);

	    sdd_array_delete(cluster);
    } else if (mode == 2) {
    	sdd_array* bucket = sdd_array_pop(builder->buckets);

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
    	(*builder->markdown)("bucket", text);

    	sdd_array_delete(bucket);
    }

    sdd_array_push(builder->states, (void*)state);
}


void sdd_builder_begin_condition(sdd_builder* builder) {
	builder->postfix_exprs[0] = 0;
}

void sdd_builder_make_expr(sdd_builder* builder, sdd_expr_type type) {
	switch(type) {
		case SDD_EXPR_VAL:
		    if (builder->postfix_exprs[0] != 0) {    // strlen会导致大量计算，而我们只需要判断是否0长度即可
		    	strcat(builder->postfix_exprs, " "); // 只有第一个元素不需要在前面加上用于分隔的空格符
		    }
			strcat(builder->postfix_exprs, sdd_array_at(builder->ids, 0, sdd_no));
			free(sdd_array_pop(builder->ids));
			break;
		case SDD_EXPR_NOT:
			strcat(builder->postfix_exprs, " !");
			break;
		case SDD_EXPR_AND:
			strcat(builder->postfix_exprs, " &");
			break;
		case SDD_EXPR_OR:
			strcat(builder->postfix_exprs, " |");
			break;
		case SDD_EXPR_XOR:
			strcat(builder->postfix_exprs, " ^");
			break;
	}
}

void sdd_builder_end_condition(sdd_builder* builder) {
	(*builder->markdown)("condition", builder->postfix_exprs);
}

void sdd_builder_make_postactions(sdd_builder* builder, int empty) {
	if (empty) {
		sdd_array_push(builder->post_acts, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(builder->id_groups);
	const char* actions = sdd_builder_array_string_new(id_group);
	sdd_array_push(builder->post_acts, (void*)actions);
	sdd_builder_array_delete(id_group);

	(*builder->markdown)("post_acts", actions);
}

void sdd_builder_make_transition(sdd_builder* builder) {
	const char* to        = sdd_array_pop(builder->stubs);
	const char* from      = sdd_array_pop(builder->stubs);
	const char* event     = sdd_array_pop(builder->ids);
	const char* post_acts = sdd_array_pop(builder->post_acts);

	char desc[512];
	if (builder->postfix_exprs[0] == 0) {
		sprintf(desc, "[%s] -> [%s]: %s", from, to, event);
	} else {
		sprintf(desc, "[%s] -> [%s]: %s (%s)", from, to, event, builder->postfix_exprs);
	}

	if (post_acts[0] != 0) {
		strcat(desc, "/");
		strcat(desc, post_acts);
	}
	(*builder->markdown)("trans", desc);

	sdd_transition* transition = sdd_transition_new(from, to, event, builder->postfix_exprs, post_acts);
	(*builder->callback->transitionHandler)(builder->callback->context, transition);
	sdd_transition_delete(transition);

	free((void*)to);
	free((void*)from);
	free((void*)event);
	free((void*)post_acts);
}

void sdd_builder_make_dsl(sdd_builder* builder, int mode) {
	sdd_state* root_state = (sdd_state*)sdd_array_pop(builder->states);
	builder->callback->completionHandler(builder->callback->context, root_state);

	sdd_state_destruct(root_state);
	free((void*)root_state);
}

void yyerror(char *msg) {
	printf("SDD error: %s \n", msg);
}

