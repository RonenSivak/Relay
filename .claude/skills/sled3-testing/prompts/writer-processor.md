# Writer Processor Prompt

You are writing Sled 3 E2E tests for a specific feature/component in a Wix project.

## Your Task

Write behavioral E2E tests for: `{FEATURE_NAME}`

**Package path:** `{PACKAGE_PATH}`
**Test directory:** `{TEST_DIR}`
**Test budget:** 2-4 tests (behavioral only — NO visibility-only tests)

## Context Provided

- **Detection report:** {DETECTION_REPORT_JSON}
- **Shared infra paths:** Base driver at `{BASE_DRIVER_PATH}`, constants at `{CONSTANTS_PATH}`
- **Component location:** `{COMPONENT_PATH}`

## Before You Begin

1. Read the component source to understand its behavior, API calls, and user interactions
2. Read the existing base driver to understand the `given.*` API and catch-all setup
3. Read any existing drivers/specs nearby for convention consistency
4. Identify ALL API endpoints the component calls — every one must be mocked

## What to Create

### 1. Page Driver (`drivers/{feature}.driver.ts`)

```typescript
// Methods to implement:
get.*   // Query elements (returns locators or values)
is.*    // Boolean state checks (returns boolean)
when.*  // User interactions (returns this for chaining)
given.* // API mocking via interceptionPipeline (if feature-specific mocks needed)
```

**Rules:**
- All selectors live here — specs never use raw selectors
- Prefer `getByRole` > `getByText` > `getByLabel` > `getByTestId` > CSS
- `when.*` methods return `this` for chaining
- No `waitForTimeout` — use `expect` auto-retry or `expect.poll`

### 2. Builder (`builders/{feature}.builder.ts`) — if needed

Create mock data factories with sensible defaults:
```typescript
export const anItem = (overrides = {}) => ({ id: uuid(), title: 'Test', ...overrides });
```

### 3. Spec File (`{feature}.spec.ts`)

**Every test MUST have:** user interaction -> state change -> assertion on NEW state.

**FORBIDDEN tests:**
- Navigate -> `toBeVisible()` (visibility-only)
- Click button -> no `expect` (empty assertion)
- Only check "renders" or "is visible" (snapshot territory)

**Structure:**
```typescript
import { test, expect } from '@wix/sled-playwright';
import { AppDriver } from './drivers/app.driver';
import { FeatureDriver } from './drivers/{feature}.driver';

test.describe('{Feature}', () => {
  const app = new AppDriver();
  const feature = new FeatureDriver();

  test.beforeEach(() => { app.reset(); });

  test('should {action} when {trigger}', async ({ page, auth, interceptionPipeline }) => {
    // given
    app.given.{mockData}();
    await app.setup(interceptionPipeline);
    await app.navigateTo{Page}(page, auth);

    // when
    await feature.when.{action}(page);

    // then
    expect(await feature.get.{result}(page)).toBe(expected);
  });
});
```

## Mandatory Requirements

1. **Catch-all API blocking** — base driver MUST have `InterceptHandlerActions.ABORT` catch-all. Verify it exists before writing tests.
2. **All APIs mocked** — every endpoint the feature calls must have a `given.*` mock. The catch-all blocks anything unmocked.
3. **Use `interceptionPipeline.setup()`** — NEVER use `interceptors.push()` (it doesn't work).
4. **BDD pattern** — no `page.*` calls in specs, no raw selectors in specs.
5. **Test budget** — 2-4 tests max. If you need more, you're testing at the wrong level.

## Self-Review Checklist

Before returning your work, verify:

- [ ] Every test has: interaction -> state change -> assertion
- [ ] No visibility-only tests (toBeVisible without prior interaction)
- [ ] No raw selectors in spec files
- [ ] No `page.*` calls in spec files (all via drivers)
- [ ] No `waitForTimeout` anywhere
- [ ] All API endpoints mocked via `given.*`
- [ ] `when.*` methods return `this`
- [ ] Driver uses `getByRole`/`getByText`/`getByTestId` (not CSS selectors)
- [ ] 2-4 tests total (not more)
- [ ] Tests are deterministic (no conditional logic)
