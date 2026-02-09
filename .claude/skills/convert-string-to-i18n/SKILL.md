---
name: convert-string-to-i18n
description: Replaces hard-coded UI strings with existing Babel translation keys in Wix React projects. Adaptive execution — tries subagents in parallel, falls back to single-agent if model can't support it. plan.md tracking + def-done.md verification. Supports yoshi-flow-bm, fe-essentials, fe-essentials-standalone, wix-i18n-config, fed-cli-i18next, ICU/parameterized messages. Use when the user says "add translations", "i18n", "internationalize", "babel keys", "replace hard-coded text", or "convert strings to i18n".
---

# Convert Strings to i18n

Replace hard-coded UI text with existing Babel translation keys. Produces plan.md + def-done.md, verifies all criteria before completion.

## Execution Strategy

**Run to completion.** Do not stop to ask "should I continue?" between files, batches, or steps. The entire workflow (discover → plan → execute → verify) must run autonomously in a single pass. Only pause for user input when explicitly required (parallelism strategy question in Step 2) or when a genuine ambiguity blocks progress.

**Parallel subagents by default.** Do NOT self-justify choosing direct mode — "I prefer direct mode" or "more control" are never valid reasons.

1. After Step 2 → ask user for parallelism strategy (fast / moderate / conservative)
2. Identify task dependencies
3. Independent tasks → dispatch subagents in parallel (batch size per strategy)
4. Dependent tasks → process sequentially
5. resource_exhausted at runtime → fall back to direct mode

Strategy limits:
- **Fast**: up to 8 total subagents (ceiling, not target), 4 concurrent, fine-grained: 1–2 files each
- **Moderate**: ~half of fast total, 4 concurrent, grouped: 3–4 files per subagent
- **Conservative**: ~quarter of fast total, 3 concurrent, aggressively grouped: many files per subagent

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

## Steps 1-2: Discovery (delegated)

**Goal**: Load translation keys, detect framework, find candidate files, generate plan.

Steps 1 and 2 are **read-only discovery** — no files are modified. Delegate this work to the discovery agent to keep scanning output out of the main conversation context.

**Subagent mode**: Dispatch `i18n-discovery` using [prompts/discovery-prompt.md](prompts/discovery-prompt.md) with project root path and optional scope.

**Direct mode** (fallback): If subagent is unavailable, perform discovery yourself following the sub-steps below.

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
- **fe-essentials-standalone**: `createEssentials` call must include `i18n.messages` with `messages_en.json` import. If missing, the orchestrator adds it after discovery completes (discovery is read-only).

### 1.5 Find Candidate Files

Run the scanner script to find files with hardcoded UI strings:

```bash
node [ABSOLUTE_PATH_TO_SKILL]/scripts/scan-ui-strings.cjs [SCOPE_OR_SRC_DIR]
```

The script ([scripts/scan-ui-strings.cjs](scripts/scan-ui-strings.cjs)):
- Walks `.js`, `.jsx`, `.ts`, `.tsx` files (skips `node_modules`, `dist`, `build`, etc.)
- **Excludes test files** (`*.spec.*`, `*.test.*`) — those are updated as a side-effect of source file processing
- Detects JSX text, JSX attrs (`title`, `placeholder`, `label`, `alt`, `aria-label`), string literals
- Filters out code-like strings (URLs, constants, dotted identifiers, expressions)
- Outputs a markdown table sorted by estimated string count (most strings first)
- Reports totals: estimated strings, user-facing strings, words, chars

Use the script output as the candidate file list. Do NOT manually grep — the script is faster and more consistent.

**Output**: `Discovery — keys: <count> | framework: <type> | candidates: <n> files`

---

## Step 2 — Plan (orchestrator builds from discovery results)

**Goal**: Apply infrastructure fixes, generate plan.md + def-done.md, ask parallelism strategy.

### 2.1 Apply Infrastructure Fixes

If the discovery report flagged missing infra (e.g., `fe-essentials-standalone` missing `i18n.messages`), apply fixes now:

```typescript
import messages_en from '<relative-path>/messages_en.json';
const essentials = createEssentials({
  // ...existing config
  i18n: { messages: messages_en },
});
```

Update `tsconfig.json` with `resolveJsonModule: true` if needed.

### 2.2 Generate plan.md (from discovery report)

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
- [ ] No destructive replacements (no string replaced with undefined/null/empty — every replacement is t() or Trans)
- [ ] Test files updated: hardcoded strings in RTL queries replaced with keys, useTranslation mocked
- [ ] plan.md updated: all files marked completed or skipped
```

### 2.4 Create TodoWrite

Create a TodoWrite entry for each candidate file from plan.md.

### 2.5 Ask Parallelism Strategy

Before execution, ask the user:

| Strategy | Max Subagents | Task Grouping | Trade-off |
|----------|--------------|---------------|-----------|
| **Fast** | Up to 8 (ceiling, not target) | 1–2 files per subagent | More requests & tokens, faster |
| **Moderate** | ~half of fast | 3–4 files per subagent | Balanced speed vs cost |
| **Conservative** | ~quarter of fast | Many files per subagent | Fewest requests, slowest |

Exact counts depend on actual file count. Max concurrent subagents per batch is always 4 (platform limit). Fast with 8 runs 2 batches.

**Output**: `Step 2 — candidates: <n> files | plan.md + def-done.md written | strategy: <choice>`

---

## Step 3 — Execute

**Goal**: Process each file — replace strings with translation keys.

**Parallel subagents by default.** Do NOT self-justify choosing direct mode — "I prefer direct mode" or "more control" are never valid reasons.

> Candidate files are almost always independent (different file, different strings, no shared state). Only fall back to direct mode when: (a) subagent fails with `resource_exhausted`, or (b) tasks genuinely depend on each other's output.

### Batch sizing by strategy

- **Fast**: Up to 4 concurrent per batch. Total subagents up to 8 (only when justified by file count). Fine-grained: 1–2 files each.
- **Moderate**: Up to 4 concurrent per batch. Total subagents roughly half of what fast would use. Group related files: 3–4 per subagent.
- **Conservative**: Up to 3 concurrent per batch. Total subagents roughly a quarter of what fast would use. Aggressive grouping.

**Per batch:**

1. **Select pending files** from plan.md (batch size per strategy above)
2. **Group files** per subagent according to strategy granularity
3. **Dispatch file-processor subagents in parallel** (one per group) using [prompts/file-processor-prompt.md](prompts/file-processor-prompt.md):
   - Provide key subset filtered to relevant namespace (max ~30 keys per file)
   - Provide file paths to reference docs — do NOT paste their content
4. **Collect results**
5. **Dispatch translation-reviewer subagents in parallel** (one per completed group) using [prompts/translation-reviewer-prompt.md](prompts/translation-reviewer-prompt.md):
   - Provide key subset, file-processor report, modified file path
6. **Fix issues**: processor fix → reviewer re-review → repeat until approved
7. **Update plan.md** — mark all batch files as `completed` or `skipped`
8. **Update TodoWrite** for the batch

Repeat batches until no pending files remain. **Do not pause between batches to ask for confirmation** — proceed automatically.

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
- **No match**: **Leave the original string untouched.** Skip with reason.

| Skip Reason | When |
|-------------|------|
| `no_matching_key` | No key with matching meaning exists |
| `ambiguous` | 2+ equally valid keys (note alternatives) |
| `uncertain` | Possible match but low confidence |
| `param_mismatch` | ICU parameter count/type doesn't align |

Never invent keys. Prefer exact > near-exact > semantic. When ambiguous, skip and note alternatives.

**Skip means leave unchanged** — the original string must remain exactly as it was in the source. Never replace a skipped string with `undefined`, `null`, `''`, or remove it.

### Replacement Rules

- **Every replacement must produce a `t()` or `<Trans>` call** — never replace a string with `undefined`, `null`, `''`, or any non-translation value. If no key matches, leave the original string untouched.
- Add `useTranslation` import if not present (framework-specific, see below)
- Add `const { t } = useTranslation()` in component body if not present
- Replace string with `t('key')` or `t('key', { params })` for ICU
- For keys with `<0>...</0>` markup, use `Trans` component
- For class components, use `withTranslation` HOC
- Context-specific rules: see [references/replacement-patterns.md](references/replacement-patterns.md)

### Test File Updates

After replacing strings in a source file, update the corresponding test file:

1. **Find test file** — look for `*.spec.tsx`, `*.spec.ts`, `*.test.tsx`, `*.test.ts` with matching name in the same directory
2. **For each replaced string** (`"Save Changes"` → `t('verse.foo.save')`):
   - Search the test file for the same hardcoded string in RTL queries (`getByText`, `findByText`, `queryByText`, `getByRole`), assertions, and driver patterns
   - Replace with the translation key: `'verse.foo.save'`
3. **Add `useTranslation` mock** if the test file doesn't already mock it. Detect the project's test runner first:
   - Check for `vitest` in devDependencies → use `vi.mock()`
   - Check for `jest` in devDependencies → use `jest.mock()`
   - Check existing test files for `vi.mock` vs `jest.mock` patterns to confirm
   - Match the project's existing mock style (module factory, `__mocks__/` dir, `beforeEach` setup, etc.)
   - The mock should make `t(key)` return the key itself

4. **Skip if no test file exists** — don't create test files, just note it in the report

The mock makes `t(key)` return the key itself, so `getByText('verse.foo.save')` works. Always match the project's existing test patterns — don't assume a specific test runner.

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
9. **No destructive replacements** — no prop/variable that previously held a string now holds `undefined`/`null`/`''`; every replacement site has a `t()` or `<Trans>` call
10. **Test files updated** — for each modified source file with a test, hardcoded strings replaced with keys, `useTranslation` mocked
11. **plan.md fully updated** — all files marked `completed` or `skipped`

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
| `i18n-file-processor` | `.claude/agents/i18n-file-processor.md` | inherit | bypassPermissions | Process one file |
| `i18n-reviewer` | `.claude/agents/i18n-reviewer.md` | haiku | plan (read-only) | Review replacements |
| `i18n-verifier` | `.claude/agents/i18n-verifier.md` | inherit | plan (read-only) | Final def-done check |

#### Background execution for parallelism

Dispatch file-processors in the background for concurrent processing. **CRITICAL**: File-processors use `bypassPermissions` because background subagents auto-deny any permission not pre-approved. With `acceptEdits`, background agents silently fail to write files — they complete their analysis but no changes are saved to disk.

**Orchestrator instructions for Claude Code:**
1. Dispatch up to 4 `i18n-file-processor` agents per batch
2. Explicitly request background execution: "run these in the background"
3. Wait for all background agents to complete before dispatching the next batch
4. After each batch, verify files were actually modified (`git status` or check file contents) before marking as completed in plan.md
5. If an agent reports completion but the file is unchanged, re-dispatch in foreground

### Cursor (Task tool templates)

Uses `prompts/` directory templates with the Task tool (up to 4 parallel):

- [prompts/discovery-prompt.md](prompts/discovery-prompt.md) — Discover files & keys (read-only, fast model)
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
- Replace a string with `undefined`, `null`, `''`, or remove it — every replacement must be `t('key')` or `<Trans>`. No match = leave original string untouched.
- Invent keys that don't exist in the babel key index
- Skip reviews (reviewer AND verifier are both required)
- Skip re-review after fixes (reviewer found issues = fix = review again)
- Start verification before all files are processed
- Accept "close enough" (issues found = not done)
- Leave files as `pending` in plan.md without processing or skipping them
- Choose direct mode for preference ("more control" is not valid)
- Make subagent read full `messages_en.json` (provide key subset instead)
- Paste reference file content into subagent prompts (provide paths)
- Skip self-review in processor (both self-review and external review are needed)
- Ignore subagent questions (answer before letting them proceed)
- Let processor self-review replace actual review (both are needed)
- Default to 8 subagents just because "fast" was selected (8 is the ceiling, not target)
- Skip asking the user for parallelism strategy (always ask before dispatch)
- Stop between files/batches/steps to ask "should I continue?" — run to completion autonomously

## Error Handling

- **File read failure**: Skip file, mark as skipped in plan.md, continue
- **Key loading failure**: Fail entire workflow (no keys = no matching)
- **Single replacement failure**: Skip that string, continue within the file
- **Subagent resource_exhausted**: Switch to direct mode (see Step 3.0)
- **Lint failure**: Attempt fix; if unfixable, report but don't roll back
- **Def-done verification failure**: Fix gaps, re-verify (loop until PASS)
