// sdd_parser.c
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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "sdd_parser.h"
#include "sdd_builder.h"


void sdd_state_construct(sdd_state* s, const char* name, const char* entries, const char* exits, const char* default_stub) {
    s->name         = strdup(name);
    s->entries      = strdup(entries);
    s->exits        = strdup(exits);
    s->default_stub = strdup(default_stub);
}

void sdd_state_destruct(sdd_state* s) {
    free((void*)s->name);
    free((void*)s->entries);
    free((void*)s->exits);
    free((void*)s->default_stub);
}

sdd_transition* sdd_transition_new(const char* from, const char* to, const char* signal, const char* conditions, const char* actions) {
	sdd_transition* t = malloc(sizeof(sdd_transition));
	t->from       = strdup(from);
	t->to         = strdup(to);
	t->signal     = strdup(signal);
	t->conditions = strdup(conditions);
	t->actions    = strdup(actions);
	return t;
}

void sdd_transition_delete(sdd_transition* t) {
	free((void*)t->actions);
	free((void*)t->conditions);
	free((void*)t->signal);
	free((void*)t->to);
	free((void*)t->from);
	free(t);
}

void sdd_transition_delete(sdd_transition* transition);


typedef struct yy_buffer_state * YY_BUFFER_STATE;
extern int yyparse();
extern YY_BUFFER_STATE yy_scan_string(char * str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
extern void yy_switch_to_buffer(struct yy_buffer_state *);
extern sdd_builder __secret_builder;

void markdown(const char* tag_name, const char* content) {
	static const char* tags[] = {
		// "entry", 
		// "exit",
		// "default",
		// "ids", 
		// "id_groups", 
		// "procedure",
		// "state_actions", 
		// "state_name",
		// "stub",
		// "cluster",
		// "bucket",
		// "state",
		// "condition",
		// "trans",
		// "post_acts",
	};

	int acceptable = 0;
	for (int i=0; i<sizeof(tags)/sizeof(tags[0]); ++i) {
	    acceptable = (acceptable || strcmp(tags[i], tag_name) == 0) ? 1 : 0;
	}

	if (acceptable != 0)
	    printf("<%-12s> %s\n", tag_name, content);
} 


void sdd_parse(const char *dsl, sdd_parser_callback* callback) {
	sdd_builder_construct(&__secret_builder, &markdown, callback);

	YY_BUFFER_STATE dsl_buffer = yy_scan_string((char*)dsl);
	yy_switch_to_buffer( dsl_buffer); // switch flex to the buffer we just created 
	yyparse(); 
	yy_delete_buffer(dsl_buffer);

	// sdd_dump_builder(&__secret_builder, "Status");
	sdd_builder_destruct(&__secret_builder);
}
