# File Processor Subagent Prompt Template

Dispatch one per file group during Step 3 execution. Needs write access to modify source and test files.

## Cursor Task Tool Parameters

```
Task:
  description: "i18n: Process [FILE_PATH]"
  subagent_type: "i18n-file-processor"
  model: "fast"
```

## Prompt (context only — the subagent type has built-in instructions)

```
## File to Process

[FILE_PATH]

## Available Translation Keys (for this file's namespace)

[PASTE KEY SUBSET — format: key → englishValue, one per line]
[Include ICU parameter annotations where applicable]
[Max ~30 keys, filtered to relevant namespace]

## Framework

Type: [FRAMEWORK_TYPE]
Import: [FRAMEWORK_IMPORT_STATEMENT]
Hook: const { t } = useTranslation();

## Namespace Context

This file is in [DIRECTORY]. Prefer keys from namespace: [NAMESPACE_PREFIX].

## Reference Files (read on demand)

- ICU parameter guide: [ABSOLUTE_PATH_TO_SKILL]/references/icu-guide.md
- Replacement patterns: [ABSOLUTE_PATH_TO_SKILL]/references/replacement-patterns.md
```

## Claude Code

Uses `.claude/agents/i18n-file-processor` agent (bypassPermissions). Pass the same context above as the task description.
