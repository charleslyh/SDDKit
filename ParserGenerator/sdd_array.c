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
