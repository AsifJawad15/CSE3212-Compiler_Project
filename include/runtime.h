#ifndef RUNTIME_H
#define RUNTIME_H

#include "common.h"
#include "symtab.h"

/* ========= Stack Operations ========= */
void   rt_init_stack(int idx);
int    rt_push(int stack_idx, double value);
double rt_pop(int stack_idx);
double rt_top(int stack_idx);
int    rt_is_empty(int stack_idx);
int    rt_stack_size(int stack_idx);

/* ========= Queue Operations ========= */
void   rt_init_queue(int idx);
int    rt_enqueue(int queue_idx, double value);
double rt_dequeue(int queue_idx);
double rt_get_front(int queue_idx);
double rt_get_rear(int queue_idx);
int    rt_is_queue_empty(int queue_idx);
int    rt_queue_size(int queue_idx);

#endif /* RUNTIME_H */
