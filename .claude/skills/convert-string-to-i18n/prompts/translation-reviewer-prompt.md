# Translation Reviewer Subagent Prompt Template

Dispatch after a file-processor completes. Read-only — verifies replacements are correct.

## Cursor Task Tool Parameters

```
Task:
  description: "i18n review: [FILE_PATH]"
  subagent_type: "i18n-reviewer"
  readonly: true
```

## Prompt (context only — the subagent type has built-in instructions)

```
## File Reviewed

[FILE_PATH]

## Available Translation Keys (for this file's namespace)

[PASTE SAME KEY SUBSET given to file-processor]

## What the File-Processor Claims

[PASTE FILE-PROCESSOR REPORT HERE]
```

## Claude Code

Uses `.claude/agents/i18n-reviewer` agent (haiku, read-only). Pass the same context above as the task description.
