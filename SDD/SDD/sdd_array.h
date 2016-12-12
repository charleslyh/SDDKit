// sdd_array.h
//
// Copyright (c) 2016 CharlesLiyh
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

#ifndef SDD_ARRAY_H
#define SDD_ARRAY_H

struct sdd_array_t;
typedef struct sdd_array_t sdd_array;
typedef void* sdd_array_value;

typedef enum sdd_bool_t {
	sdd_no  = 0,
	sdd_yes = 1,
} sdd_bool;

sdd_array* sdd_array_new();
void sdd_array_delete(sdd_array* array);

int sdd_array_count(sdd_array* array);
void sdd_array_push(sdd_array* array, sdd_array_value value);
void sdd_array_push_front(sdd_array* array, sdd_array_value value);

sdd_array_value sdd_array_pop(sdd_array* array);
sdd_array_value sdd_array_pop_front(sdd_array* array);
sdd_array_value sdd_array_at(sdd_array* array, int index, sdd_bool from_begin);

typedef void (*sdd_array_element_handler)(void* context, void* handler);
void sdd_array_foreach(sdd_array* array, sdd_array_element_handler handler, void* context);

#endif // SDD_ARRAY_H
