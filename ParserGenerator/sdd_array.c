// sdd_array.c
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
#include "sdd_array.h"

struct sdd_array_t {
	int count;
	sdd_array_value values[64];
};

sdd_array* sdd_array_new() {
	sdd_array* array = (sdd_array*) malloc(sizeof(sdd_array));
	array->count = 0;
	return array;
}

void sdd_array_delete(sdd_array* array) {
	free(array);
}

int sdd_array_count(sdd_array* array) {
	return array->count;
}

void sdd_array_push(sdd_array* array, sdd_array_value value) {
	array->values[array->count++] = value;
}

void sdd_array_push_front(sdd_array* array, sdd_array_value value) {
	for (int i=0; i<array->count; ++i)
		array->values[i+1] = array->values[i];

	array->values[0] = value;
	array->count += 1;
}

sdd_array_value sdd_array_pop(sdd_array* array) {
	return array->values[--array->count];
}

sdd_array_value sdd_array_pop_front(sdd_array* array) {
	sdd_array_value value = array->values[0];
	for (int i=0; i<(array->count - 1); ++i)
		array->values[i] = array->values[i+1];

	array->count -= 1;
	return value;
}

sdd_array_value sdd_array_at(sdd_array* array, int index, sdd_bool from_begin) {
	if (from_begin == sdd_yes) {
		return array->values[index];
	} else {
		return array->values[array->count - index - 1];
	}
}

void sdd_array_foreach(sdd_array* array, sdd_array_element_handler handler, void* context) {
	for (int i=0; i<sdd_array_count(array); ++i) {
		(*handler)(context, sdd_array_at(array, i, sdd_yes));
	}
}
