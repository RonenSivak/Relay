---
name: e2e-testing
description: End-to-end browser testing for Wix applications using Sled 3 (@wix/sled-playwright), Sled 2 (@wix/sled-test-runner), or standalone Playwright. Adaptive parallel subagents for detection, test writing, and debugging. Full lifecycle with BDD architecture (driver/builder/spec), Storybook visual regression, and plan.md + def-done.md verification. Use when asked to write E2E tests, debug failing E2E tests, set up E2E infrastructure, or when the user says "e2e", "sled", "browser test", "end to end", "playwright", "visual regression", or "storybook e2e".
---

# E2E Testing

## Overview

Write, run, debug, and maintain E2E browser tests for Wix applications. Supports Sled 3 (Playwright-based), Sled 2 (Puppeteer/Jest), standalone Playwright, and Storybook visual regression. Uses adaptive parallel subagents to offload detection, per-feature test writing, and multi-test debugging from the master context. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist.

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
| 5 | Create shared infra (app.driver, builders) | writing | B | pending |
| 6 | Write tests: <feature-1> | writing | B | pending |
| ... | ... | ... | ... | ... |
```

### 2c. Generate `def-done.md`

```markdown
# Definition of Done
- [ ] Infrastructure detected and documented
- [ ] Framework type identified (Sled 3 / Sled 2 / Playwright)
- [ ] Existing test patterns analyzed (or BDD architecture adopted)
- [ ] Shared drivers and builders created (if needed)
- [ ] Per-feature specs written with happy path + error states
- [ ] All tests pass locally (run command per detected framework)
- [ ] Visual regression added (if Storybook available)
- [ ] No lint errors in test files
```

### 2d. Ask Parallelism Strategy

Present fast / moderate / conservative options per the Execution Strategy section above.

### 2e. Ask Execution Mode

Detection subagents are background-viable (Read/Glob/Grep only). Writing subagents need foreground (file writes). Debug subagents are background-viable if no interactive investigation needed.

Only offer background when subagents don't need MCP tools or mid-task clarification.

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

Master combines all 4 reports into a detection summary, then proceeds to Phase B.

**Framework setup (if new):**
- Sled 3: See `references/sled-testing.md`
- Standalone Playwright: See `references/playwright-testing.md`
- Storybook visual regression: See `references/storybook-sled.md`

### Phase B: Writing

**Step B1 -- Master creates shared infrastructure:**

If no existing tests, master creates BDD shared infra:

```
__e2e__/
+-- constants.ts              # BASE_URL, testUser
+-- drivers/
|   +-- app.driver.ts         # Navigation + given.* (API setup)
+-- builders/                 # Or src/test/builders/ if shared with unit
```

See `references/e2e-driver-pattern.md` for complete templates.

**Step B2 -- Dispatch per-feature subagents:**

Each subagent receives: detection report, shared infra paths, feature requirements. Each creates:
- `feature.spec.ts` -- BDD specs (or matching existing style)
- `drivers/page-name.driver.ts` -- get.* / is.* / when.*
- `feature.builder.ts` -- mock data factories (if needed)

Use prompt templates from `prompts/writer-processor.md`.

**Step B3 -- Review:** Dispatch reviewer subagents (one per feature) using `prompts/reviewer.md`.

**Quick examples by framework:**

Sled 3 (Playwright):
```typescript
test('should show empty state when no items', async ({ page, interceptionPipeline }) => {
  await appDriver.given.itemsLoaded([]).setup(interceptionPipeline);
  await appDriver.navigateToHome(page);
  await expect.poll(async () => itemsPage.is.emptyStateShown(page)).toBe(true);
});
```

Sled 2 (Puppeteer/Jest):
```typescript
it('should show empty state when no items', async () => {
  appDriver.given.itemsLoaded([]);
  page = await appDriver.createPage();  // uses sled.newPage() internally
  await page.goto(BASE_URL);
  await page.waitForSelector('[data-hook="empty-state"]');
  expect(await itemsPage.is.emptyStateShown(page)).toBe(true);
});
```

**Coverage priorities:**
1. Critical user flows (revenue, user-blocking)
2. Cross-service interactions
3. Regression-prone areas
4. Visual regression via Storybook plugin
5. Skip: pure UI state (unit tests), API contracts (integration tests)

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

**Debugging commands (Sled 3 / Playwright):**
```bash
CI=false npx sled-playwright test failing.spec.ts 2>&1           # Full output
npx playwright show-trace test-results/test-name/trace.zip       # Trace viewer
CI=false npx sled-playwright test --headed                        # Watch browser
CI=false npx sled-playwright test --debug                         # Playwright Inspector
CI=false npx sled-playwright detect-flakiness --repeat-count 20   # Flaky detection
```

**Debugging commands (Sled 2):**
```bash
npx sled-test-runner local                                        # Run locally (headed)
npx sled-test-runner local -d -k                                  # DevTools + keep browser open
npx sled-test-runner local -b -v -l                               # Serial + verbose + browser logs
npx sled-test-runner local -f "failing"                           # Filter by pattern
npx sled-test-runner remote -d -f "failing"                       # Remote Cloud Debugger
```

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Element not found | Selector changed, timing | Playwright locators (auto-wait) |
| Timeout | Slow/blocked API | Check mocks, increase timeout |
| Visual regression | UI changed | `--update-snapshots` |
| Story not found | Stale static build or wrong ID | Rebuild; verify export-name-based ID |
| Route aborted | Unmocked request | Add mock |
| CI env crash | `defineSledConfig` outside CI | `CI=false` prefix |
| Pointer events intercepted | Overlay blocking | Dismiss overlay / wait |
| Flaky | Race condition | `detect-flakiness` (Sled 3), add waits |
| Actions.CONTINUE missing (Sled 2) | Handler silently blocks all requests | Always return `CONTINUE` for non-matching URLs |
| Request blocked unexpectedly (Sled 2) | Wrong action name | Use `ABORT` (not `BLOCK_RESOURCE`) |

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

**Test with E2E:** Critical user journeys, complex multi-step interactions, cross-service flows, auth flows, regression-prone areas.

**Do NOT test with E2E:** Unit-level logic, API contracts, every edge case, implementation details, pure UI state.

```
    /  E2E  \        <-- Few: critical user flows only
   / Integr. \       <-- Some: API contracts, service interactions
  /   Unit    \      <-- Many: business logic, components, utilities
```

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

## Sled 3 Fixtures

| Fixture | Purpose |
|---------|---------|
| `auth` | `auth.loginAsUser()`, `auth.loginAsMember()` |
| `site` | `await site.create()` --> `{ metaSiteId }` |
| `experiment` | `experiment.enable('my-experiment')` |
| `interceptionPipeline` | Network interception |
| `urlBuilder` | Build URLs with overrides/experiments |
| `biSpy` | Spy on BI events |

**Scoped auth:** `test.use({ user: 'admin@wix.com' })` for auto-login.

## Sled 2 Specifics

| Aspect | Pattern |
|--------|---------|
| Page access | `sled.newPage()` or `sled.newPage({ user, interceptors, experiments })` |
| Auth | `sled.newPage({ user: 'email' })` or `sled.loginAsUser(page, email)` |
| Auth (deprecated) | `authType: 'free-user'` -- do not use |
| BM apps | `injectBMOverrides({ page, appConfig })` from `@wix/yoshi-flow-bm/sled` |
| Interceptors | `InterceptionTypes.Handler` with `execRequest`/`execResponse`, **FIFO** |
| Actions | `CONTINUE`, `MODIFY_RESOURCE`, `INJECT_RESOURCE`, `ABORT`, `REDIRECT`, `MODIFY_REQUEST` |
| Cleanup | `page.close()` in `afterEach`/`afterAll` -- manual |
| Selectors | `page.$('[data-hook="..."]')`, `page.waitForSelector()` -- no auto-wait |
| WDS testkits | `@wix/design-system/dist/testkit/puppeteer` |
| File naming | `*.sled.spec.ts` |
| Config | `sled/sled.json` |
| Run | `npx sled-test-runner` (remote) / `sled-test-runner local` (local) |
| Debug local | `local -d` (DevTools), `-k` (keep browser), `-b` (serial), `-v` (verbose) |
| Debug remote | `remote -d` (Cloud Debugger) |
| Storybook | `storybook_config` key in `sled.json` (Sheshesh visual comparison) |

See `references/sled-testing.md` Sled 2 section for full API details and examples.

## Critical Pitfalls (Quick Reference)

1. **Storybook IDs** use **export names** (kebab-cased), NOT the `name` property -- always verify
2. **Route ordering differs**: Playwright/Sled 3 = **LIFO** (register catch-all FIRST), Sled 2 = **FIFO** (first match wins)
3. **Stale `storybook-static`** -- rebuild (`yarn build:storybook`) after adding/renaming stories
4. **Don't write visibility-only E2E tests** when visual regression exists -- test behavior instead
5. **Builders belong in `src/test/builders/`** -- shared by unit + E2E, no global counters

For detailed explanations, see `references/lessons-pitfalls.md`.

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
