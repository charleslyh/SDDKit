#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "sdd_parser.h"
#include "sdd_builder.h"
#include "sdd_array.h"


void SDDBuilderInit(SDDBuilder* builder, SDDMarkdownFn markdown, sdd_parser_callback* callback) {
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

void SDDDumpStateByNames(void* context, void* element) {
	sdd_state* state = (sdd_state*)element;
    printf("[%s]", state->name);
}

void SDDDumpString(void* context, void* element) {
	printf("%s ", (const char*)element);
}

void SDDDumpArrayCount(void* context, void* array) {
	printf("%d ", sdd_array_count((sdd_array*)array));
}

void SDDDumpElements(const char* name, sdd_bool isGroup, sdd_array* elements, sdd_array_element_handler handler) {
	printf("");
	printf(isGroup ? "[*]" : "   ");
	printf("[%d]%s\t", sdd_array_count(elements), name);
	sdd_array_foreach(elements, handler, 0);
	printf("\n");
}

void SDDDumpParser(SDDBuilder* builder, const char* tag) {
	printf ("_______ %s _______\n", tag);
	SDDDumpElements("states",     sdd_no,  builder->states,     SDDDumpStateByNames);
	SDDDumpElements("buckets",    sdd_yes, builder->buckets,    SDDDumpArrayCount);
	SDDDumpElements("clusters",   sdd_yes, builder->clusters,   SDDDumpArrayCount);
	SDDDumpElements("state_names",sdd_no,  builder->state_names,SDDDumpString);
	SDDDumpElements("entries",    sdd_no,  builder->entries,    SDDDumpString);
	SDDDumpElements("exits",      sdd_no,  builder->exits,      SDDDumpString);
	SDDDumpElements("defaults",   sdd_no,  builder->defaults,   SDDDumpString);
	SDDDumpElements("stubs",	  sdd_no,  builder->stubs,      SDDDumpString);
	SDDDumpElements("procedures", sdd_no,  builder->procedures, SDDDumpString);
	SDDDumpElements("id_groups",  sdd_yes, builder->id_groups,  SDDDumpArrayCount);
	SDDDumpElements("post_acts",  sdd_no,  builder->post_acts,  SDDDumpString);
	SDDDumpElements("ids", 		  sdd_no,  builder->ids,        SDDDumpString);
	printf ("________________________\n");
}

void SDDBuilderDestroy(SDDBuilder* builder) {
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

void SDDBuilderPushIdentifier(SDDBuilder* builder, const char* identifier) {
	sdd_array_push(builder->ids, (void*)strdup(identifier));
	(*builder->markdown)("ids", identifier);
}

void SDDBuilderMakeIDGroup(SDDBuilder* builder, int gen_new) {
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

void SDDBuilderMakeStub(SDDBuilder* builder) {
	const char* stub = sdd_array_pop(builder->ids);
	sdd_array_push(builder->stubs, (void*)stub);

	builder->markdown("stub", stub);
}

void SDDBuilderMakeStateName(SDDBuilder* builder) {
	const char* identifier = sdd_array_pop(builder->ids);
	sdd_array_push(builder->state_names, (void*)identifier);

	(*builder->markdown)("state_name", identifier);
}

void SDDBuilderDeleteArray(sdd_array* array) {
	while(sdd_array_count(array)>0) {
		free((void*)sdd_array_pop(array));
	}
	free(array);
}

char* SDDBuilderGenerateArrayString(sdd_array* array) {
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

void SDDBuilderMakeProcedure(SDDBuilder* builder, int empty) {
	if (empty != 0) {
		sdd_array_push(builder->procedures, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(builder->id_groups);
	const char* procedure = SDDBuilderGenerateArrayString(id_group);
	sdd_array_push(builder->procedures, (void*)procedure);
	SDDBuilderDeleteArray(id_group);

	(*builder->markdown)("procedure", procedure);
}

void SDDBuilderMakeEntry(SDDBuilder* builder, int empty) {
	const char* procs = empty == 0 ? sdd_array_pop(builder->procedures) : strdup("");
	sdd_array_push(builder->entries, (void*)procs);
	(*builder->markdown)("entry", procs);
}

void SDDBuilderMakeExit(SDDBuilder* builder, int empty) {
	char* procs = empty == 0 ? sdd_array_pop(builder->procedures) : strdup("");
	sdd_array_push(builder->exits, (void*)procs);

	(*builder->markdown)("exit", empty ? "<null>" : procs);
}

void SDDBuilderMakeDefault(SDDBuilder* builder, int empty) {
	char* stub = empty == 0 ? sdd_array_pop(builder->stubs) : strdup("");
	sdd_array_push(builder->defaults, (void*)stub);

	(*builder->markdown)("default", empty ? "<null>" : stub);
}

void SDDBuilderMakeCluster(SDDBuilder* builder, int gen_new) {
	if (gen_new) {
		sdd_array_push(builder->clusters, sdd_array_new());
	}
	sdd_array* clusters = (sdd_array*)sdd_array_at(builder->clusters, 0, sdd_no);
	sdd_state* state = (sdd_state*)sdd_array_pop(builder->states);
	sdd_array_push(clusters, state);
}

void SDDBuilderMakeBucket(SDDBuilder* builder, int gen_new) {
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

sdd_state* SDDBuilderExtractState(SDDBuilder* builder) {
	const char* name = sdd_array_pop(builder->state_names);
	const char* en   = sdd_array_pop(builder->entries);
	const char* ex   = sdd_array_pop(builder->exits);
	const char* def  = sdd_array_pop(builder->defaults);
	
	sdd_state* s = malloc(sizeof(sdd_state));
	sdd_state_init(s, name, en, ex, def);

	free((void*)name);
	free((void*)en);
	free((void*)ex);
	free((void*)def);

	return s;
}

void sdd_stateMakeDescription(sdd_state* state, char* desc) {
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

void SDDBuilderMakeState(SDDBuilder* builder, int mode) {
	sdd_parser_callback* callback = builder->callback;

    sdd_state* state = SDDBuilderExtractState(builder);

    char text[1024];
    sdd_stateMakeDescription(state, text);
    (*builder->markdown)("state", text);

    callback->stateHandler(callback->context, state);

    const char* type;
    sprintf(text, "[%-8s ", state->name);
    if (mode == 1) {
	    sdd_array* cluster = sdd_array_pop(builder->clusters);
	    callback->clusterHandler(callback->context, state, cluster);

	    while(sdd_array_count(cluster) > 0) {
	        sdd_state* cluster_state = sdd_array_pop_front(cluster);
	        strcat(text, "[");
	        strcat(text, cluster_state->name);
	        strcat(text, "]");
	        sdd_state_release(cluster_state);
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
	        sdd_state_release(bucket_state);
	        free((void*)bucket_state);
    	}
    	strcat(text, "]");
    	(*builder->markdown)("bucket", text);

    	sdd_array_delete(bucket);
    }

    sdd_array_push(builder->states, (void*)state);
}


void SDDBuilderBeginCondition(SDDBuilder* builder) {
	builder->postfix_exprs[0] = 0;
}

void SDDBuilderMakeExpr(SDDBuilder* builder, sdd_expr_type type) {
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

void SDDBuilderEndCondition(SDDBuilder* builder) {
	(*builder->markdown)("condition", builder->postfix_exprs);
}

void SDDBuilderMakePostActions(SDDBuilder* builder, int empty) {
	if (empty) {
		sdd_array_push(builder->post_acts, strdup(""));
		return;
	}

	sdd_array* id_group = sdd_array_pop(builder->id_groups);
	const char* actions = SDDBuilderGenerateArrayString(id_group);
	sdd_array_push(builder->post_acts, (void*)actions);
	SDDBuilderDeleteArray(id_group);

	(*builder->markdown)("post_acts", actions);
}

void SDDBuilderMakeTransition(SDDBuilder* builder) {
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

void SDDBuilderMakeDSL(SDDBuilder* builder, int mode) {
	sdd_state* root_state = (sdd_state*)sdd_array_pop(builder->states);
	builder->callback->completionHandler(builder->callback->context, root_state);

	sdd_state_release(root_state);
	free((void*)root_state);
}

void yyerror(char *msg) {
	printf("SDD error: %s \n", msg);
}

