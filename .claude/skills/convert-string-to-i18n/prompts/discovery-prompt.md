# Discovery Subagent Prompt Template

Dispatch this FIRST, before any file processing. Read-only agent that scans the codebase and returns structured data for plan building.

## Cursor Task Tool Parameters

```
Task:
  description: "i18n: Discover files & keys"
  subagent_type: "i18n-discovery"
  readonly: true
  model: "fast"
```

## Prompt (context only — the subagent type has built-in instructions)

```
## Project Root

[PROJECT_ROOT_PATH]

## Scope (optional)

[SCOPE_PATH_OR_EMPTY]

## Skill Path

[ABSOLUTE_PATH_TO_SKILL]

## Scanner Script

[ABSOLUTE_PATH_TO_SKILL]/scripts/scan-ui-strings.cjs
```

## Claude Code

Uses `.claude/agents/i18n-discovery` agent directly. Pass the same context above as the task description.
