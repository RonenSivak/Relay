---
name: e2e-testing
description: End-to-end browser testing for Wix applications using Sled 3 (@wix/sled-playwright), Sled 2 (@wix/sled-test-runner), or standalone Playwright. Full lifecycle - writing, running, debugging, and maintaining E2E tests. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist. Supports Storybook visual regression via @wix/playwright-storybook-plugin. Use when asked to write E2E tests, debug failing E2E tests, set up E2E infrastructure, or when the user says "e2e", "sled", "browser test", "end to end", "playwright", "visual regression", or "storybook e2e".
---

# E2E Testing

## Prerequisites

**MANDATORY**: Before writing E2E tests, invoke `/brainstorming` to clarify:

1. What user flows need E2E coverage?
2. What environment will tests run against?
3. Is there existing E2E infrastructure?
4. Is Storybook available for visual regression?

## Core Workflow

### Step 1: Infrastructure Detection (Always First)

```bash
Glob: **/*.e2e.*, **/*.spec.ts, **/*.sled.spec.*, **/*.sled3.spec.*
Glob: playwright.config.*, sled/sled.json
Read: package.json → look for @wix/sled-playwright, @wix/sled-test-runner, @playwright/test
Glob: .storybook/**, *.stories.tsx
```

**Decision:**
```
E2E infrastructure found?
├─ @wix/sled-playwright → Sled 3 (Playwright-based)
│  └─ Has Storybook? → Add @wix/playwright-storybook-plugin
├─ @wix/sled-test-runner v2.x → Sled 2 (Puppeteer/Jest)
├─ @playwright/test (no sled) → Standalone Playwright
└─ Nothing → Wix project? → Sled 3 (recommended) / Non-Wix → Playwright
```

### Step 2: Yoshi Flow Detection

| Yoshi Flow | E2E Framework | Config | Test Dir | Run Command |
|------------|--------------|--------|----------|-------------|
| **flow-bm** | Sled 3 | `playwright.config.ts` | `e2e/` | `sled-playwright test` |
| **flow-editor** | Sled 2 | `sled/sled.json` | `sled/` | `sled-test-runner remote` |
| **fullstack** | Jest + Puppeteer | `jest-yoshi.config.js` | `__tests__/*.e2e.ts` | `yoshi test --e2e` |
| **flow-library** | No E2E (unit only) | N/A | N/A | N/A |
| **Non-Yoshi** | Sled 3 | `playwright.config.ts` | `tests/e2e/` | `sled-playwright test` |

**Detect:** `package.json` → `wix.framework.type` or `devDependencies` for `@wix/yoshi-flow-*`.

**Framework setup (if new):**
- Sled 3: See `references/sled-testing.md`
- Standalone Playwright: See `references/playwright-testing.md`
- Storybook visual regression: See `references/storybook-sled.md`

### Step 3: Pattern Detection

**Before writing any tests**, analyze existing patterns:
```bash
Glob: **/*.e2e.*, **/*.spec.ts, **/__e2e__/**, **/e2e/**
# If tests found → read 2-3 examples and match their style
# No tests → use BDD architecture (driver/builder/spec)
```

### Step 4: Write Tests

**Existing patterns found?** Match their style exactly.

**No tests? Use BDD architecture:**

```
__e2e__/
├── constants.ts              # BASE_URL, testUser
├── feature.spec.ts           # BDD specs
├── feature.builder.ts        # Mock data factories
└── drivers/
    ├── app.driver.ts         # Navigation + given.* (API setup)
    └── page-name.driver.ts   # get.* / is.* / when.*
```

See `references/e2e-driver-pattern.md` for complete templates.

**Quick example (Sled 3):**

```typescript
test('should show empty state when no items', async ({ page, interceptionPipeline }) => {
  await appDriver.given.itemsLoaded([]).setup(interceptionPipeline);
  await appDriver.navigateToHome(page);
  await expect.poll(async () => itemsPage.is.emptyStateShown(page)).toBe(true);
});
```

**Coverage priorities:**
1. Critical user flows (revenue, user-blocking)
2. Cross-service interactions
3. Regression-prone areas
4. Visual regression via Storybook plugin
5. Skip: pure UI state (unit tests), API contracts (integration tests)

### Step 5: Run Tests

**`defineSledConfig()` crashes locally** — no CI env vars. Prefix with `CI=false`.

```bash
# Sled 3 — local
CI=false npx sled-playwright test 2>&1 | tail -30
CI=false npx sled-playwright test <file>.spec.ts 2>&1
CI=false npx sled-playwright test --grep "<pattern>" 2>&1
CI=false npx sled-playwright test --update-snapshots 2>&1

# Sled 3 — CI
sled-playwright test
sled-playwright test --remote

# View results
npx sled-playwright show-report

# Sled 2
npx sled-test-runner
npx sled-test-runner --testPathPattern="feat"
```

**Working directory:** Run from the package directory containing `playwright.config.ts`.

### Step 6: Debug Failures

**Read terminal output first:**
```
Test failed
├─ Exact line + assertion → Fix assertion or code
├─ "Couldn't find story matching..." → Rebuild Storybook; IDs use export names
├─ Route aborted / unmocked API → Add mock for that endpoint
├─ "intercepted pointer events" → Overlay blocking → wait/dismiss
├─ Timeout → Check mocks return data, check page/story loads
└─ Need deeper investigation → trace viewer or headed mode
```

**Debugging commands:**
```bash
CI=false npx sled-playwright test failing.spec.ts 2>&1           # Full output
npx playwright show-trace <test-results>/<test-name>/trace.zip   # Trace viewer
CI=false npx sled-playwright test --headed                        # Watch browser
CI=false npx sled-playwright test --debug                         # Playwright Inspector
CI=false npx sled-playwright detect-flakiness --repeat-count 20   # Flaky detection
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
| Flaky | Race condition | `detect-flakiness`, add waits |

## Triggers & Workflows

### "Write E2E tests for X"

1. Infrastructure detection (Step 1)
2. Pattern detection (Step 3) — match existing style
3. No tests? → BDD: `app.driver.ts`, `page.driver.ts`, `feature.builder.ts`
4. Write specs: happy path, error states, edge cases
5. Run and verify; add visual regression if Storybook exists

### "Debug failing E2E test"

1. Run: `CI=false npx sled-playwright test failing.spec.ts 2>&1`
2. Read error completely — line, assertion, stack
3. Categorize using debug table above
4. If unclear → trace viewer or headed mode
5. If flaky → `detect-flakiness --repeat-count 20`

### "Set up E2E infrastructure"

1. Determine project type → Sled 3 vs Playwright
2. Follow setup in references
3. Create first smoke test
4. Check for Storybook → add visual regression plugin
5. Add `postPublish` script for CI

## Selector Strategy

| Priority | Selector | Example |
|----------|----------|---------|
| 1 | Role-based | `page.getByRole('button', { name: 'Submit' })` |
| 2 | Text-based | `page.getByText('Submit')` |
| 3 | Label-based | `page.getByLabel('Username')` |
| 4 | Test ID / data-hook | `page.getByTestId('submit-btn')` |
| 5 | CSS (avoid) | `page.locator('.submit-btn')` |

**Wix convention:** `data-hook` via `use: { testIdAttribute: 'data-hook' }`.

## What to Test (and What NOT)

**Test with E2E:** Critical user journeys, complex multi-step interactions, cross-service flows, auth flows, regression-prone areas.

**Do NOT test with E2E:** Unit-level logic, API contracts, every edge case, implementation details, pure UI state.

```
    /  E2E  \        ← Few: critical user flows only
   / Integr. \       ← Some: API contracts, service interactions
  /   Unit    \      ← Many: business logic, components, utilities
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
| **Page** (`page.driver.ts`) | `get.*`, `is.*`, `when.*` | No — pass `page` per method |
| **Builder** (`feature.builder.ts`) | `anItem()`, `aUser()` — partial overrides | No — stable defaults |
| **Spec** (`feature.spec.ts`) | Composes drivers, reads like docs | N/A |

Place builders in `src/test/builders/` — shared by unit + E2E.

## Critical Pitfalls (Quick Reference)

1. **Storybook IDs** use **export names** (kebab-cased), NOT the `name` property — always verify
2. **Playwright routes are LIFO** — register fail-safe catch-all FIRST, then specific mocks override it
3. **Stale `storybook-static`** — rebuild (`yarn build:storybook`) after adding/renaming stories
4. **Don't write visibility-only E2E tests** when visual regression exists — test behavior instead
5. **Builders belong in `src/test/builders/`** — shared by unit + E2E, no global counters

For detailed explanations, see `references/lessons-pitfalls.md`.

## Sled 3 Fixtures

| Fixture | Purpose |
|---------|---------|
| `auth` | `auth.loginAsUser()`, `auth.loginAsMember()` |
| `site` | `await site.create()` → `{ metaSiteId }` |
| `experiment` | `experiment.enable('my-experiment')` |
| `interceptionPipeline` | Network interception |
| `urlBuilder` | Build URLs with overrides/experiments |
| `biSpy` | Spy on BI events |

**Scoped auth:** `test.use({ user: 'admin@wix.com' })` for auto-login.

## Additional Resources

- `references/e2e-driver-pattern.md` — BDD driver/builder/spec templates
- `references/sled-testing.md` — Sled 3 setup, config, CLI, fixtures, migration
- `references/playwright-testing.md` — Standalone Playwright setup, mocking, debugging
- `references/storybook-sled.md` — Visual regression with @wix/playwright-storybook-plugin
- `references/wds-e2e-testing.md` — WDS browser testkits
- `references/anti-patterns.md` — Common anti-patterns and better approaches
- `references/lessons-pitfalls.md` — Lessons from real implementations
- [Sled 3 official docs](https://dev.wix.com/docs/fed-guild/articles/infra/sled3-beta/getting-started/getting-started)
