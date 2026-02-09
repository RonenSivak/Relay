---
name: implement-bi
description: Implements Wix BI tracking events end-to-end in yoshi-flow-bm React projects using bi-schema-loggers. Four-phase workflow covering event extraction, schema analysis, hook and component integration, and testing with validation. Orchestrates bi-catalog-mcp and eventor-mcp servers. Use when the user says "implement BI events", "add BI tracking", "BI migration", "wire BI", "bi-schema-loggers", or provides an events array or Eventor sessionId.
compatibility: Requires bi-catalog-mcp and eventor-mcp MCP servers. Designed for yoshi-flow-bm React projects with @wix/bi-logger-* packages.
---

# Implement BI Events

End-to-end BI event implementation for Wix React projects using bi-schema-loggers.

## Prerequisites

**MCP servers required:**
- `bi-catalog-mcp` — `bi-catalog-mcp:get_evid_schema` fetches event schemas
- `eventor-mcp` — `eventor-mcp:listSessionFeatures` and `eventor-mcp:getImplementationFlow` extract events from sessions

> If these aren't configured, add them to `.cursor/mcp.json`:
> ```json
> { "bi-catalog-mcp": { "url": "https://bo.wix.com/_serverless/bi-catalog-mcp/mcp/" } }
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

## Execution Flow

Execute phases sequentially. Each must succeed before the next.

Copy this checklist and track progress:

```
Phase Progress:
- [ ] Phase 0: Event extraction (if sessionId provided)
- [ ] Phase 1: Analysis & setup (schemas, loggers, component mapping)
- [ ] Phase 2: Implementation & wiring (hooks, components, field propagation)
- [ ] Phase 3: Testing & validation (tests, per-interaction validation, QA)
- [ ] Cleanup: Remove intermediate files (unless --debug)
```

### Phase 0: Event Extraction (only if sessionId provided)

1. Call `eventor-mcp:listSessionFeatures` with the `sessionId`
2. For each feature's BI events, call `eventor-mcp:getImplementationFlow` with `session_id`, `feature_id`, `user_interaction`
3. Aggregate results into `events` array following the `EventorOutput` type
4. If extraction fails → ask user for events manually

### Phase 1: Analysis & Setup

**Goal**: Fetch schemas, detect/install loggers, map events to components, plan field mappings.

#### 1.0 Environment Check

1. **Validate BI Catalog MCP** — test with `bi-catalog-mcp:get_evid_schema` using a known event (src: 61, evid: 1)
2. **Detect existing BI packages** — `grep -r "@wix/bi-logger-" package.json packages/*/package.json`
3. **Detect testing framework** — Jest, Vitest, RTL
4. **Detect existing BI wrappers** — search for `use*Bi*` hooks, shared logger patterns

#### 1.1 Fetch Event Schemas

For each event, call `bi-catalog-mcp:get_evid_schema({ src, evid })` — use parallel fetching. Extract:
- `functionName` — the event builder function
- `schemaLoggers` — available logger packages
- `fields` — field definitions (name, type, required, description)

Use `schemaLoggers[0]` as preferred logger unless project already uses a different one.

#### 1.2 Install Logger Package

If not already installed: `yarn add @wix/[logger-name]`

Verify function exists in package types. See [logger-setup.md](references/logger-setup.md) for details.

#### 1.3 Component Mapping

For each event, find the target component:
1. Use `interaction` + `description` for semantic search in `src/`
2. Identify trigger points (onClick, onSubmit, etc.) matching the `interaction`
3. If not found → flag for manual wiring with diagnostic info

#### 1.4 Field Mapping

Separate fields into:
- **Static** — constants from `staticProperties` (name → value)
- **Dynamic** — inferred from component props/state/context using `dynamicProperties` descriptions
- **Missing** — flag required fields that need manual implementation

#### 1.5 Save Analysis

Write `wixify-analysis.json` with all schema results, component mappings, field plans, and environment info.

**Phase 1 success**: All schemas fetched, loggers identified, components mapped, fields planned.

---

### Phase 2: Implementation & Wiring

**Goal**: Create/extend BI hooks, integrate into components, propagate fields.

See [implementation-patterns.md](references/implementation-patterns.md) for full pattern details.

#### 2.1 Choose Wiring Strategy

**Priority order (CRITICAL):**

| Priority | Strategy | When |
|----------|----------|------|
| 1st | **Extend existing shared hook** | Project has `useSharedBi` or similar |
| 2nd | **Component wrapper** using shared hook | Shared infrastructure exists |
| 3rd | **Standalone hook** (last resort) | No shared infrastructure |

#### 2.2 Generate/Extend BI Hooks

- Import from `/v2` path (tree-shakable): `import { fnName } from '@wix/bi-logger-xxx/v2'`
- Import types from `/v2/types`: `import type { fnNameParams } from '@wix/bi-logger-xxx/v2/types'`
- Create `report[EventName]` method wrapping `biLogger.report(fnName(params))`

#### 2.3 Component Integration

1. Add hook import to component
2. Initialize hook: `const { reportEventName } = useHook()`
3. Wire BI call at the correct trigger point — ensure it fires on the **actual described flow** (after creation, edit, deletion, etc.)

#### 2.4 Field Propagation

**CRITICAL**: Trace component tree to ensure ALL BI fields reach the reporting point.
1. Add missing fields to component props interfaces
2. Update parent components to pass BI fields down
3. Map static properties to constants, dynamic to component data sources

#### 2.5 Validate Build

```bash
yarn lint ${modifiedFiles} && yarn tsc --noEmit
```

**Phase 2 success**: All hooks created, components integrated, fields propagated, build passes.

Output: `wixify-implementation.json`

---

### Phase 3: Testing & Validation

**Goal**: Generate tests, validate per-interaction, run QA.

See [testing-guide.md](references/testing-guide.md) for full testing patterns.

#### 3.1 Setup

Load Phase 2 results. Determine testkit import: `import biTestKit from '@wix/bi-logger-xxx/testkit/client'`

#### 3.2 Locate Existing Tests

**CRITICAL**: Always enhance existing test files. Never create isolated BI test files.

```bash
find . -name "*.spec.ts*" -o -name "*.test.ts*" | grep -E "(ComponentName)"
```

#### 3.3 Add BI Test Assertions

For each event, add test case:

```typescript
beforeEach(() => { biTestKit.reset(); });

it('should report [eventDescription] when [trigger]', async () => {
  // Render component, simulate interaction
  // Assert: biTestKit.eventName.last() contains expected fields
});
```

**Testkit API**: `.last()`, `.getAll()`, `.length`, `.reset()`

#### 3.4 Per-Interaction Validation

For EACH interaction, verify:
1. Function exists in BI hook file
2. BI call exists in component
3. Test exists and covers the interaction
4. Test passes when run

Generate validation report with status per interaction.

#### 3.5 Full QA

```bash
yarn test --testNamePattern="BI" --verbose
yarn lint ${allModifiedFiles}
yarn tsc --noEmit
```

**Phase 3 success**: All tests pass, lint clean, types clean, every interaction validated.

---

## Completion

### Cleanup

- **Default**: Delete `wixify-analysis.json` and `wixify-implementation.json`
- **`--debug`**: Keep intermediate files
- **On error**: Always keep intermediate files

### Summary Template

```
### BI Implementation Complete

**Events Implemented:**

1. **[Interaction]** (EVID: X, SRC: Y)
   - Implementation: `path/to/component.tsx:line`
   - Hook: `path/to/hook.ts:line`
   - Tests: `path/to/test.spec.tsx:line`
   - Status: Implemented & Tested

**Summary:**
- Total events: X | Implemented: X | Tested: X
- Files modified: X | Test files updated: X
- Logger: @wix/bi-logger-xxx
- Shared hooks extended: [list]

**Validation:**
- All tests passing | Lint clean | Types clean
- Per-interaction: X/X validated
```

---

## Progress Emoji

| Phase | Emoji | Example |
|-------|-------|---------|
| Analysis | `🔍` | "Fetched schemas – resolved 3 logger functions" |
| Implementation | `⚙️` | "Created hook and wired into component" |
| Testing | `🧪` | "Generated tests, all green" |
| Success | `✅` | "BI implementation complete" |
| Cleanup | `🧹` | "Intermediate files cleaned" |
| Debug | `🐛` | "Keeping intermediate files" |
| Error | `⚠️` | "Phase X failed – [details]" |

## Error Handling

1. Log error with phase context
2. Reference [troubleshooting.md](references/troubleshooting.md) for resolution
3. Create TODO items for manual resolution
4. **Auto-recovery**: For missing packages, attempt one auto-install and retry
5. Intermediate files kept on error for debugging
