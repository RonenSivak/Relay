---
name: e2e-testing
description: End-to-end browser testing for Wix applications using Sled 3 (@wix/sled-playwright), Sled 2 (@wix/sled-test-runner), or standalone Playwright. Adaptive parallel subagents for detection, test writing, and debugging. Full lifecycle with BDD architecture (driver/builder/spec), Storybook visual regression, and plan.md + def-done.md verification. Use when asked to write E2E tests, debug failing E2E tests, set up E2E infrastructure, or when the user says "e2e", "sled", "browser test", "end to end", "playwright", "visual regression", or "storybook e2e".
---

# E2E Testing

## Overview

Write, run, debug, and maintain E2E browser tests for Wix applications. Supports Sled 3 (Playwright-based), Sled 2 (Puppeteer/Jest), standalone Playwright, and Storybook visual regression. Uses adaptive parallel subagents to offload detection, per-feature test writing, and multi-test debugging from the master context. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist.

## MANDATORY RULES -- Read Before Anything Else

These 3 rules are **non-negotiable**. Violating any of them means the entire run is invalid.

**1. USER CHOICE GATE (Phase A2):** After detection, you MUST use `AskQuestion` to present available test types and let the user choose. NEVER auto-generate tests without user selection. If your plan.md has no "User choice gate" task, your plan is wrong.

**2. CATCH-ALL API BLOCKING:** No test may make a real HTTP request. The approach depends on the detected framework:
- **Sled 3:** Use `interceptionPipeline` fixture. Add a catch-all handler with `InterceptHandlerActions.ABORT` at the end of the handlers array. Specific mocks (`INJECT_RESOURCE`) go before it. Use `test.use({ interceptors })` or `interceptionPipeline.setup([...mocks, catchAll])`.
- **Sled 2:** Use `InterceptionTypes.Handler` in the interceptors array passed to `sled.newPage()`. Catch-all goes LAST (FIFO -- first match wins). Return `InterceptionTypes.Actions.ABORT` for unmatched URLs.
- **Standalone Playwright:** Use `page.route('**/api/**', route => route.abort('blockedbyclient'))` registered FIRST (LIFO).
- **PostMessage apps (Storybook):** Use `page.addInitScript()` with a PostMessage interceptor. Mock all expected messages; unmocked messages should throw.
If BaseE2EDriver does not have this, add it in Step B1. See `references/e2e-driver-pattern.md` for complete code.

**3. TEST BUDGET:** 2-4 behavioral tests per component, 10-20 total hand-written. Each test must be: user interaction -> state change -> assertion. Tests that only check visibility ("is visible", "renders", "is enabled") are forbidden when snapshot tests exist. If you produce more than 20 hand-written tests, you are testing at the wrong level.

## Execution Strategy

**Parallel subagents by default.** Do NOT self-justify choosing direct mode.

1. After Step 2 (Plan) -- ask user for parallelism strategy (fast / moderate / conservative)
2. Check if background execution is viable -- if yes, ask user for execution mode
3. Identify task dependencies
4. Independent tasks -- dispatch subagents in parallel (batch size per strategy)
5. Dependent tasks -- process sequentially
6. `resource_exhausted` at runtime -- fall back to direct mode

| Strategy | Max Subagents | Grouping | Trade-off |
|----------|--------------|----------|-----------|
| **Fast** | Up to 8 (ceiling) | Fine-grained: 1-2 tasks each | More tokens, faster |
| **Moderate** | ~half of fast | Group related: 3-4 per subagent | Balanced |
| **Conservative** | ~quarter of fast | Aggressive grouping | Fewest tokens, slowest |

Max concurrent subagents per batch: 4 (platform limit).

---

## Step 1: Setup

**MANDATORY**: Before writing E2E tests, invoke `/brainstorming` to clarify:

1. What user flows need E2E coverage?
2. What environment will tests run against?
3. Is there existing E2E infrastructure?
4. Is Storybook available for visual regression?

This step runs once. Load project context, identify the target package, and confirm the working directory.

## Step 2: Plan

### 2a. Scan for Candidates

Determine what needs to be done: writing new tests (which features?), debugging failures (which tests?), or setting up infrastructure.

### 2b. Generate `plan.md`

```markdown
# E2E Testing Plan
| # | Task | Type | Phase | Status |
|---|------|------|-------|--------|
| 1 | Detect infrastructure | detection | A | pending |
| 2 | Detect yoshi flow | detection | A | pending |
| 3 | Detect test patterns | detection | A | pending |
| 4 | Detect storybook | detection | A | pending |
| 5 | **MANDATORY: User choice gate** -- present options via AskQuestion, wait for selection | choice-gate | A2 | pending |
| 6 | **MANDATORY: Shared infra** -- base driver with catch-all route.abort for /api/** | infra | B1 | pending |
| 7 | Audit storiesToIgnoreRegex + configure visual regression | visual-regression | B2 | pending |
| 8 | Write full happy-flow test (primary user journey) | full-flow | B3 | pending |
| 9 | Write tests: <feature-1> (budget: 2-4) | writing | B4 | pending |
| ... | ... | ... | ... | ... |

**STOP: Tasks 5 and 6 are MANDATORY and must complete before any writing tasks.**
Tasks 7-9+ are conditional -- only include tasks the user selected in the choice gate (task 5).
```

### 2c. Generate `def-done.md`

```markdown
# Definition of Done

## Gate 1 -- BDD Pattern Compliance
- [ ] Spec files contain ZERO direct `page.*` or `driver.page.*` calls -- all access via `driver.when.*`, `driver.get.*`, `driver.given.*`
- [ ] No raw selectors in specs (`[data-hook=...]`, `.css-class`, `locator(...)`) -- selectors live in drivers only
- [ ] No `waitForSelector`, `waitForTimeout`, or `page.evaluate` in spec files
- [ ] No `waitForTimeout` in driver files (use `waitFor`, `expect.poll`, `waitForLoadState`)
- [ ] Driver `when.*` methods return `this` (chainable)
- [ ] No conditional logic (`if/else`) in spec files -- tests must be deterministic

## Gate 2 -- API / Communication Mocking
- [ ] Existing interception infrastructure discovered and reused (not reinvented)
- [ ] Framework-correct mocking: `interceptionPipeline` (Sled 3), `InterceptionTypes.Handler` (Sled 2), `page.route` (Playwright), `addInitScript` + existing interceptor (PostMessage)
- [ ] Catch-all blocking in base driver `setup()` (grep for `ABORT` or `route.abort`)
- [ ] Every API/message endpoint is mocked via `given.*` -- no real calls
- [ ] No custom `page.evaluate()` to simulate events when an interceptor already exists

## Gate 3 -- Test Substance
- [ ] Every test has: user interaction -> state change -> assertion on the NEW state
- [ ] No visibility-only tests (navigate -> `toBeVisible` with no prior interaction)
- [ ] No empty assertions (click button -> no `expect` on the result)
- [ ] No tests that only assert "renders" or "is visible" -- snapshots cover that

## Gate 4 -- Full-flow test (if user selected)
- [ ] At least 1 test walks through ALL steps of the primary user journey
- [ ] Test covers: first step -> interaction -> next step -> ... -> final state
- [ ] Final assertion verifies end result (not intermediate visibility)

## Gate 5 -- Budget and Scope
- [ ] User choice gate completed: user selected which test types to implement
- [ ] Test budget: 2-4 per component, 10-20 total hand-written
- [ ] Each spec file has 2-4 tests max
- [ ] No storybook snapshot duplicates (if visual regression selected)
- [ ] All tests pass locally (run command per detected framework)
- [ ] No lint errors in test files
```

### 2d. Ask Parallelism Strategy

Present fast / moderate / conservative options per the Execution Strategy section above.

---

## Step 3: Execute (Adaptive)

### Phase A: Detection (4 parallel subagents)

Dispatch 4 detection subagents in parallel. Each returns a structured JSON report.

| Subagent | Detects | Tools | Optional MCP |
|----------|---------|-------|-------------|
| **Infrastructure Detector** | Sled 3/2/Playwright deps, config files | Read, Glob, Grep | wix-internal-docs |
| **Framework Detector** | Yoshi flow type, test dir, run command | Read, Glob | wix-internal-docs |
| **Pattern Detector** | Existing test files, style conventions | Read, Glob, Grep | -- |
| **Storybook Detector** | .storybook/, stories, plugin config | Read, Glob | -- |

Use prompt templates from `prompts/detection-processor.md`.

**Infrastructure decision tree:**
```
E2E infrastructure found?
+-- @wix/sled-playwright --> Sled 3 (Playwright-based)
|   +-- Has Storybook? --> Add @wix/playwright-storybook-plugin
+-- @wix/sled-test-runner v2.x --> Sled 2 (Puppeteer/Jest)
+-- @playwright/test (no sled) --> Standalone Playwright
+-- Nothing --> Wix project? --> Sled 3 (recommended) / Non-Wix --> Playwright
```

**Yoshi flow mapping:**

| Yoshi Flow | E2E Framework | Config | Test Dir | Run Command |
|------------|--------------|--------|----------|-------------|
| **flow-bm** | Sled 3 | `playwright.config.ts` | `e2e/` | `sled-playwright test` |
| **flow-editor** | Sled 2 | `sled/sled.json` | `sled/` | `sled-test-runner remote` |
| **fullstack** | Jest + Puppeteer | `jest-yoshi.config.js` | `__tests__/*.e2e.ts` | `yoshi test --e2e` |
| **flow-library** | No E2E (unit only) | N/A | N/A | N/A |
| **Non-Yoshi** | Sled 3 | `playwright.config.ts` | `tests/e2e/` | `sled-playwright test` |

**Detect:** `package.json` --> `wix.framework.type` or `devDependencies` for `@wix/yoshi-flow-*`.

Master combines all 4 reports into a detection summary, then proceeds to Phase A2.

### Phase A2: User Choice Gate (MANDATORY)

After detection, present findings and ask the user what to implement. **NEVER auto-implement any test type.**

Use `AskQuestion` to present options based on what was detected:

**Always available options:**
- **Behavioral tests per component** -- 2-4 tests per component (interaction -> state change)
- **Full happy-flow test** -- 1 test walking through the primary user journey end-to-end
- **Error state tests** -- 1 test per critical error path (API failure -> error UI)

**Conditional options (only if detected):**
- **Visual regression / snapshot tests** -- (shown only if `@wix/playwright-storybook-plugin` or Storybook detected) Auto-generated screenshot tests for all stories. Replaces manual "should render" / "is visible" tests.

**Always enforced (not a choice -- infrastructure):**
- Catch-all API blocking in base driver (mandatory for all tests, not optional)
- BDD driver pattern (mandatory architecture)

Example `AskQuestion` prompt:
```
I detected the following in your project:
- Framework: Sled 3 (@wix/sled-playwright)
- Storybook: Yes, with @wix/playwright-storybook-plugin
- Components: ComponentA, ComponentB, ComponentC
- storiesToIgnoreRegex issue: ['.*'] disables ALL snapshot tests

Which test types would you like me to implement?
☐ Visual regression (snapshot tests) -- fix storiesToIgnoreRegex + auto-generate
☐ Full happy-flow test -- end-to-end primary user journey
☐ Per-component behavioral tests (2-4 each)
☐ Error state tests
```

Only proceed with the selected options. Update plan.md to include only the chosen task types. Skip unselected types entirely.

**Framework setup (if new):**
- Sled 3: See `references/sled-testing.md`
- Standalone Playwright: See `references/playwright-testing.md`
- Storybook visual regression: See `references/storybook-sled.md`

### Phase B: Writing (only selected test types)

**Step B1 -- MANDATORY: Master creates shared infrastructure** (ALWAYS -- regardless of user selection):

**DO NOT dispatch any writer subagents until this step is complete.**

If existing base driver exists, verify it has catch-all API blocking. If it doesn't, ADD IT NOW. If no existing tests, master creates BDD shared infra:

```
__e2e__/
+-- constants.ts              # BASE_URL, testUser
+-- drivers/
|   +-- app.driver.ts         # Navigation + given.* (API setup) + CATCH-ALL API BLOCK
+-- builders/                 # Or src/test/builders/ if shared with unit
```

The catch-all pattern depends on the detected framework:

**Sled 3** -- use `interceptionPipeline` (NOT `page.route`):
```typescript
// Catch-all handler -- add LAST in the handlers array
const catchAll: InterceptHandler = {
  id: 'catch-all-api-block',
  pattern: /\/(api|_api)\//,
  handler: () => ({ action: InterceptHandlerActions.ABORT }),
};
// In setup: interceptionPipeline.setup([...specificMocks, catchAll])
```

**Sled 2** -- use `InterceptionTypes.Handler` (catch-all goes LAST in FIFO array):
```typescript
const catchAll: InterceptionTypes.Handler = {
  execRequest: ({ url }) => url.match(/\/(api|_api)\//)
    ? { action: InterceptionTypes.Actions.ABORT }
    : { action: InterceptionTypes.Actions.CONTINUE },
};
// Pass to sled.newPage({ interceptors: [...specificMocks, catchAll] })
```

See `references/e2e-driver-pattern.md` for complete base driver templates per framework.

**Verification gate:** Before proceeding to B2/B3/B4, grep the base driver for `ABORT`. If not found, this step is NOT done.

**Step B2 -- Visual regression setup (ONLY if user selected "Visual regression"):**

If Storybook detected with `@wix/playwright-storybook-plugin`:
1. Read `playwright.config.ts` and check `storiesToIgnoreRegex`
2. If regex is `['.*']` or matches all stories: fix to `['.*--docs$', '.*-playground$']`
3. Set `deleteOldTestFiles: true`
4. Run tests once to generate snapshot test files
5. Verify snapshot tests exist in the output directory

This single step replaces the need for ANY manual "should render" or "is visible" tests. Mark as done in plan.md.

**Step B3 -- Full happy-flow test (ONLY if user selected "Full happy-flow test"):**

Write at least 1 test that exercises the primary user journey end-to-end. This test:
- Uses the top-level app driver (e.g., wizard driver, dashboard driver)
- Navigates through all steps: step 1 -> step 2 -> ... -> final step
- Verifies the final state (success screen, confirmation, result)
- Mocks ALL API endpoints it touches via the driver's `given.*` chain
- Is the highest-value E2E test in the suite

**Step B4 -- Dispatch per-component subagents (ONLY if user selected "Per-component behavioral tests"):**

Each subagent receives: detection report, shared infra paths, **test budget (2-4 tests max)**, and the **mandatory API blocking requirement**. Each creates:
- `feature.spec.ts` -- 2-4 behavioral tests (NOT visibility tests). All API calls mocked via `given.*`.
- `drivers/page-name.driver.ts` -- get.*/is.*/when.* for behavior testing. `given.*` for API mocking.
- `feature.builder.ts` -- mock data factories (if needed for error states)

Use prompt templates from `prompts/writer-processor.md`.

**Critical instructions for subagents**:
- If storybook snapshot tests exist (user selected visual regression), do NOT write "should render" / "is visible" tests
- Focus ONLY on user interactions that cause state changes
- ALL API endpoints hit by the component MUST be mocked via `given.*` -- the catch-all blocks everything else

**Step B4b -- Error state tests (ONLY if user selected "Error state tests"):**
- 1 test per critical error path (API failure -> error UI, empty state)
- Can be added to existing per-component specs or as a separate spec

**Step B5 -- Review:** Dispatch reviewer subagents (one per feature) using `prompts/reviewer.md`. Reviewer now checks for test bloat and API blocking (see reviewer changes).

For complete code examples by framework (Sled 3, Sled 2, standalone Playwright), see `references/e2e-driver-pattern.md`.

**Test budget (applies to whatever is selected):**
- Per component: 2-4 behavioral tests (interaction -> state change, NOT visibility)
- Full-flow: 1-2 tests (primary user journey end-to-end)
- Error states: 1 per critical error path
- Total hand-written: 10-20 for a typical project
- Auto-generated snapshots: unlimited (plugin handles these)
- Exceeding 5 tests for one component? STOP -- you're likely testing visibility, not behavior.

### Phase C: Debugging (adaptive)

**Single failing test:** Debug sequentially in master (interactive investigation).

**Multiple failing tests:** Dispatch one subagent per test using `prompts/debugger-processor.md`. Each subagent:
1. Runs the test using the detected framework's run command (see run commands below)
2. Reads error output -- line, assertion, stack
3. Categorizes using the debug table
4. Applies fix or reports what's needed

Optional: subagents can use octocode MCP for code navigation (LSP goto definition, call hierarchy) to understand the code under test.

**Run commands by framework:**

| Action | Sled 3 (Playwright) | Sled 2 (Puppeteer/Jest) | Standalone Playwright |
|--------|--------------------|-----------------------|----------------------|
| Run all | `CI=false npx sled-playwright test 2>&1 \| tail -30` | `npx sled-test-runner 2>&1 \| tail -30` | `npx playwright test 2>&1 \| tail -30` |
| Run one file | `CI=false npx sled-playwright test FILE 2>&1` | `npx sled-test-runner --testPathPattern="FILE"` | `npx playwright test FILE` |
| Filter by name | `CI=false npx sled-playwright test --grep "name"` | `npx sled-test-runner --testPathPattern="name"` | `npx playwright test --grep "name"` |
| Update snapshots | `CI=false npx sled-playwright test --update-snapshots` | N/A | `npx playwright test --update-snapshots` |
| CI / remote | `sled-playwright test --remote` | `npx sled-test-runner remote` | N/A |
| View report | `npx sled-playwright show-report` | N/A | `npx playwright show-report` |

**Working directory:** Run from the package directory containing `playwright.config.ts` (Sled 3/Playwright) or `sled/sled.json` (Sled 2).

**`defineSledConfig()` crashes locally** (Sled 3 only) -- no CI env vars. Prefix with `CI=false`. Sled 2 does not use `defineSledConfig`.

**Debug decision tree:**
```
Test failed
+-- Exact line + assertion --> Fix assertion or code
+-- "Couldn't find story matching..." --> Rebuild Storybook; IDs use export names
+-- Route aborted / unmocked API --> Add mock for that endpoint
+-- "intercepted pointer events" --> Overlay blocking --> wait/dismiss
+-- Timeout --> Check mocks return data, check page/story loads
+-- Need deeper investigation --> trace viewer or headed mode
```

For detailed debugging commands and symptom/fix tables, see `references/sled-testing.md` and `references/playwright-testing.md`.

### Direct Mode (fallback)

Only use when: (a) subagent failed with `resource_exhausted`, or (b) tasks are genuinely dependent. "I prefer direct mode" is not valid.

Process remaining tasks sequentially with the same quality checks.

---

## Step 4: Verify

1. Run all tests using the detected framework's run command (see run commands table above)
2. Verify every criterion in `def-done.md` against actual state
3. Fix gaps --> re-verify --> loop until PASS
4. Final summary with results + any skipped items

Dispatch a verifier subagent using `prompts/verifier.md` for independent validation.

---

## Selector Strategy

**Sled 3 / Playwright** (auto-wait built in):

| Priority | Selector | Example |
|----------|----------|---------|
| 1 | Role-based | `page.getByRole('button', { name: 'Submit' })` |
| 2 | Text-based | `page.getByText('Submit')` |
| 3 | Label-based | `page.getByLabel('Username')` |
| 4 | Test ID / data-hook | `page.getByTestId('submit-btn')` |
| 5 | CSS (avoid) | `page.locator('.submit-btn')` |

**Sled 2 / Puppeteer** (no auto-wait -- use explicit waits):

| Priority | Selector | Example |
|----------|----------|---------|
| 1 | data-hook + waitFor | `await page.waitForSelector('[data-hook="submit-btn"]')` |
| 2 | data-hook + query | `await page.$('[data-hook="submit-btn"]')` |
| 3 | data-hook + eval | `await page.$eval('[data-hook="el"]', el => el.textContent)` |
| 4 | CSS (avoid) | `await page.$('.submit-btn')` |

**Wix convention:** `data-hook` via `use: { testIdAttribute: 'data-hook' }` (Sled 3). Sled 2 uses `[data-hook="..."]` CSS selectors directly.

## What to Test (and What NOT)

**E2E tests** = behavior + state changes: full user journeys, multi-step interactions, cross-component flows, error recovery.

**NOT E2E** (unit/snapshot territory): "renders component", "is visible", "button enabled", "input accepts text", "data-hook exists", "handle rapid clicks", "child count". See def-done.md Gate 3 for enforcement.

## WDS Component Testing

| Framework | Import Path |
|-----------|-------------|
| Puppeteer (Sled 2) | `@wix/design-system/dist/testkit/puppeteer` |
| Playwright (Sled 3) | `@wix/design-system/dist/testkit/playwright` |

See `references/wds-e2e-testing.md` for patterns.

## BDD Architecture Summary

| Driver Type | Methods | Stateful? |
|-------------|---------|-----------|
| **Base** (`app.driver.ts`) | `given.*`, `navigateTo*()`, `setup()`, `reset()` | Yes (interceptors) |
| **Page** (`page.driver.ts`) | `get.*`, `is.*`, `when.*` | No -- pass `page` per method |
| **Builder** (`feature.builder.ts`) | `anItem()`, `aUser()` -- partial overrides | No -- stable defaults |
| **Spec** (`feature.spec.ts`) | Composes drivers, reads like docs | N/A |

Place builders in `src/test/builders/` -- shared by unit + E2E.

## Framework Quick Reference

For Sled 3 fixtures (`auth`, `site`, `experiment`, `interceptionPipeline`, `urlBuilder`, `biSpy`) and Sled 2 specifics (page access, auth, interceptors, actions, cleanup, config), see `references/sled-testing.md`.

## Critical Pitfalls (Quick Reference)

1. **Storybook IDs** use **export names** (kebab-cased), NOT `name` property
2. **Route ordering**: Playwright/Sled 3 = LIFO (catch-all FIRST), Sled 2 = FIFO (first match wins)
3. **Stale `storybook-static`** -- rebuild after adding/renaming stories
4. **No visibility-only E2E tests** -- snapshots cover rendering; E2E must test behavior
5. **Builders in `src/test/builders/`** -- shared by unit + E2E, no global counters
6. **`storiesToIgnoreRegex: ['.*']`** silently disables ALL visual regression
7. **Test budget: 2-4 per component, 10-20 total** -- excess = unit test territory
8. **Catch-all API blocking required** -- no real API calls in E2E tests

Details: `references/lessons-pitfalls.md`.

## Subagent Dispatch

When dispatching subagents, follow these rules:

- **Never paste full reference file content** -- provide file paths, detection data, and key context inline
- **Parallel limit**: max 4 subagents at once
- **Provide full task text** -- do NOT tell subagents to read plan.md
- **Check results** -- after each batch, verify files were created/modified before marking completed
- **Subagents cannot spawn subagents** -- the orchestrator dispatches all subagents

### Claude Code (native agents)

Uses `.claude/agents/e2e-*` agents: `e2e-detection-processor`, `e2e-writer-processor` (bypassPermissions), `e2e-debugger-processor` (bypassPermissions), `e2e-reviewer` (read-only), `e2e-verifier` (read-only).

**CRITICAL**: Writer/debugger processors must use `bypassPermissions` -- background agents auto-deny permissions. Dispatch up to 4 per batch. After each batch, verify files were modified (`git status`) before marking completed.

### Cursor (Task tool)

Uses `Task` tool with dedicated e2e subagent types. Each type has built-in instructions -- the `prompt` only needs task-specific context (paths, detection data, component list).

| Step | `subagent_type` | `readonly` | `model` | Prompt template |
|------|----------------|------------|---------|----------------|
| Detection | `"e2e-detection-processor"` | `true` | `"fast"` | [detection-processor.md](prompts/detection-processor.md) |
| Writer | `"e2e-writer-processor"` | — | — | [writer-processor.md](prompts/writer-processor.md) |
| Debugger | `"e2e-debugger-processor"` | — | — | [debugger-processor.md](prompts/debugger-processor.md) |
| Reviewer | `"e2e-reviewer"` | `true` | — | [reviewer.md](prompts/reviewer.md) |
| Verifier | `"e2e-verifier"` | `true` | — | [verifier.md](prompts/verifier.md) |

**IMPORTANT**: Use the dedicated `subagent_type` values above -- do NOT use `"generalPurpose"`. Dedicated types have built-in instructions, reducing token usage and avoiding `resource_exhausted`. The `prompt` field should only contain task-specific context (detection report, component paths, test budget, etc.), not the full skill instructions.

## Red Flags

**Never:**
- Skip reviews (reviewer AND verifier are both required)
- Skip re-review after fixes (reviewer found issues = fix = review again)
- Start verification before all tasks are processed
- Accept "close enough" (issues found = not done)
- Leave tasks as `pending` without processing or skipping
- Choose direct mode for preference ("more control" is not valid)
- Make subagent read plan file (provide full task text instead)
- Skip self-review in processor (both self-review and external review are needed)
- Ignore subagent questions (answer before letting them proceed)
- Let processor self-review replace actual review (both are needed)
- Default to 8 subagents just because "fast" was selected (8 is ceiling -- use only when justified)
- Skip asking the user for parallelism strategy (always ask before dispatch)
- Offer background mode when subagents need MCP tools or mid-task clarification
- Use `"generalPurpose"` subagent_type when a dedicated e2e type exists (causes resource_exhausted)

## Error Handling

- **Task failure**: Skip task, mark as skipped in plan.md, continue with remaining
- **Subagent resource_exhausted**: Switch to direct mode for remaining tasks
- **Verification failure**: Fix gaps, re-verify (loop until PASS)
- **`defineSledConfig()` crash**: Prefix all local commands with `CI=false`
- **Story not found**: Rebuild Storybook (`yarn build:storybook`), verify export-name-based IDs
- **Flaky tests**: Run `detect-flakiness --repeat-count 20`, find root cause before retrying

## Additional Resources

- `prompts/detection-processor.md` -- Detection subagent prompt template
- `prompts/writer-processor.md` -- Per-feature test writer prompt template
- `prompts/debugger-processor.md` -- Per-test debugger prompt template
- `prompts/reviewer.md` -- Reviewer subagent prompt template
- `prompts/verifier.md` -- Verifier subagent prompt template
- `references/e2e-driver-pattern.md` -- BDD driver/builder/spec templates
- `references/sled-testing.md` -- Sled 2/3 setup, config, CLI, fixtures, interceptors, migration
- `references/playwright-testing.md` -- Standalone Playwright setup, mocking, debugging
- `references/storybook-sled.md` -- Visual regression with @wix/playwright-storybook-plugin
- `references/wds-e2e-testing.md` -- WDS browser testkits
- `references/anti-patterns.md` -- Common anti-patterns and better approaches
- `references/lessons-pitfalls.md` -- Lessons from real implementations
- [Sled 3 official docs](https://dev.wix.com/docs/fed-guild/articles/infra/sled3-beta/getting-started/getting-started)
