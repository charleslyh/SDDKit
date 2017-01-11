// sdd_builder.h
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

#ifndef SDD_BUILDER_H
#define SDD_BUILDER_H

typedef void (*sdd_markdown)(const char*, const char*);
typedef struct sdd_array_t sdd_array;
typedef struct sdd_parser_callback sdd_parser_callback;

struct sdd_builder_t {
	sdd_array* states;
	sdd_array* state_names;
	sdd_array* entries;
	sdd_array* exits;
	sdd_array* defaults;
	sdd_array* procedures;
	sdd_array* clusters;
	sdd_array* buckets;
	sdd_array* stubs;
	sdd_array* ids;
	sdd_array* id_groups;
	sdd_array* post_acts;
	char postfix_exprs[4096];

	sdd_markdown markdown;
	sdd_parser_callback* callback;
};

typedef struct sdd_builder_t sdd_builder;

void sdd_builder_construct(sdd_builder* builder, sdd_markdown markdown, sdd_parser_callback* callback);
void sdd_builder_destruct(sdd_builder* builder);
void sdd_builder_push_id(sdd_builder* builder, const char* identifier);
void sdd_builder_make_stub(sdd_builder* builder);
void sdd_builder_make_id_group(sdd_builder* builder, int gen_new);
void sdd_builder_make_state_name(sdd_builder* builder);
void sdd_builder_make_procedure(sdd_builder* builder, int empty);
void sdd_builder_make_entry(sdd_builder* builder, int empty);
void sdd_builder_make_exit(sdd_builder* builder,  int empty);
void sdd_builder_make_default(sdd_builder* builder, int empty);
void sdd_builder_make_cluster(sdd_builder* builder, int gen_new);
void sdd_builder_make_bucket(sdd_builder* builder, int gen_new);

// mode: 0 - single, 1 - with cluster, 2 - with bucket
void sdd_builder_make_state(sdd_builder* builder, int mode);

typedef enum sdd_expr_type {
	SDD_EXPR_VAL,
	SDD_EXPR_NOT,
	SDD_EXPR_AND,
	SDD_EXPR_OR,
	SDD_EXPR_XOR,
} sdd_expr_type;

void sdd_builder_begin_condition(sdd_builder* builder);
void sdd_builder_make_expr(sdd_builder* builder, sdd_expr_type type);
void sdd_builder_end_condition(sdd_builder* builder);
void sdd_builder_make_postactions(sdd_builder* builder, int empty);

void sdd_builder_make_transition(sdd_builder* builder);

// mode: 0 - no transitions, 1- with transitions
void sdd_builder_make_dsl(sdd_builder* builder, int mode);

void sdd_dump_builder(sdd_builder* builder, const char* tag);

#endif  // SDD_BUILDER_H
