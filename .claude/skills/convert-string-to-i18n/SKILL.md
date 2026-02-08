---
name: convert-string-to-i18n
description: Replaces hard-coded UI strings with existing Babel translation keys in Wix React projects. Adaptive execution — tries subagents in parallel, falls back to single-agent if model can't support it. plan.md tracking + def-done.md verification. Supports yoshi-flow-bm, fe-essentials, fe-essentials-standalone, wix-i18n-config, fed-cli-i18next, ICU/parameterized messages. Use when the user says "add translations", "i18n", "internationalize", "babel keys", "replace hard-coded text", or "convert strings to i18n".
---

# Convert Strings to i18n

Replace hard-coded UI text with existing Babel translation keys. Produces plan.md + def-done.md, verifies all criteria before completion.

## Execution Strategy

**Parallel subagents by default.** Always dispatch independent tasks in parallel (up to 4 at once). Do NOT self-justify choosing direct mode — "I prefer direct mode" or "more control" are never valid reasons.

```
1. After Step 2 → identify task dependencies
2. Independent tasks → dispatch subagents in parallel
3. Dependent tasks (one task's output feeds another) → process sequentially
4. resource_exhausted at runtime → fall back to direct mode for remaining tasks
```

## Principles

- **AI-first matching** — Read code + keys, match semantically. No scripts.
- **No temp dependencies** — No `@babel/parser`. Read and understand code directly.
- **Incremental** — File-by-file. If one fails, skip and continue.
- **Conservative** — Skip uncertain matches. Never invent keys.
- **Verified** — Final state verified against def-done.md checklist.

## Input

```typescript
type Input = {
  projectId?: string;    // Babel project ID (from babel_config.json)
  projectName?: string;  // Babel project name
  scope?: string;        // Directory or glob to limit processing
};
```

If `--debug` is in the user prompt, show detailed per-string matching decisions.

---

## Step 1 — Setup

**Goal**: Load translation keys, build namespace map, detect framework, ensure i18n infrastructure.

### 1.1 Load Babel Config

Find `babel_config.json` in the project root. Extract `projectId`, `projectName`, `langFilePath`.
If missing, use values from user input. Fail if neither available.

### 1.2 Load & Index Translation Keys

1. Read `messages_en.json` from `langFilePath` directory
2. If missing/invalid → **fail**: "Babel 3 not configured (messages_en.json missing); configure and re-run"
3. Build key index: `{ keyName → englishValue }` for all keys
4. Annotate ICU keys with parameter metadata — see [references/icu-guide.md](references/icu-guide.md)

### 1.3 Build Namespace Map

Create a mapping between key namespace prefixes and source directories:

1. **From keys**: Group by first 2 namespace segments (e.g., `verse.keyGeneration.*` → `keyGeneration`)
2. **From existing `t()` calls**: Grep for `t('namespace.` patterns in source files to learn which directories use which namespaces
3. **From file paths**: Map component directory names to likely namespace segments

### 1.4 Detect Framework & Ensure Infrastructure

Check `package.json` dependencies (priority order):

| Priority | Dependency | Framework |
|----------|-----------|-----------|
| 1 | `@wix/yoshi-flow-bm` | `yoshi-flow-bm` |
| 2 | `@wix/fe-essentials-standalone` | `fe-essentials-standalone` |
| 3 | `@wix/fe-essentials` | `fe-essentials` |
| 4 | `@wix/wix-i18n-config` | `wix-i18n-config` |
| 5 | `@wix/fed-cli-i18next` | `fed-cli-i18next` |

**Ensure infra is ready**:

- **yoshi-flow-bm**: `.application.json` must have `translations.enabled: true`
- **fe-essentials**: `.application.json` must have `translations.enabled: true`, `translations.suspense: true`
- **fe-essentials-standalone**: `createEssentials` call must include `i18n.messages` with `messages_en.json` import. If missing:

```typescript
import messages_en from '<relative-path>/messages_en.json';
const essentials = createEssentials({
  // ...existing config
  i18n: { messages: messages_en },
});
```

Add missing config automatically. Update `tsconfig.json` with `resolveJsonModule: true` if needed.

**Output**: `Step 1 — keys: <count> | framework: <type> | infra: ready`

---

## Step 2 — Plan

**Goal**: Find all candidate files, generate plan.md and def-done.md, create TodoWrite.

### 2.1 Find Candidate Files

Search `.tsx`/`.ts` files in `src/` for potential UI strings:

```bash
rg -l --type-add 'tsx:*.tsx' --type tsx --type ts \
  '(>[A-Z][\w\s]+<|placeholder="|label="|title="|subtitle="|content="|buttonText=")' src/
```

Also grep for string literals that look like UI text (capitalized multi-word strings, sentences).

**Exclude**: `*.spec.*`, `*.test.*`, `.d.ts`, `node_modules`, generated code, `__mocks__`, `__generated__/`, `locale-keys/` (code-generated LocaleKeys wrappers — already i18n'd).

If `scope` input is provided, limit to that path. Order files by number of potential strings (most first).

### 2.2 Generate plan.md

Write `plan.md` to the target project root:

```markdown
# i18n Conversion Plan

## Project
- Framework: {framework}
- Babel project: {projectName} ({projectId})
- Keys loaded: {count}
- Infra: ready

## Files

| # | File | Est. Strings | Namespace | Status |
|---|------|-------------|-----------|--------|
| 1 | src/components/Foo/Foo.tsx | ~5 | verse.foo | pending |
| 2 | ... | ... | ... | pending |
```

### 2.3 Generate def-done.md

Write `def-done.md` to the target project root:

```markdown
# Definition of Done

All must be true for 100% success:

- [ ] Every candidate file processed (replaced or explicitly skipped with reason)
- [ ] All replacements use existing babel keys only (zero invented keys)
- [ ] ICU parameters correctly mapped (count, names, positions)
- [ ] useTranslation hook + import added in every modified component
- [ ] Import uses correct framework path
- [ ] Lint passes on all modified files (zero new lint errors)
- [ ] No TypeScript compilation errors introduced
- [ ] Skipped strings documented with skip reason
- [ ] plan.md updated: all files marked completed or skipped
```

### 2.4 Create TodoWrite

Create a TodoWrite entry for each candidate file from plan.md.

**Output**: `Step 2 — candidates: <n> files | plan.md + def-done.md written`

---

## Step 3 — Execute

**Goal**: Process each file — replace strings with translation keys.

> **Use parallel subagents for independent tasks.** In this skill, candidate files are almost always independent (different file, different strings, no shared state). Dispatch them in parallel. Only process tasks sequentially when they genuinely depend on each other's output, or fall back to direct mode if subagents fail with `resource_exhausted`. Do NOT choose direct mode for "more control" or preference — that is not a valid reason.

**Per batch:**

1. **Select next batch** — take up to 4 pending files from plan.md
2. **Dispatch file-processor subagents in parallel** (one per file) using [prompts/file-processor-prompt.md](prompts/file-processor-prompt.md):
   - Provide key subset filtered to relevant namespace (max ~30 keys per file)
   - Provide file paths to reference docs — do NOT paste their content
3. **Collect results** — wait for all to complete
4. **Dispatch translation-reviewer subagents in parallel** (one per completed file) using [prompts/translation-reviewer-prompt.md](prompts/translation-reviewer-prompt.md):
   - Provide key subset, file-processor report, modified file path
5. **Collect reviews** — for files with issues:
   - Dispatch file-processor fix → reviewer re-review (serially per file)
   - Repeat until approved
6. **Update plan.md** — mark all batch files as `completed` or `skipped`
7. **Update TodoWrite** for the batch

Repeat batches until no pending files remain.

### 3B. Direct Mode (fallback)

> Only use when: (a) subagent failed with `resource_exhausted`, or (b) tasks are genuinely dependent and can't be parallelized. "I prefer direct mode" is not a valid reason.

Process remaining files one at a time yourself. Follow these context management rules:

- **Keys**: Filter to ~20-30 keys from the relevant namespace per file
- **Reference files**: Read `references/icu-guide.md` and `references/replacement-patterns.md` on-demand only when you encounter ICU params or unusual patterns (Trans, class components)
- **Per-file cleanup**: After finishing a file, retain only the summary line. Do not carry forward the file's full content.
- **Batch lint**: If >10 files, lint-check every 5 files instead of at the end

**Per file:**

1. **Read the file**
2. **Identify translatable strings** — see String Identification Rules below
3. **Match each string to a babel key** — see Matching Rules below
4. **Apply replacements** (bottom-up, last line first) — see Replacement Rules below
5. **Update plan.md** and TodoWrite

### String Identification Rules

| Include | Skip |
|---------|------|
| JSX text: `<div>Hello</div>` | URLs, paths, CSS classes |
| JSX attrs: `placeholder="..."`, `label="..."`, `title="..."` | `data-testid`, `data-hook`, `className`, `key`, `id` |
| UI object props: `{ label: "Cancel" }` | Console/error messages for developers |
| String constants → UI: `const TITLE = "Dashboard"` | Enum values, config keys, regex |
| Template literals: `` `Hello ${name}` `` | Strings already in `t()`, `Trans`, `localeKeys`, `this.props.t()` |

### Matching Rules

- **Exact match**: string === key value → accept
- **Near-exact**: Minor punctuation/casing diffs → accept
- **Semantic match**: Same meaning, different wording → accept if context aligns
- **Namespace priority**: Prefer keys from the namespace matching this file's directory
- **ICU compatibility**: For parameterized strings, check parameter count and positions — see [references/icu-guide.md](references/icu-guide.md)
- **No match**: Skip with reason

| Skip Reason | When |
|-------------|------|
| `no_matching_key` | No key with matching meaning exists |
| `ambiguous` | 2+ equally valid keys (note alternatives) |
| `uncertain` | Possible match but low confidence |
| `param_mismatch` | ICU parameter count/type doesn't align |

Never invent keys. Prefer exact > near-exact > semantic. When ambiguous, skip and note alternatives.

### Replacement Rules

- Add `useTranslation` import if not present (framework-specific, see below)
- Add `const { t } = useTranslation()` in component body if not present
- Replace string with `t('key')` or `t('key', { params })` for ICU
- For keys with `<0>...</0>` markup, use `Trans` component
- For class components, use `withTranslation` HOC
- Context-specific rules: see [references/replacement-patterns.md](references/replacement-patterns.md)

**Output**: `Step 3 — mode: <subagent|direct> | files: <n> | replaced: <total> | skipped: <total>`

---

## Step 4 — Verify (Adaptive)

**Goal**: Lint, verify all def-done criteria, produce final summary.

### 4a. Lint Changed Files

Run linter on all modified files. Fix new lint errors.

### 4b. Verify def-done.md

**Subagent mode**: Dispatch def-done-verifier using [prompts/def-done-verifier-prompt.md](prompts/def-done-verifier-prompt.md) with def-done.md, plan.md, modified file list, key index, framework type.

**Direct mode**: Check each criterion yourself:

1. **Every candidate file processed** — no files left as `pending` in plan.md
2. **All keys exist** — grep `t('...')` calls, cross-reference against key index
3. **ICU parameters correct** — verify param names/count match ICU templates
4. **useTranslation hook + import present** — in every modified file with `t()` calls
5. **Correct framework import path** — matches detected framework
6. **Lint passes** — confirmed in 4a
7. **No TypeScript errors** — run `tsc --noEmit` if available
8. **Skipped strings documented** — every skipped string has a reason
9. **plan.md fully updated** — all files marked `completed` or `skipped`

If any criterion fails: fix the gap, re-check. Repeat until all pass.

### 4c. Final Summary

Once all criteria pass:

1. Update def-done.md: check all boxes
2. Summary report: files processed, strings replaced/skipped, skip reasons breakdown
3. Show notable skipped strings grouped by reason for user review

**Output**: `Step 4 — lint: ok | def-done: PASS | done`

---

## Subagent Dispatch

When dispatching subagents, follow these rules:

- **Key subset**: max ~30 keys per file, filtered to relevant namespace — do NOT paste full key index
- **Reference files**: Provide absolute file paths only — do NOT paste content into prompts
- **Parallel limit**: max 4 subagents at once
- **Independence**: All candidate files are independent — safe to parallelize file-processors and reviewers
- **Review loop**: If reviewer finds issues → fix → re-review (serial per file, but different files can be reviewed in parallel)
- **Subagents cannot spawn subagents** — the orchestrator (this skill, running in the main conversation) dispatches all subagents

### Claude Code (native agents)

Claude Code delegates to `.claude/agents/i18n-*` agents automatically based on task descriptions. Each agent runs in its own context window with tool restrictions, model selection, and preloaded skills.

| Agent | File | Model | Mode | Purpose |
|-------|------|-------|------|---------|
| `i18n-file-processor` | `.claude/agents/i18n-file-processor.md` | inherit | acceptEdits | Process one file |
| `i18n-reviewer` | `.claude/agents/i18n-reviewer.md` | haiku | plan (read-only) | Review replacements |
| `i18n-verifier` | `.claude/agents/i18n-verifier.md` | inherit | plan (read-only) | Final def-done check |

Background execution enables true parallelism — ask Claude to run file-processors in the background for concurrent processing.

### Cursor (Task tool templates)

Uses `prompts/` directory templates with the Task tool (up to 4 parallel):

- [prompts/file-processor-prompt.md](prompts/file-processor-prompt.md) — Process one file
- [prompts/translation-reviewer-prompt.md](prompts/translation-reviewer-prompt.md) — Review replacements
- [prompts/def-done-verifier-prompt.md](prompts/def-done-verifier-prompt.md) — Final verification

---

## Framework Import Patterns

```typescript
// yoshi-flow-bm
import { useTranslation } from '@wix/yoshi-flow-bm';

// fe-essentials-standalone
import { useTranslation } from '@wix/fe-essentials-standalone/react';

// fe-essentials
import { useTranslation } from '@wix/fe-essentials/react';

// wix-i18n-config (also exports Trans and withTranslation)
import { useTranslation } from '@wix/wix-i18n-config';

// fed-cli-i18next
import { useTranslation } from '@wix/fed-cli-i18next';
```

Usage in component body:
```typescript
const { t } = useTranslation();
```

### Class Components (withTranslation HOC)

If the file contains a **class component**, use the HOC pattern instead of the hook:

```typescript
import { withTranslation, WithTranslation } from '@wix/wix-i18n-config';
// Access via this.props.t('key')
export default withTranslation()(MyComponent);
```

### Trans Component (Rich-Text JSX Interpolation)

When a translation value contains **embedded markup** (links, bold, line breaks), use `Trans` instead of `t()`:

```tsx
import { Trans } from '@wix/wix-i18n-config';
// Key value: "Read our <0>terms</0> and <1>privacy policy</1>"
<Trans i18nKey="legal.terms" components={[<a href="/terms" />, <a href="/privacy" />]} />
```

Use `Trans` only when the key's value contains numbered tags (`<0>...</0>`). For plain text, always prefer `t()`.

### Already-Translated Patterns to Skip

Skip files/strings that are **already using translations**:

| Pattern | What it is | Action |
|---------|-----------|--------|
| `t('key')` / `t('key', {...})` | Standard hook | Already done |
| `this.props.t('key')` | HOC pattern | Already done |
| `localeKeys.some.key()` | Code-generated LocaleKeys | Already done |
| `<Trans i18nKey="..." />` | Trans component | Already done |
| `useLocaleKeys()` | LocaleKeys hook | Already done — skip entire file if dominant pattern |

---

## Red Flags

**Never:**
- Invent keys that don't exist in the babel key index
- Skip the def-done verification step
- Start verification before all files are processed
- Accept "close enough" (issues found = not done)
- Leave files as `pending` in plan.md without processing or skipping them
- Make subagent read full `messages_en.json` (provide key subset instead)
- Paste reference file content into subagent prompts (provide paths)

## Error Handling

- **File read failure**: Skip file, mark as skipped in plan.md, continue
- **Key loading failure**: Fail entire workflow (no keys = no matching)
- **Single replacement failure**: Skip that string, continue within the file
- **Subagent resource_exhausted**: Switch to direct mode (see Step 3.0)
- **Lint failure**: Attempt fix; if unfixable, report but don't roll back
- **Def-done verification failure**: Fix gaps, re-verify (loop until PASS)
