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