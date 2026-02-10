# Def-Done Verifier Subagent Prompt Template

Dispatch after all files are processed and lint passes. Read-only — final verification gate.

## Cursor Task Tool Parameters

```
Task:
  description: "i18n: Verify definition of done"
  subagent_type: "i18n-verifier"
  readonly: true
```

## Prompt (context only — the subagent type has built-in instructions)

```
## Definition of Done

[PASTE def-done.md CONTENT HERE]

## Plan

[PASTE plan.md CONTENT HERE — includes file list with statuses]

## Modified Files

[LIST ALL FILES MODIFIED DURING THE WORKFLOW]

## Babel Key Index

[PASTE FULL KEY INDEX — or the subset used across all files]

## Framework

Type: [FRAMEWORK_TYPE]
Import: [FRAMEWORK_IMPORT_STATEMENT]
```

## Claude Code

Uses `.claude/agents/i18n-verifier` agent (sonnet, read-only). Pass the same context above as the task description.
