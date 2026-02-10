---
name: implement-bi
description: Implements Wix BI tracking events end-to-end in yoshi-flow-bm React projects using bi-schema-loggers. Adaptive execution — tries subagents in parallel (one per event group), falls back to direct mode on resource_exhausted. Four-step workflow with plan.md tracking and def-done.md verification. Orchestrates bi-catalog-mcp and eventor-mcp servers. Use when the user says "implement BI events", "add BI tracking", "BI migration", "wire BI", "bi-schema-loggers", or provides an events array or Eventor sessionId.
compatibility: Requires bi-catalog-mcp and eventor-mcp MCP servers. Designed for yoshi-flow-bm React projects with @wix/bi-logger-* packages.
---

# Implement BI Events

End-to-end BI event implementation for Wix React projects using bi-schema-loggers.

## Execution Strategy

**Parallel subagents by default.** Do NOT self-justify choosing direct mode — "I prefer direct mode" or "more control" are never valid reasons.

1. After Step 2 → ask user for parallelism strategy (fast / moderate / conservative)
2. Identify task dependencies (events targeting same component/hook → same group)
3. Independent groups → dispatch subagents in parallel (batch size per strategy)
4. Dependent groups → process sequentially
5. resource_exhausted at runtime → fall back to direct mode

Strategy limits:

- **Fast**: up to 8 total subagents (ceiling, not target), 4 concurrent, fine-grained: 1–2 events each
- **Moderate**: ~half of fast total, 4 concurrent, grouped: 3–4 events per subagent
- **Conservative**: ~quarter of fast total, 3 concurrent, aggressively grouped: many events per subagent

## Prerequisites

**MCP servers required:**

- `bi-catalog-mcp` — `bi-catalog-mcp:get_evid_schema` fetches event schemas
- `eventor-mcp` — `eventor-mcp:listSessionFeatures` and `eventor-mcp:getImplementationFlow` extract events from sessions

> **IMPORTANT**: Config must be at the **workspace root** (the directory you opened in Cursor/Claude Code). A config nested inside a subdirectory (e.g., `packages/app/.cursor/mcp.json`) is NOT picked up by Cursor.
>
> **Cursor** — add to `<workspace-root>/.cursor/mcp.json`:
> ```json
> { "bi-catalog-mcp": { "url": "https://bo.wix.com/_serverless/bi-catalog-mcp/mcp/" } }
> ```
> **Claude Code** — add to `<workspace-root>/.mcp.json`:
> ```json
> { "mcpServers": { "bi-catalog-mcp": { "url": "https://bo.wix.com/_serverless/bi-catalog-mcp/mcp/" } } }
> ```

**Official references:**
- [bi-schema-loggers](https://github.com/wix-private/bi-schema-loggers) | [BI Handbook](https://github.com/wix-private/fed-handbook/blob/master/BI.md) | [BI Catalog](https://bo.wix.com/data-tools/bi-catalog-app) | [#bi-logger-support](https://wix.slack.com/archives/CS9BG540L)

## Input

The user provides **one of**:

1. **`events` array** — list of `EventorOutput` objects (see below)
2. **`sessionId`** (GUID) — extract events automatically via Eventor MCP

If neither is provided, ask before proceeding.

```typescript
type StaticProperty = { name: string; value: string };
type DynamicProperty = { name: string; description: string };

type EventorOutput = {
  evid: string;
  src: string;
  description: string;     // Detailed interaction description
  interaction: string;      // User interaction name
  implementationFlow?: string;
  staticProperties: StaticProperty[];
  dynamicProperties: DynamicProperty[];
};
```

**Debug mode**: If `--debug` in user prompt, keep intermediate JSON files after completion.

---

## Step 0 — MCP Gate (MANDATORY, DO NOT SKIP)

**Before anything else**, validate that `bi-catalog-mcp` is available. This is the ONLY way to fetch event schemas. There is NO manual alternative, NO workaround, NO fallback. Do NOT proceed without it.

Call `bi-catalog-mcp:get_evid_schema` with a known event (src: 61, evid: 1).

**If the call succeeds** → continue to Step 1. Do NOT ask any other questions yet.

**If the call fails** (tool not found, server error, not configured):

1. **STOP immediately.** Do NOT continue to Step 1. Do NOT ask about parallelism. Do NOT start setup. Do NOT attempt any workaround or placeholder implementation.
2. Use the `AskQuestion` tool to present a clickable choice:
   - Title: "bi-catalog-mcp is not configured"
   - Prompt: "The bi-catalog-mcp server is required to fetch BI event schemas. There is no alternative. How would you like to proceed?"
   - Option A: "Add it for me — add the MCP config to my project and continue"
   - Option B: "I'll do it myself — show me the setup steps"
3. **If A**: Add the `bi-catalog-mcp` entry to the MCP config at the **workspace root** (the directory Cursor/Claude Code was opened from). Cursor only reads `.cursor/mcp.json` from the workspace root and `~/.cursor/mcp.json` globally — a config nested inside a subdirectory (e.g., `packages/app/.cursor/mcp.json`) is **NOT picked up**.
   - Detect the workspace root (the top-level directory of the current session)
   - Cursor: add to `<workspace-root>/.cursor/mcp.json` (create if missing) → `{ "bi-catalog-mcp": { "url": "https://bo.wix.com/_serverless/bi-catalog-mcp/mcp/" } }`
   - Claude Code: add to `<workspace-root>/.mcp.json` (create if missing) → `{ "mcpServers": { "bi-catalog-mcp": { "url": "https://bo.wix.com/_serverless/bi-catalog-mcp/mcp/" } } }`
   - Re-validate the MCP call. Only continue to Step 1 if it succeeds.
4. **If B**: Show the config snippets above, emphasizing the file must be at the **workspace root** (not a nested package). **STOP. Wait for user to confirm** before continuing to Step 1.

**Do NOT** improvise, guess schemas, use manual approaches, skip this gate, or bundle this question with any other question.

---

## Step 1 — Setup

All one-time initialization. Runs once before any tasks are dispatched.

### 1.1 Event Extraction (only if sessionId provided)

1. Call `eventor-mcp:listSessionFeatures` with the `sessionId`
2. For each feature's BI events, call `eventor-mcp:getImplementationFlow`
3. Aggregate results into `events` array following the `EventorOutput` type
4. If extraction fails → ask user for events manually

### 1.2 Environment Check

1. **Detect existing BI packages** — `grep -r "@wix/bi-logger-" package.json packages/*/package.json`
2. **Detect testing framework** — Jest, Vitest, RTL
3. **Detect existing BI wrappers** — search for `use*Bi*` hooks, shared logger patterns

### 1.3 Fetch Event Schemas

For each event, call `bi-catalog-mcp:get_evid_schema({ src, evid })` — use parallel fetching. Extract:

- `functionName` — the event builder function
- `schemaLoggers` — available logger packages
- `fields` — field definitions (name, type, required, description)

Use `schemaLoggers[0]` as preferred logger unless project already uses a different one.

### 1.4 Install Logger Package & Validate Functions

If not already installed: `yarn add @wix/[logger-name]`. See [logger-setup.md](references/logger-setup.md).

**Validate every function name** from the schemas exists in the package:

```bash
grep -r "${functionName}" node_modules/@wix/${loggerPkg}/dist/types/
```

If function missing → `yarn up @wix/${loggerPkg}`. If still missing after update → check for typos, verify evid/src, escalate to [#bi-logger-support](https://wix.slack.com/archives/CS9BG540L).

### 1.5 Determine Wiring Strategy

**Priority order (CRITICAL):**

| Priority | Strategy | When |
|----------|----------|------|
| 1st | **Extend existing shared hook** | Project has `useSharedBi` or similar |
| 2nd | **Component wrapper** using shared hook | Shared infrastructure exists |
| 3rd | **Standalone hook** (last resort) | No shared infrastructure |

### 1.6 Component Mapping

For each event, find the target component:

1. Use `interaction` + `description` for semantic search in `src/`
2. Identify trigger points (onClick, onSubmit, etc.) matching the `interaction`
3. If found → record `{ path, confidence, triggerContext }`
4. **If not found** → generate diagnostics before flagging:
   - Directories scanned (e.g., `src/`, `packages/`)
   - Alternative search terms: interaction verb, first 3 words of description, `${interaction.split(' ')[0]} handler`
   - Troubleshooting tips: check non-standard directories, split compound interactions, look for wrapper/container components
   - Try each alternative term before giving up
   - Only flag for manual wiring if all alternatives fail — include the diagnostics in the flag so the user has actionable next steps

### 1.7 Field Mapping

Classify **every** field with a source **during analysis** — do not defer to subagents.

- **Static** — constants from `staticProperties`. Centralize in a `BI_CONSTANTS` object (use existing constants file or create one). Never hardcode static values at each call site.
- **Dynamic** — for each `dynamicProperty`, commit to a source:
  - `props` — passed from parent component
  - `state` — local component state (useState, useReducer)
  - `context` — React context or hook (useParams, useSelector, etc.)
  - `computed` — derived at call site from other values
  - Record the `inferredValue` (e.g., `props.menuId`, `state.selectedItems.length`)
- **Missing** — required schema fields with no identifiable source → flag with field name, type, and suggested resolution

This classification is passed to subagents so they wire fields correctly instead of guessing.

---

## Step 2 — Plan

### 2.1 Group Events by Target

Group events that share the **same component** or **same shared hook** into a single task. Events targeting different components are independent tasks.

### 2.2 Generate plan.md

```markdown
# BI Implementation Plan

| # | Task | Events (evid/src) | Component | Status |
|---|------|--------------------|-----------|--------|
| 1 | Wire [interaction] into [Component] | evid:X src:Y | path/to/Component.tsx | pending |
| 2 | Wire [interaction] into [Component] | evid:X src:Y | path/to/Component.tsx | pending |
```

### 2.3 Generate def-done.md

```markdown
# Definition of Done

- [ ] Every event has a `report[EventName]` function in a BI hook file
- [ ] All imports use `/v2` paths (tree-shakable)
- [ ] All type imports use `/v2/types` paths
- [ ] Every event's BI call is wired into the correct component at the correct trigger point
- [ ] BI calls fire on actual described flow (after success, not before action)
- [ ] All required BI fields are propagated through component tree
- [ ] Every dynamic field has a committed source (props/state/context/computed)
- [ ] Static properties centralized in BI_CONSTANTS (not hardcoded at call sites)
- [ ] Testkit imported BEFORE component import in every test file
- [ ] Testkit reset in beforeEach
- [ ] Every event has a test assertion (own file or nearest ancestor test that renders the component)
- [ ] Per-interaction validation: each event individually verified with path:line evidence
- [ ] All tests pass (`yarn test`)
- [ ] Lint clean (`yarn lint`)
- [ ] TypeScript clean (`yarn tsc --noEmit`)
- [ ] No broken imports or missing dependencies
```

### 2.4 Create TodoWrite Entries

One entry per task from plan.md.

### 2.5 Ask Parallelism Strategy

Use the `AskQuestion` tool to present a clickable choice (do NOT bundle with any other question):
- Title: "Parallelism Strategy"
- Prompt: "How should events be processed?"
- Option A: "Fast — up to 8 subagents, 1-2 events each, fastest completion"
- Option B: "Moderate — ~half as many subagents, 3-4 events each, balanced"
- Option C: "Conservative — fewest subagents, many events each, lowest cost"

---

## Step 3 — Execute (Adaptive)

**Parallel subagents by default.** Only fall back to direct mode when: (a) subagent fails with `resource_exhausted`, or (b) tasks genuinely depend on each other's output.

### Per batch

1. Select pending independent tasks from plan.md (batch size per strategy)
2. Group tasks per subagent according to strategy granularity
3. Dispatch event-processor subagents — see [prompts/event-processor-prompt.md](prompts/event-processor-prompt.md)
4. Wait for all subagents in batch to complete
5. Dispatch event-reviewer subagents in parallel — see [prompts/event-reviewer-prompt.md](prompts/event-reviewer-prompt.md)
6. Fix issues: processor fix → reviewer re-review → repeat until approved
7. Update plan.md and TodoWrite

### What each processor does (per event)

1. Create/extend BI hook with `report[EventName]` method
2. Wire hook into target component at correct trigger point
3. Propagate missing BI fields through component tree
4. Add BI test assertions (see testing rules below)
5. Self-review before reporting

See [implementation-patterns.md](references/implementation-patterns.md) for import rules, wiring patterns, and field propagation. See [testing-guide.md](references/testing-guide.md) for full testkit API and assertion patterns.

### Testing Rules (inline — do not skip)

These 4 rules are non-negotiable. Do NOT rely solely on the reference file.

1. **Import order**: testkit BEFORE component import (required for mocking to work)
2. **Reset**: `biTestKit.reset()` in `beforeEach` (prevents event leakage between tests)
3. **Event name pattern**: `biTestKit.{eventNameCamelCase}Src{src}Evid{evid}` — e.g., `biTestKit.menuUpdatedSrc61Evid180`
4. **Test file selection**:
   - **Has own test file** → enhance it
   - **No test file but parent renders this component** → add BI assertion in the nearest ancestor test file that renders it (e.g., test `EmptyState` BI from `MenusLobby.spec.tsx` if that's where it's rendered)
   - **No test file and no parent test renders it** → skip and flag as `missing_test_coverage`
   - **NEVER** create isolated BI-only test files

### Direct Mode (fallback)

Only use when: (a) subagent failed with `resource_exhausted`, or (b) tasks are genuinely dependent. Process remaining tasks sequentially with same logic and quality checks.

---

## Step 4 — Verify

Dispatch the def-done verifier — see [prompts/def-done-verifier-prompt.md](prompts/def-done-verifier-prompt.md).

### 4.1 Per-Interaction Validation

For EACH event individually (not a single pass/fail for the whole project), verify and record:

1. `report[EventName]` function exists in hook file → record `hookPath:line`
2. BI call exists in component at correct trigger → record `componentPath:line`
3. Test assertion exists → record `testPath:line`
4. Test passes when run → record pass/fail

**Status per event**: `complete` | `missing-implementation` | `missing-tests` | `failed`

Report must list each event with its status, paths, and line numbers. A flat "all tests pass" without per-event evidence is not acceptable — it hides skipped interactions.

### 4.2 Full QA

```bash
yarn test --testNamePattern="BI" --verbose
yarn lint ${allModifiedFiles}
yarn tsc --noEmit
```

### 4.3 def-done.md Check

Verify every criterion. Fix gaps → re-verify → loop until PASS.

### 4.4 Cleanup & Summary

Delete all intermediate files created during execution:

- `plan.md`, `def-done.md`, `wixify-analysis.json`, `wixify-implementation.json`
- **`--debug`**: Keep all intermediate files
- **On error**: Keep all intermediate files

After cleanup, present this summary (the only output the user sees):

```markdown
## BI Implementation Summary

**Events**: [N] implemented, [N] skipped
**Logger**: @wix/bi-logger-[name]

| Event | EVID | SRC | Component | Status |
|-------|------|-----|-----------|--------|
| [interaction] | [evid] | [src] | `path/to/file.tsx` | done |
| [interaction] | [evid] | [src] | — | skipped: [reason] |

**Files modified**: [list of changed files]
**Validation**: tests pass | lint clean | types clean
**Next steps**: [any manual TODOs, or "None"]
```

---

## Subagent Dispatch

When dispatching subagents, follow these rules:

- **Never paste full schema or reference file content** — provide event details, file paths, and key data inline
- **Parallel limit**: max 4 subagents at once
- **Provide full task text** — do NOT tell subagents to read plan.md
- **Check results** — after each batch, verify files were modified before marking completed
- **Subagents cannot spawn subagents** — the orchestrator (this skill, running in the main conversation) dispatches all subagents

### Claude Code (native agents)

Uses `.claude/agents/bi-*` agents: `bi-event-processor` (bypassPermissions, inherit model), `bi-event-reviewer` (haiku, read-only), `bi-verifier` (sonnet, read-only).

**CRITICAL**: Event-processors must use `bypassPermissions` — background agents auto-deny permissions, so `acceptEdits` causes silent write failures. Dispatch up to 4 per batch in background. After each batch, verify files were modified (`git status`) before marking completed. Re-dispatch in foreground if unchanged.

### Cursor (Task tool)

Uses `Task` tool with prompt templates from `prompts/`:
- **event-processor-prompt.md** → `subagent_type: "generalPurpose"` (needs write access)
- **event-reviewer-prompt.md** → `subagent_type: "generalPurpose"`, `readonly: true`
- **def-done-verifier-prompt.md** → `subagent_type: "generalPurpose"`, `readonly: true`

---

## Red Flags

**Never:**

- Skip reviews (reviewer AND verifier are both required)
- Skip re-review after fixes (issues found = fix = review again)
- Start verification before all tasks are processed
- Accept "close enough" (issues found = not done)
- Leave tasks as `pending` without processing or skipping
- Choose direct mode for preference ("more control" is not valid)
- Make subagent read plan file (provide full task text instead)
- Skip self-review in processor (both self-review and external review are needed)
- Default to 8 subagents just because "fast" was selected (8 is the ceiling)
- Skip asking the user for parallelism strategy (always ask before dispatch)

## Error Handling

- **Task failure**: Skip task, mark as skipped in plan.md, continue
- **Subagent resource_exhausted**: Switch to direct mode for remaining tasks
- **Verification failure**: Fix gaps, re-verify (loop until PASS)
- **Missing packages**: Attempt one auto-install and retry
- **MCP failure**: Reference [troubleshooting.md](references/troubleshooting.md) for resolution

## Progress Emoji

| Phase | Emoji | Example |
|-------|-------|---------|
| Analysis | `🔍` | "Fetched schemas — resolved 3 logger functions" |
| Plan | `📋` | "Generated plan with 5 events in 3 groups" |
| Implementation | `⚙️` | "Created hook and wired into component" |
| Review | `🔎` | "Reviewer approved 2/3, 1 needs fixes" |
| Testing | `🧪` | "Generated tests, all green" |
| Success | `✅` | "BI implementation complete" |
| Cleanup | `🧹` | "Intermediate files cleaned" |
| Debug | `🐛` | "Keeping intermediate files" |
| Error | `⚠️` | "Phase X failed — [details]" |
