---
name: sled3-testing
description: "Specialized Sled 3 E2E testing for Wix apps. Full lifecycle: detection, setup, test writing, debugging, visual regression, CI. Adaptive parallel subagents with plan.md/def-done.md. BDD drivers, interceptionPipeline, storybookPlugin. Use when user says sled3, sled-playwright, e2e test, visual regression, write e2e, debug e2e, or wants to add/fix/debug Sled 3 browser tests."
---

# Sled 3 Testing

Specialized E2E testing skill for Wix applications using **Sled 3** (`@wix/sled-playwright`). Covers the full lifecycle: detection, setup, writing, debugging, visual regression, and CI integration. Sled 3 only — no Sled 2 or standalone Playwright.

## MANDATORY RULES — Read Before Anything Else

These 3 rules are **non-negotiable**. Violating any means the run is invalid.

**1. USER CHOICE GATE (Phase A2):** After detection, MUST use `AskQuestion` to present available test types and let the user choose. NEVER auto-generate tests without user selection.

**2. CATCH-ALL API BLOCKING:** No test may make a real HTTP request. Use `interceptionPipeline.setup()` with a catch-all handler:

```typescript
const catchAll: InterceptHandler = {
  id: 'catch-all-api-block',
  pattern: /\/(api|_api)\//,
  handler: () => ({ action: InterceptHandlerActions.ABORT }),
};
// interceptionPipeline.setup([...specificMocks, catchAll])
```

**CRITICAL:** Never use `interceptors.push()` — it does NOT register routes. Always use `setup()`.

**3. TEST BUDGET:** 2-4 behavioral tests per component, 10-20 total hand-written. Each test: user interaction -> state change -> assertion. Tests that only check visibility are forbidden when snapshot tests exist.

## Execution Strategy

**Parallel subagents by default.** Do NOT self-justify choosing direct mode.

1. After Step 2 (Plan) — ask user for parallelism strategy
2. Identify task dependencies
3. Independent tasks — dispatch subagents in parallel (batch size per strategy)
4. Dependent tasks — process sequentially
5. `resource_exhausted` — fall back to direct mode

| Strategy | Max Subagents | Grouping |
|----------|--------------|----------|
| **Fast** | Up to 8 (ceiling) | 1-2 tasks each |
| **Moderate** | ~half of fast | 3-4 per subagent |
| **Conservative** | ~quarter of fast | Aggressive grouping |

Max concurrent subagents per batch: 4 (platform limit).

---

## Step 1: Setup

**MANDATORY**: Before writing tests, invoke `/brainstorming` to clarify:
1. What user flows need E2E coverage?
2. What environment will tests run against?
3. Is there existing E2E infrastructure?
4. Is Storybook available for visual regression?

Load project context, identify the target package, confirm the working directory.

## Step 2: Plan

### 2a. Scan for Candidates
Determine scope: writing new tests, debugging failures, or setting up infrastructure.

### 2b. Generate `plan.md`

```markdown
# E2E Testing Plan (Sled 3)
| # | Task | Type | Phase | Status |
|---|------|------|-------|--------|
| 1 | Detect infrastructure | detection | A | pending |
| 2 | Detect test patterns + storybook | detection | A | pending |
| 3 | **MANDATORY: User choice gate** | choice-gate | A2 | pending |
| 4 | **MANDATORY: Shared infra** — base driver with catch-all | infra | B1 | pending |
| 5 | Visual regression setup | visual-regression | B2 | pending |
| 6 | Full happy-flow test | full-flow | B3 | pending |
| 7 | Write tests: <feature> (budget: 2-4) | writing | B4 | pending |
| ... | ... | ... | ... | ... |

**STOP: Tasks 3 and 4 must complete before any writing tasks.**
```

### 2c. Generate `def-done.md`

```markdown
# Definition of Done

## Gate 1 — BDD Pattern Compliance
- [ ] Spec files: ZERO direct page.* calls — all via driver.when.*, driver.get.*, driver.given.*
- [ ] No raw selectors in specs — selectors live in drivers only
- [ ] No waitForTimeout in driver files — use waitFor, expect.poll, waitForLoadState
- [ ] Driver when.* methods return this (chainable)
- [ ] No conditional logic in spec files — tests must be deterministic

## Gate 2 — API / Communication Mocking
- [ ] Existing interception infrastructure reused (not reinvented)
- [ ] interceptionPipeline.setup() used (NEVER interceptors.push())
- [ ] Catch-all blocking with InterceptHandlerActions.ABORT in base driver
- [ ] Every API endpoint mocked via given.* — no real calls

## Gate 3 — Test Substance
- [ ] Every test: user interaction -> state change -> assertion on NEW state
- [ ] No visibility-only tests (navigate -> toBeVisible with no interaction)
- [ ] No empty assertions (click button -> no expect on the result)

## Gate 4 — Full-flow test (if selected)
- [ ] At least 1 test walks all steps of primary user journey
- [ ] Final assertion verifies end result (not intermediate visibility)

## Gate 5 — Budget and Scope
- [ ] User choice gate completed
- [ ] 2-4 tests per component, 10-20 total
- [ ] All tests pass locally (CI=false npx sled-playwright test)
- [ ] No lint errors in test files
```

### 2d. Ask Parallelism Strategy
Present fast / moderate / conservative via `AskQuestion`.

---

## Step 3: Execute (Adaptive)

### Phase A: Detection (2 parallel subagents)

| Subagent | Detects | Tools |
|----------|---------|-------|
| **Infrastructure** | @wix/sled-playwright in deps, playwright.config.ts, defineSledConfig, yoshi flow type | Read, Glob, Grep |
| **Patterns** | Existing test files, drivers, builders, storybook config, plugin setup | Read, Glob, Grep |

Use prompt from `prompts/detection-processor.md`.

**Infrastructure decision tree:**
```
@wix/sled-playwright in deps?
├── YES → Sled 3 confirmed
│   └── Has @wix/playwright-storybook-plugin? → Add visual regression option
└── NO → Wix project? → Recommend Sled 3 setup (see references/sled3-config.md)
```

Master combines reports into detection summary, then Phase A2.

### Phase A2: User Choice Gate (MANDATORY)

Present findings and ask what to implement via `AskQuestion`. **Never auto-implement.**

**Always available:**
- Behavioral tests per component (2-4 each)
- Full happy-flow test (primary user journey end-to-end)
- Error state tests (1 per critical error path)

**Conditional (only if detected):**
- Visual regression / snapshot tests (if storybook plugin detected)

**Always enforced (not a choice):**
- Catch-all API blocking in base driver
- BDD driver pattern

### Phase B1: Shared Infra (MANDATORY — master creates this)

**Do NOT dispatch writer subagents until this is done.**

Create or verify BDD scaffold:
```
__e2e__/
├── constants.ts              # BASE_URL, testUser
├── drivers/
│   └── app.driver.ts         # Navigation + given.* + CATCH-ALL via interceptionPipeline.setup()
└── builders/                 # Or src/test/builders/ if shared with unit
```

Catch-all pattern (see `references/sled3-interception.md` for full details):
```typescript
import { InterceptHandlerActions, type InterceptHandler } from '@wix/sled-playwright';

const catchAll: InterceptHandler = {
  id: 'catch-all-api-block',
  pattern: /\/(api|_api)\//,
  handler: () => ({ action: InterceptHandlerActions.ABORT }),
};
```

**Verification gate:** Grep base driver for `ABORT`. If not found, step is NOT done.

### Phase B2: Visual Regression (if user selected)

If storybook plugin detected:
1. Read `playwright.config.ts`, check `storiesToIgnoreRegex`
2. If regex is `['.*']`: fix to `['.*--docs$', '.*-playground$']`
3. Set `deleteOldTestFiles: true`
4. Run tests to generate snapshot files
5. See `references/sled3-storybook.md` for full plugin API

### Phase B3: Full Happy-Flow Test (if user selected)

1 test exercising the primary user journey end-to-end:
- Uses top-level app driver
- Navigates through all steps
- Mocks ALL API endpoints via given.* chain
- Verifies final state

### Phase B4: Per-Component Subagents (if user selected)

Each subagent receives: detection report, shared infra paths, test budget (2-4), mandatory API blocking requirement. Each creates:
- `feature.spec.ts` — 2-4 behavioral tests (NOT visibility)
- `drivers/page.driver.ts` — get.*/is.*/when.*/given.*
- `feature.builder.ts` — mock data factories (if needed)

Use prompt from `prompts/writer-processor.md`.

### Phase B5: Review

Dispatch reviewer subagents (one per feature) using `prompts/reviewer.md`.

### Phase C: Debugging (adaptive)

**Single failing test:** Debug sequentially in master.
**Multiple failing tests:** Dispatch one subagent per test using `prompts/debugger-processor.md`.

**Run commands:**

| Action | Command |
|--------|---------|
| Run all | `CI=false npx sled-playwright test 2>&1 \| tail -30` |
| Run one file | `CI=false npx sled-playwright test FILE 2>&1` |
| Filter by name | `CI=false npx sled-playwright test --grep "name"` |
| Update snapshots | `CI=false npx sled-playwright test --update-snapshots` |
| Remote (CI) | `sled-playwright test --remote` |
| View report | `npx sled-playwright show-report` |
| Detect flakiness | `sled-playwright detect-flakiness --repeat-count 20` |

**Working directory:** Package containing `playwright.config.ts`.
**Local crash fix:** Prefix with `CI=false` when `defineSledConfig()` fails locally.

### Direct Mode (fallback)

Only when: (a) `resource_exhausted`, or (b) tasks are genuinely dependent. "I prefer direct mode" is not valid.

---

## Step 4: Verify

1. Run all tests: `CI=false npx sled-playwright test`
2. Verify every criterion in `def-done.md`
3. Fix gaps -> re-verify -> loop until PASS
4. Dispatch verifier subagent using `prompts/verifier.md`

---

## Selector Strategy

| Priority | Selector | Example |
|----------|----------|---------|
| 1 | Role-based | `page.getByRole('button', { name: 'Submit' })` |
| 2 | Text-based | `page.getByText('Submit')` |
| 3 | Label-based | `page.getByLabel('Username')` |
| 4 | data-hook | `page.getByTestId('submit-btn')` |
| 5 | CSS (avoid) | `page.locator('.submit-btn')` |

**Wix convention:** `data-hook` via `use: { testIdAttribute: 'data-hook' }` in config.

## What to Test (and What NOT)

**E2E (DO):** Full user journeys, multi-step interactions, cross-component flows, error recovery.

**NOT E2E (unit/snapshot):** "renders", "is visible", "button enabled", "input accepts text", "data-hook exists", "child count".

## Tag Convention

Use `@tag` in test names with `--grep` for filtering:
```typescript
test('@smoke should load dashboard', async ({ page }) => { ... });
// Run: CI=false npx sled-playwright test --grep @smoke
```

## Parallel/Retry Quick Reference

```typescript
// playwright.config.ts via defineSledConfig
playwrightConfig: {
  fullyParallel: true,           // Run tests in parallel within files
  workers: process.env.CI ? 4 : 1, // Parallel workers
  retries: process.env.CI ? 2 : 0, // Retry failed tests in CI
  repeatEach: 1,                 // Repeat each test N times (flakiness detection)
}
```

## BDD Architecture Summary

| Driver Type | Methods | Stateful? |
|-------------|---------|-----------|
| **Base** (`app.driver.ts`) | `given.*`, `navigateTo*()`, `setup()`, `reset()` | Yes (interceptors) |
| **Page** (`page.driver.ts`) | `get.*`, `is.*`, `when.*` | No — pass page per method |
| **Builder** (`feature.builder.ts`) | `anItem()`, `aUser()` — partial overrides | No — stable defaults |
| **Spec** (`feature.spec.ts`) | Composes drivers, reads like docs | N/A |

Place builders in `src/test/builders/` — shared by unit + E2E.

## Subagent Dispatch

### Cursor (Task tool)

| Step | `subagent_type` | `readonly` | `model` |
|------|----------------|------------|---------|
| Detection | `"e2e-detection-processor"` | `true` | `"fast"` |
| Writer | `"e2e-writer-processor"` | — | — |
| Debugger | `"e2e-debugger-processor"` | — | — |
| Reviewer | `"e2e-reviewer"` | `true` | — |
| Verifier | `"e2e-verifier"` | `true` | — |

Use dedicated `subagent_type` values — do NOT use `"generalPurpose"`.

### Rules
- Never paste full reference files — provide paths and key context inline
- Max 4 concurrent subagents
- Provide full task text — do NOT tell subagents to read plan.md
- Verify files after each batch before marking completed

## Red Flags

**Never:**
- Skip reviews (reviewer AND verifier both required)
- Skip re-review after fixes
- Start verification before all tasks processed
- Choose direct mode for preference
- Make subagent read plan file
- Use `interceptors.push()` instead of `setup()`
- Use `"generalPurpose"` when dedicated type exists
- Default to 8 subagents (8 is ceiling, not default)
- Skip parallelism strategy question

## Error Handling

| Error | Fix |
|-------|-----|
| `defineSledConfig()` crash | Prefix with `CI=false` |
| Story not found | Rebuild storybook; IDs use export names (kebab-case) |
| Route aborted / unmocked API | Add mock via `given.*` in driver |
| Flaky tests | `detect-flakiness --repeat-count 20`; find root cause |
| Timeout | Check mocks return data; check page loads |
| `intercepted pointer events` | Overlay blocking — wait/dismiss |
| `storiesToIgnoreRegex: ['.*']` | Fix to `['.*--docs$', '.*-playground$']` |

## References (load on demand)

- `references/sled3-fixtures.md` — All 14 built-in fixtures with full API
- `references/sled3-interception.md` — InterceptionPipeline deep dive
- `references/sled3-config.md` — defineSledConfig + CLI reference
- `references/sled3-storybook.md` — Visual regression plugin
- `references/sled3-debugging.md` — Debug patterns and common issues
- `references/sled3-driver-patterns.md` — BDD templates + real examples
- `references/sled3-migration.md` — Sled 2 to Sled 3 migration
- `prompts/detection-processor.md` — Detection subagent prompt
- `prompts/writer-processor.md` — Writer subagent prompt
- `prompts/debugger-processor.md` — Debugger subagent prompt
- `prompts/reviewer.md` — Reviewer subagent prompt
- `prompts/verifier.md` — Verifier subagent prompt
