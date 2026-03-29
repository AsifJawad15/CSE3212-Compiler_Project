#ifndef PARSER_CTX_H
#define PARSER_CTX_H

#include "common.h"

/* ========= Parser Context ========= */
/* Wraps parser-wide global state into a single struct so that
   every module can access it through a shared extern.            */
typedef struct {
    /* Execution suppression counter: when > 0, all side effects
       are skipped (used to prevent dead branches from executing) */
    int suppress_exec;

    /* ICG suppression counter: when > 0, emit()/store_icg_line()
       are skipped (prevents false-branch body statements from
       emitting ICG before the if_false goto) */
    int suppress_icg;

    /* Current declaration type — used by init_item for correct
       type in comma-separated lists */
    int current_decl_type;

    /* Stack for conditionMatched to support nested if-chains */
    int cm_stack[50];
    int cm_top_idx;

    /* ICG label stack for if/elif/else control flow */
    char* icg_label_stack[50];
    int icg_label_top;
} ParserContext;

extern ParserContext g_ctx;

/* ---- conditionMatched stack macros ---- */
#define CM_PUSH(v)   (g_ctx.cm_stack[++g_ctx.cm_top_idx] = (v))
#define CM_POP()     (g_ctx.cm_stack[g_ctx.cm_top_idx--])
#define CM_SET(v)    (g_ctx.cm_stack[g_ctx.cm_top_idx]  = (v))
#define CM_GET()     (g_ctx.cm_stack[g_ctx.cm_top_idx])

/* ---- ICG label stack macros ---- */
#define ICG_LPUSH(l)  (g_ctx.icg_label_stack[++g_ctx.icg_label_top] = (l))
#define ICG_LPOP()    (g_ctx.icg_label_stack[g_ctx.icg_label_top--])
#define ICG_LPEEK()   (g_ctx.icg_label_stack[g_ctx.icg_label_top])

#endif /* PARSER_CTX_H */
