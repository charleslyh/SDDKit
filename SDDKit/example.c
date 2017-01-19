#include <stdio.h>
#include <string.h>
#include "sdd_parser.h"
#include "sdd_array.h"

void EXPMakeStateDescription(sdd_state* state, char* desc) {
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

#define COLOR_NONE        "\033[0m"
#define FONT_CLR_BLACK    "\033[;30m"
#define FONT_CLR_RED      "\033[;31m"
#define FONT_CLR_GREEN    "\033[;32m"
#define FONT_CLR_YELLOW   "\033[;33m"
#define FONT_CLR_BLUE     "\033[;34m"
#define FONT_CLR_MAGENTA  "\033[;35m"
#define FONT_CLR_CYAN     "\033[;36m"
#define FONT_CLR_WHITE    "\033[;37m"

void EXPMarkTag(const char* tag, const char* text, const char* color) {
	if (color == 0)
		color = "";
	printf("[%10s]: %s%s\n" COLOR_NONE, tag, color, text);	
}

void EXPMarkdownState(void* context, sdd_state* state) {
	char desc[1024];
	EXPMakeStateDescription(state, desc);
	EXPMarkTag("state", desc, FONT_CLR_BLUE);
}

void EXPMarkdownCluster(void* context, sdd_state* master, sdd_array* slaves) {
	char desc[1024];
	sprintf(desc, "[%s    ", master->name);

	while(sdd_array_count(slaves) > 0) {
		sdd_state* one = sdd_array_pop_front(slaves);
		strcat(desc, "[");
		strcat(desc, one->name);
		strcat(desc, "]");
	}
	strcat(desc, "]");

	EXPMarkTag("cluster", desc, FONT_CLR_GREEN);
}

void EXPMarkdownTransition(void* context, sdd_transition* t) {
	char sig_desc[256];
	sdd_describe_signal(t->signal, sig_desc);

	char desc[4096+256*3];
	if (t->conditions[0] == 0) {
		sprintf(desc, "[%s] -> [%s]: \t%s", t->from, t->to, sig_desc);
	} else {
		sprintf(desc, "[%s] -> [%s]: \t%s (%s)", t->from, t->to, sig_desc, t->conditions);
	}

	if (t->actions[0] != 0) {
		strcat(desc, " / ");
		strcat(desc, t->actions);
	}
	EXPMarkTag("trans", desc, FONT_CLR_MAGENTA);
}

void EXPMarkRootState(void* context, sdd_state* rootState) {
	EXPMarkTag("top", rootState->name, FONT_CLR_RED);
}

int main() {
	char* dsl = sdd_dsl
	(
	// 每个状态机必须有且只有一个‘根’状态，如果根状态不是该DSL所描述的唯一状态，那就必须在d字段（default)后指定【唯一】的默认激活的子状态名称。默认状态既可以是子辈状态，也可以是孙辈以后的状态
	[A
		// 跟在状态行为表后面的可以是另一个状态，或者多个‘簇’状态，这些状态间可以用空格分开，或紧挨在一起，形成有层次的互斥状态集，这里的互斥，指的是，同级状态中，同时仅允许其中一个被激活。例如B1,B2同时仅允许激活一个 
		[B1][B2]

		// 每个状态可以定义属于它的“行为字段表“，e字段(entry)表示当该状态激活时执行的方法集；x字段(exit)表示当该状态注销时执行的方法集；方法集按声明顺序执行，且一旦声明了字段，则它对应的方法集不得为空。但是，任何字段都是可选的。 
		[B3 e:e1 e2 x:x1]

		// 可以仅使用e字段 
		[B4 e:e1]

		// 也可以仅使用x字段 
		[B5 x:x1]

		// 状态可以定义它激活时默认激活的子孙状态。可以使直系子状态，也可以是孙辈以后的状态。默认状态字段本身是可选的，但如果状态包含后代状态，则必须通过自身或其祖先状态来确认当它激活时需要激活的子状态是什么（难点） 
		[B6
			[C1]
		]

		// 子状态也可以有属于它的子状态 
		[B7 [C2]]

		// 状态还可以包含“正交”状态集，这些状态和‘簇’的标记语法不同，通过'|'符号进行分隔。需要注意的是，‘簇’状态和‘正交‘状态不可以同时存在于同一个容器状态中，例如：[A [B1] [B2]|[B3]]。这种定义可以通过将B2,B3再置入一个和B1同级的‘簇’状态来实现：[A [B1][B2 [C1]|[C2]]] 
		[B8 [C3]|[C4]]

		// 当然，每一个’正交状态‘本身也是一个状态，它也可以包含子‘簇’状态集，或者’正交‘状态集 
		[B9 [C5]|[C6 [D1][D2]]]
	]

	[.]  -> [B1]: $Initial
	[A]  -> [.] : $Final
	[A]  -> [B1]: $Initial

	// “纯朴”状态转换： 如果[B1]状态是激活的，当发生Event1时，激活[B2]状态。 [B1]称为源状态，[B2]称为目的状态。需要注意的是，当目的状态和源状态为非同源时，源状态会被注销，否则直接激活目的状态 
	[B1] -> [B2]: Event1

	// “条件”状态转换：如果[B1]状态是激活的，当发生Event2，且布尔条件a为真(YES)时，激活[B3]状态
	[B1] -> [B3] : Event2 (a)

	// 下面列出了各种复合逻辑表达式组成的“条件”，包括与、或、非、异或，以及用于明示运算优先级的圆括号 
	[B1] -> [B4] : Event3 (a & b)
	[B1] -> [B5] : Event4 (a | b)
	[B1] -> [B6] : Event5 (a ^ b)
	[B1] -> [B7] : Event6 (!a)
	[B1] -> [B8] : Event7 (a & (b | c))
	[B1] -> [B9] : Event8 (a | !b)
	[B1] -> [B10]: Event9 ((a & b) & c)
	[B1] -> [B11]: Event10 (!!a)
	[B1] -> [B12]: Event11 (a | !(b ^ c))

	// 当B1到C1的转换成立时，会执行由分隔符 '/' 后的Action方法(Transition Action)，这个（些）Action是在转换完成后才执行的，这意味着如果B1,C1包含了e,x字段，则会执行完B1.x以及C1.e后，才执行Action
	[B1] -> [C1]: Event1 / Action

	// Transition Action可以包含多个执行方法序列，它们的执行时按声明顺序进行的
	[B1] -> [C2]: Event2 / a1 a2

	// 这是一个“完全”定义的Transition，它包含了用于判断是否进行状态转换的condition条件，以及当condition满足时，由B1转换到C3后，执行的action a
	[B1] -> [C3]: Event3 (condition) / a
	);

	sdd_parser_callback callback;
	callback.stateHandler      = &EXPMarkdownState;
	callback.clusterHandler    = &EXPMarkdownCluster;
	callback.transitionHandler = &EXPMarkdownTransition;
	callback.completionHandler = &EXPMarkRootState;

	sdd_parse(dsl, &callback);
	return 0;
}
