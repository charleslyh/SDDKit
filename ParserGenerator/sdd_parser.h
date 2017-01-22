// sdd_parser.h
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

#ifndef SDD_PARSER_H
#define SDD_PARSER_H


typedef enum sdd_signal_type {
	SDD_SIG_INTERNAL	= 1,
	SDD_SIG_USER 		= 2,
} sdd_signal_type;

typedef struct sdd_signal_t {
	sdd_signal_type type;
	char            *name;
} sdd_signal;

sdd_signal *sdd_signal_new(sdd_signal_type type, const char *name);
sdd_signal *sdd_signal_copy(sdd_signal *sig);
void sdd_signal_delete(sdd_signal *sig);
void sdd_describe_signal(sdd_signal *sig, char str[]);

typedef struct sdd_state_t {
	const char* name;
	const char* entries;
	const char* exits;
	const char* default_stub;
} sdd_state;

void sdd_state_construct(sdd_state* state, const char* name, const char* entries, const char* exits, const char* default_stub);
void sdd_state_destruct(sdd_state* state);


typedef struct sdd_transition_t {
	sdd_signal *signal;
	const char* from;
	const char* to;
	const char* conditions;
	const char* actions;
} sdd_transition;

sdd_transition* sdd_transition_new(const char* from, const char* to, sdd_signal* signal, const char* conditions, const char* actions);
void sdd_transition_delete(sdd_transition* transition);


typedef struct sdd_array_t sdd_array;
typedef void (*sdd_parser_state_handler)(void* context, sdd_state* state);
typedef void (*sdd_parser_cluster_handler)(void* context, sdd_state* holder, sdd_array* states);
typedef void (*sdd_parser_transition_handler)(void* context, sdd_transition* transition);
typedef void (*sdd_parser_topstate_handler)(void* context, sdd_state* top_state);
typedef void (*sdd_parser_completion_handler)(void* context);

typedef struct sdd_parser_callback {
	void* context;
	sdd_parser_state_handler      stateHandler;
	sdd_parser_cluster_handler    clusterHandler;
	sdd_parser_transition_handler transitionHandler;
	sdd_parser_topstate_handler   topstateHandler;
	sdd_parser_completion_handler completionHandler;
} sdd_parser_callback;

// 为了让DSL的定义更方便，这里使用了一个将括号内内容直接转成字符串的宏。这样就可以定义跨行（但是不包括换行符）的DSL内容了。例如：
// const char* dsl = sdd_dsl
// (
//    [A e:entry x:exit]
// );
#define sdd_dsl(text) #text

void sdd_parse(const char* dsl, sdd_parser_callback* callback);

#endif // SDD_PARSER_H
