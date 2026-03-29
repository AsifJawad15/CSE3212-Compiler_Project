#include "runtime.h"

/* ========= Stack Operations ========= */

void rt_init_stack(int idx) {
    variable[idx].value.stack.top = -1;
}

int rt_push(int stack_idx, double value) {
    if (variable[stack_idx].value.stack.top >= 99) {
        printf("\nStack overflow! Cannot push %f", value);
        return 0;
    }
    variable[stack_idx].value.stack.top++;
    variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top] = value;
    printf("\nPushed %f to stack (position: %d)", value, variable[stack_idx].value.stack.top);
    return 1;
}

double rt_pop(int stack_idx) {
    if (variable[stack_idx].value.stack.top < 0) {
        printf("\nStack underflow! Cannot pop from empty stack");
        return 0;
    }
    double value = variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top];
    variable[stack_idx].value.stack.top--;
    printf("\nPopped %f from stack (new top: %d)", value, variable[stack_idx].value.stack.top);
    return value;
}

double rt_top(int stack_idx) {
    if (variable[stack_idx].value.stack.top < 0) {
        printf("\nStack is empty! No top element");
        return 0;
    }
    return variable[stack_idx].value.stack.values[variable[stack_idx].value.stack.top];
}

int rt_is_empty(int stack_idx) {
    if (stack_idx < 0 || stack_idx >= no_var) {
        return 1;
    }
    return (variable[stack_idx].value.stack.top == -1);
}

int rt_stack_size(int stack_idx) {
    if (stack_idx < 0 || stack_idx >= no_var) {
        printf("\nError: Invalid stack index");
        return 0;
    }
    return variable[stack_idx].value.stack.top + 1;
}

/* ========= Queue Operations ========= */

void rt_init_queue(int idx) {
    variable[idx].value.queue.front = 0;
    variable[idx].value.queue.rear = -1;
    variable[idx].value.queue.size = 0;
}

int rt_enqueue(int queue_idx, double value) {
    if (variable[queue_idx].value.queue.size >= 100) {
        printf("\nQueue overflow! Cannot enqueue %f", value);
        return 0;
    }
    variable[queue_idx].value.queue.rear = (variable[queue_idx].value.queue.rear + 1) % 100;
    variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.rear] = value;
    variable[queue_idx].value.queue.size++;
    printf("\nEnqueued %f to queue (rear: %d)", value, variable[queue_idx].value.queue.rear);
    return 1;
}

double rt_dequeue(int queue_idx) {
    if (variable[queue_idx].value.queue.size <= 0) {
        printf("\nQueue underflow! Cannot dequeue from empty queue");
        return 0;
    }
    double value = variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.front];
    variable[queue_idx].value.queue.front = (variable[queue_idx].value.queue.front + 1) % 100;
    variable[queue_idx].value.queue.size--;
    printf("\nDequeued %f from queue (new front: %d)", value, variable[queue_idx].value.queue.front);
    return value;
}

double rt_get_front(int queue_idx) {
    if (variable[queue_idx].value.queue.size <= 0) {
        printf("\nQueue is empty! No front element");
        return 0;
    }
    return variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.front];
}

double rt_get_rear(int queue_idx) {
    if (variable[queue_idx].value.queue.size <= 0) {
        printf("\nQueue is empty! No rear element");
        return 0;
    }
    return variable[queue_idx].value.queue.values[variable[queue_idx].value.queue.rear];
}

int rt_is_queue_empty(int queue_idx) {
    return (variable[queue_idx].value.queue.size == 0);
}

int rt_queue_size(int queue_idx) {
    return variable[queue_idx].value.queue.size;
}
