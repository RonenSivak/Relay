---
name: e2e-testing
description: End-to-end browser testing for Wix applications using Sled 3 (@wix/sled-playwright), Sled 2 (@wix/sled-test-runner), or standalone Playwright. Full lifecycle - writing, running, debugging, and maintaining E2E tests. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist. Supports Storybook visual regression via @wix/playwright-storybook-plugin. Use when asked to write E2E tests, debug failing E2E tests, set up E2E infrastructure, or when the user says "e2e", "sled", "browser test", "end to end", "playwright", "visual regression", or "storybook e2e".
---

# E2E Testing

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before writing E2E tests, invoke `/brainstorming` to clarify:

1. What user flows need E2E coverage?
2. What environment will tests run against? (local dev, staging, production)
3. Is there existing E2E infrastructure? (Sled 3, Sled 2, Playwright)
4. Is Storybook available? (visual regression testing opportunity)

## Core Workflow

### Step 1: Infrastructure Detection (Always First)

**CRITICAL:** Before writing any tests, analyze what already exists.

```bash
# Find existing E2E test files
Glob: **/*.e2e.*, **/*.spec.ts, **/*.sled.spec.*, **/*.sled3.spec.*

# Check for framework configs
Glob: playwright.config.*, sled/sled.json, sled/*.json

# Check package.json for E2E deps
Read: package.json → look for @wix/sled-playwright, @wix/sled-test-runner, @playwright/test

# Check for Storybook
Glob: .storybook/**, storybook-static/**, *.stories.tsx
```

**Decision:**

```
E2E infrastructure found?
│
├─ @wix/sled-playwright in deps → Sled 3 (Playwright-based)
│  └─ Has storybook? → Add @wix/playwright-storybook-plugin
│
├─ @wix/sled-test-runner v2.x in deps → Sled 2 (Puppeteer/Jest)
│
├─ @playwright/test (no sled) → Standalone Playwright
│
└─ Nothing found → Ask: "Is this a Wix internal project?"
   ├─ YES → Set up Sled 3 (recommended)
   │  └─ Has Storybook? → Include storybook-plugin
   └─ NO → Set up standalone Playwright
```

### Step 2: Framework Setup (If New)

**Sled 3** (Wix internal - recommended):
- See `references/sled-testing.md` for complete setup, config, and Sled 2→3 migration

**Standalone Playwright** (non-Wix):
- See `references/playwright-testing.md` for setup and configuration

**Storybook Visual Regression** (with Sled 3):
- See `references/storybook-sled.md` for plugin setup and auto-generated tests

### Step 3: Pattern Detection

**CRITICAL:** Before writing any tests, analyze existing patterns in the codebase. Only fall back to BDD architecture when no existing patterns exist.

```bash
# Find existing E2E test files
Glob: **/*.e2e.*, **/*.spec.ts, **/__e2e__/**, **/e2e/**

# If tests found, read 2-3 examples to understand patterns
Read: [existing test files]
```

**Decision:**
- **Tests exist** → Follow their patterns (naming, structure, drivers)
- **No tests** → Use BDD architecture (driver/builder/spec) — see below

### Step 4: Write Tests

**If following existing patterns:** Match their style exactly.

**If using BDD architecture:** Create structured files:

```
__e2e__/
├── constants.ts              # Test constants (BASE_URL, testUser)
├── feature.spec.ts           # BDD specs (compose drivers)
├── feature.builder.ts        # Mock data factories
└── drivers/
    ├── app.driver.ts         # Base driver: navigation + given.* (API setup)
    ├── page-name.driver.ts   # Page driver: get.* / is.* / when.*
    └── component.driver.ts   # Component driver: get.* / is.* / when.*
```

See `references/e2e-driver-pattern.md` for complete templates and real Wix examples.

**BDD quick example (Sled 3):**

```typescript
import { test, expect } from '@wix/sled-playwright';
import { AppDriver } from './drivers/app.driver';
import { ItemsPageDriver } from './drivers/items-page.driver';
import { anItem } from './items.builder';

test.describe('Items Page', () => {
  const appDriver = new AppDriver();
  const itemsPage = new ItemsPageDriver();

  test.beforeEach(async ({ auth }) => {
    await auth.loginAsUser('test-user@wix.com');
    appDriver.reset();
  });

  test('should show empty state when no items', async ({ page, interceptionPipeline }) => {
    await appDriver.given
      .itemsLoaded([])
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);

    await expect
      .poll(async () => itemsPage.is.emptyStateShown(page))
      .toBe(true);
  });

  test('should display items after load', async ({ page, interceptionPipeline }) => {
    await appDriver.given
      .itemsLoaded([anItem({ id: 'item-1' })])
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);

    await expect(itemsPage.get.itemRow(page, 'item-1')).toBeVisible();
  });
});
```

**Coverage priorities:**
1. **Critical user flows** — Revenue-generating or user-blocking paths
2. **Cross-service interactions** — Flows spanning multiple backends
3. **Regression-prone areas** — Flows that have broken before
4. **Visual regression** — Component appearance via Storybook plugin
5. **Skip**: Pure UI state (unit tests), API contracts (integration tests)

### Step 5: Run Tests

```bash
# Sled 3
sled-playwright test                           # All tests
sled-playwright test --remote                  # Remote execution (CI-like)
sled-playwright test feature.spec.ts           # Specific file
sled-playwright detect-flakiness               # Check for flaky tests

# Sled 2
npx sled-test-runner                           # All tests (cloud)
npx sled-test-runner --testPathPattern="feat"  # Specific pattern
```

### Step 6: Debug Failures

```bash
# Playwright / Sled 3: Headed mode (see the browser)
sled-playwright test --headed

# Step-through debugging
sled-playwright test --debug

# Standalone Playwright
npx playwright test --headed
npx playwright test --debug
npx playwright test --ui            # Interactive test runner
```

**In-test debugging:**

```typescript
test('debug this flow', async ({ page }) => {
  await page.pause();  // Opens Playwright Inspector — step through actions

  // Use test.step for better trace/report structure
  await test.step('Navigate to dashboard', async () => {
    await page.goto('/dashboard');
  });

  await test.step('Create new item', async () => {
    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText('Created')).toBeVisible();
  });
});
```

**Artifacts on failure** (configured via `playwright.config.ts`):
- `trace: 'retain-on-failure'` — Full trace viewer (`npx playwright show-trace`)
- `screenshot: 'only-on-failure'` — Failure screenshots
- `video: 'retain-on-failure'` — Video recording

## Triggers & Workflows

### "Write E2E tests for X"

1. Run infrastructure detection (Step 1)
2. Run pattern detection (Step 3) — existing tests? Match their style
3. No existing tests? → Use BDD architecture:
   - Create `drivers/app.driver.ts` (navigation + API given.*)
   - Create `drivers/x-page.driver.ts` (get.*/is.*/when.*)
   - Create `x.builder.ts` (mock data factories)
4. Write specs: happy path, error states, edge cases
5. Run and verify all tests pass
6. If Storybook exists: add visual regression tests

### "Debug failing E2E test"

1. **Read the error completely** — screenshot, error message, stack trace
2. **Categorize:**

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Element not found | Selector changed, timing | Use Playwright locators (auto-wait) |
| Timeout | Page didn't load, slow API | Check backend, increase timeout |
| Visual regression | UI changed intentionally | Update snapshots: `--update-snapshots` |
| Flaky (random pass/fail) | Race condition, shared state | Run `detect-flakiness`, add waits |
| Works locally, fails remote | Environment difference | Run with `--remote` to reproduce |

3. **For flaky tests:** `npx @wix/sled-playwright detect-flakiness --repeat-count 20`

### "Set up E2E infrastructure"

1. Determine project type → Sled 3 vs Playwright
2. Follow setup in references
3. Create first smoke test
4. Check for Storybook → add visual regression plugin
5. Add `postPublish` script for CI

## Selector Strategy (from official Sled 3 docs)

**Priority order:**

| Priority | Selector | Example |
|----------|----------|---------|
| 1 | Role-based | `page.getByRole('button', { name: 'Submit' })` |
| 2 | Text-based | `page.getByText('Submit')` |
| 3 | Label-based | `page.getByLabel('Username')` |
| 4 | Test ID / data-hook | `page.getByTestId('submit-btn')` |
| 5 | CSS (avoid) | `page.locator('.submit-btn')` |

**Wix convention**: `data-hook` is the standard across WDS and Wix codebases. Configure:
```typescript
use: { testIdAttribute: 'data-hook' }
```

## WDS Component Testing in E2E

When the project uses `@wix/design-system`:

| Framework | Import Path |
|-----------|-------------|
| Puppeteer (Sled 2) | `@wix/design-system/dist/testkit/puppeteer` |
| Playwright (Sled 3) | `@wix/design-system/dist/testkit/playwright` |

See `references/wds-e2e-testing.md` for patterns and component APIs.

## What to Test with E2E (and What NOT to)

**Test with E2E:**
- Critical user journeys (login, checkout, signup, onboarding)
- Complex multi-step interactions (drag-and-drop, multi-step forms)
- Cross-service flows (spanning multiple backends)
- Authentication and authorization flows
- Regression-prone areas that have broken before

**Do NOT test with E2E:**
- Unit-level logic (use unit tests — much faster)
- API contracts (use integration tests)
- Every edge case (too slow for E2E — cover in unit tests)
- Internal implementation details
- Pure UI state changes (unit tests with RTL)

```
    /  E2E  \        ← Few: critical user flows only
   / Integr. \       ← Some: API contracts, service interactions
  /   Unit    \      ← Many: business logic, components, utilities
```

## Anti-Patterns

| Anti-Pattern | Better Approach |
|-------------|----------------|
| `page.waitForTimeout(3000)` | `await expect(locator).toBeVisible()` — auto-retrying assertion |
| `page.waitForSelector('.btn')` | `page.getByRole('button', { name: 'Submit' })` — auto-waits |
| `page.locator('.btn-primary.submit')` | `page.getByRole('button', { name: 'Submit' })` — role-based |
| `page.locator('div > form > div:nth-child(2)')` | `page.getByLabel('Email')` — label-based |
| Testing implementation details | Test user-visible behavior |
| One giant test for entire flow | Break into focused, independent tests |
| Shared mutable state between tests | Each test sets up its own state |
| Hardcoded test data inline | Use builders (`anItem()`) and fixtures |
| All logic in spec file | Use BDD drivers (get/is/when) |
| Storing `page` in driver constructor | Pass `page` as parameter to each method |
| Running visual tests locally | Always `--remote` for visual tests |
| Retrying flaky tests without fixing | `detect-flakiness` → find root cause |
| Skipping Storybook for visual coverage | Add `@wix/playwright-storybook-plugin` |
| Manual snapshot tests for each story | Plugin auto-generates them |

## BDD Architecture Summary

**Base Driver** (`drivers/app.driver.ts`):
- `given.*` — API interception/data setup (return `this` for chaining)
- `navigateTo*()` — Page navigation helpers
- `setup()` / `reset()` — Interceptor lifecycle

**Page Driver** (`drivers/page.driver.ts`):
- `get.*` — Returns Playwright Locators
- `is.*` — Async boolean state queries
- `when.*` — Async browser actions

**Builder** (`feature.builder.ts`):
- Factory functions with sensible defaults (`anItem()`, `aUser()`)
- Allow partial overrides

**Spec** (`feature.spec.ts`):
- Composes base + page drivers
- Reads like documentation
- Uses `expect.poll()` for async state assertions

Example:
```typescript
test('should show empty state when no items', async ({ page, interceptionPipeline }) => {
  await appDriver.given
    .itemsLoaded([])
    .setup(interceptionPipeline);

  await appDriver.navigateToHome(page);

  await expect.poll(async () => itemsPage.is.emptyStateShown(page)).toBe(true);
});
```

## References

- `references/e2e-driver-pattern.md` — BDD driver/builder/spec templates for E2E tests
- `references/sled-testing.md` — Sled 3 setup, config, CLI, fixtures, migration from Sled 2
- `references/playwright-testing.md` — Standalone Playwright setup, network mocking, debugging
- `references/storybook-sled.md` — Storybook visual regression with @wix/playwright-storybook-plugin
- `references/wds-e2e-testing.md` — WDS browser testkits (Puppeteer + Playwright)
