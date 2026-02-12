# Lessons & Pitfalls from Real Implementations

## Avoid "Dumb" Visibility Tests

When Storybook visual regression is in place, do NOT write E2E tests that only check "is this element visible". Visual regression already covers appearance. E2E tests should validate **behavior, flows, and state transitions**.

| Bad (redundant with visual regression) | Good (tests behavior) |
|---|---|
| `expect(wizard).toBeVisible()` | Navigate step 1 → step 2 → back → verify state preserved |
| `expect(header).toHaveText('Title')` | Click continue → verify API call sent with correct payload |
| `expect(button).toBeEnabled()` | Fill form → submit → verify success screen shows |

**Rule of thumb:** If a test only asserts visibility/text without user interaction, it's a visual regression test — let Storybook handle it.

## API Mocking Best Practices

### Core Principles (All Frameworks)

1. **Each test mocks only what it needs** — no monolithic `setupAllMocks()`
2. **Mock third-party dependencies** — never test services you don't control
3. **Know your ordering** — Playwright/Sled 3 = **LIFO**, Sled 2 = **FIFO** (critical!)

### Quick Reference: Which API to Use

| Framework | Mocking API | Ordering |
|-----------|-------------|----------|
| **Standalone Playwright** | `page.route()` + `route.fulfill()` | LIFO |
| **Sled 3** (`@wix/sled-playwright`) | `interceptionPipeline.setup(handlers)` with `InterceptHandler[]` | LIFO (wraps `context.route()`) |
| **Sled 3** (also supports) | Raw `page.route()` alongside pipeline | LIFO |
| **Sled 2** (`@wix/sled-test-runner`) | `InterceptionTypes.Handler` with `execRequest`/`execResponse` | **FIFO** |

---

### Standalone Playwright (`page.route`)

**Approaches:**

| Approach | When to Use |
|----------|-------------|
| `route.fulfill({ json })` | Return static mock data (most common) |
| `route.fetch()` → modify → `route.fulfill()` | Modify real API responses (hybrid) |
| `route.fallback()` | Layered handlers — compose multiple route rules |
| `page.routeFromHAR()` | Complex APIs — replay recorded responses |
| `route.continue()` | Pass through with modified headers/params |
| `route.abort()` | Block requests (fail-safe, asset blocking) |

```typescript
// Return static JSON
await page.route('**/api/v1/users', route => route.fulfill({
  json: [{ id: '1', name: 'Test User' }],
}));

// Mock with error status
await page.route('**/api/v1/items', route => route.fulfill({
  status: 500,
  json: { error: 'Internal Server Error' },
}));

// Modify a real response (hybrid)
await page.route('**/api/settings', async route => {
  const response = await route.fetch();
  const json = await response.json();
  json.featureFlag = true;
  await route.fulfill({ json });
});
```

**Route ordering (LIFO) and `route.fallback()`:**

Playwright routes are **Last In, First Out** — last registered handler runs first. Use `route.fallback()` to compose layered handlers (passes to next handler, unlike `route.continue()` which goes to network):

```typescript
// Layer 1: Global (registered first → runs last)
await page.route('**/*', async route => {
  const headers = await route.request().allHeaders();
  delete headers['if-none-match'];
  await route.fallback({ headers });
});

// Layer 2: Specific mock (registered second → runs first)
await page.route('**/api/users', route => route.fulfill({ json: mockUsers }));
```

**Fail-safe catch-all:** Register FIRST (becomes lowest priority due to LIFO):

```typescript
await page.route('**/api/**', route => route.abort('blockedbyclient'));  // FIRST
await page.route('**/api/users', route => route.fulfill({ json: mockUsers }));  // overrides
```

**HAR replay:** `await page.routeFromHAR('./hars/api.har', { url: '**/api/**', update: false });`
Record: `npx playwright open --save-har=api.har <url>`

**Cleanup:** `page.unroute()` or `{ times: 1 }` option.

---

### Sled 3 (`interceptionPipeline`)

Sled 3 provides the `interceptionPipeline` fixture which wraps `page.context().route()`. Handlers use `InterceptHandler` from `@wix/browser-integrations`.

**Actions available** (`InterceptHandlerActions`):

| Action | Purpose |
|--------|---------|
| `INJECT_RESOURCE` | Return mock response (Buffer) — **most common for mocking** |
| `MODIFY_RESOURCE` | Intercept response and modify body/headers/status |
| `MODIFY_REQUEST` | Modify request URL/headers/postData before sending |
| `REDIRECT` | Redirect to different URL |
| `INJECT_REMOTE_RESOURCE` | Fetch from a different remote URL |
| `ABORT` | Block the request |
| `CONTINUE` | Pass through unchanged |
| `FALLBACK` | Pass to next handler (LIFO composition) |
| `EMPTY_RESPONSE` | Return empty response |
| `HOLD` | Pause request until `waitUntil()` resolves |
| `ASYNC_INTERCEPT` | Return an async `InterceptionResult` |

**Handler shape:**

```typescript
import type { InterceptHandler } from '@wix/sled-playwright';
import { InterceptHandlerActions } from '@wix/sled-playwright';

const myInterceptor: InterceptHandler = {
  id: 'mock-users-api',                // optional — for reporting
  pattern: '**/api/v1/users',           // glob or RegExp
  handler({ url, method, postData, headers, resourceType }) {
    return {
      action: InterceptHandlerActions.INJECT_RESOURCE,
      resource: Buffer.from(JSON.stringify([{ id: '1', name: 'Test User' }])),
      responseHeaders: { 'Content-Type': 'application/json' },
      responseCode: 200,
    };
  },
};
```

**Usage in tests:**

```typescript
import { test, expect, InterceptHandlerActions } from '@wix/sled-playwright';
import type { InterceptHandler } from '@wix/sled-playwright';

const createInterceptors = (): InterceptHandler[] => [
  {
    pattern: '**/api/v1/items',
    handler() {
      return {
        action: InterceptHandlerActions.INJECT_RESOURCE,
        resource: Buffer.from(JSON.stringify({ items: [] })),
        responseHeaders: { 'Content-Type': 'application/json' },
      };
    },
  },
];

test('should show empty state', async ({ page, auth, interceptionPipeline }) => {
  await interceptionPipeline.setup(createInterceptors());
  await auth.loginAsUser('test@wix.com');
  await page.goto('https://manage.wix.com/dashboard/msid/app');
  await expect(page.getByText('No items')).toBeVisible();
});
```

**Modify existing response:**

```typescript
{
  pattern: '**/api/v1/settings',
  handler() {
    return {
      action: InterceptHandlerActions.MODIFY_RESOURCE,
      modifyBody: (body) => {
        const json = JSON.parse(body.toString());
        json.featureEnabled = true;
        return JSON.stringify(json);
      },
    };
  },
}
```

**Sled 3 also supports raw `page.route()`** alongside `interceptionPipeline`. Use whichever fits — pipeline is preferred for BDD drivers (composable interceptor arrays), raw `page.route()` for simple one-off mocks.

---

### Sled 2 (`InterceptionTypes`)

Sled 2 uses `InterceptionTypes.Handler` from `@wix/sled-test-runner`. Handlers have two hooks: `execRequest` (before request) and `execResponse` (after response).

**Critical difference: Sled 2 is FIFO** — first interceptor to return `action !== CONTINUE` wins. Opposite of Playwright/Sled 3's LIFO.

**Handler shape:**

```typescript
import { InterceptionTypes } from '@wix/sled-test-runner';

const interceptor: InterceptionTypes.Handler = {
  // Intercept BEFORE request is sent
  execRequest({ url, resourceType }) {
    if (url.includes('/api/blocked')) {
      return { action: InterceptionTypes.Actions.ABORT };
    }
    return { action: InterceptionTypes.Actions.CONTINUE };
  },

  // Intercept AFTER response is received
  execResponse({ url, method }) {
    if (url.endsWith('/api/v1/items') && method === 'GET') {
      return {
        action: InterceptionTypes.Actions.MODIFY_RESOURCE,
        modify: ({ body, responseHeaders }) => {
          return {
            body: Buffer.from(JSON.stringify({ items: [], total: 0 })),
          };
        },
      };
    }
    return { action: InterceptionTypes.Actions.CONTINUE };
  },
};
```

**Usage in tests:**

```typescript
const { page } = await sled.newPage({
  user: 'test@wix.com',
  interceptors: [interceptor],
});
```

**Sled 2 Actions:**

| Action | Hook | Purpose |
|--------|------|---------|
| `CONTINUE` | Both | Pass through (default — always return this for non-matching URLs) |
| `MODIFY_RESOURCE` | `execResponse` | Modify response body/headers via `modify` callback |
| `INJECT_RESOURCE` | `execRequest` | Return a synthetic response (no network) |
| `ABORT` | `execRequest` | Block/abort the request |
| `REDIRECT` | `execRequest` | Redirect to different URL |
| `MODIFY_REQUEST` | `execRequest` | Modify request headers before sending |

---

### Common Mistakes (All Frameworks)

| Mistake | Fix |
|---------|-----|
| Monolithic `setupAllMocks()` for every test | Each test provides only the interceptors it needs |
| Catch-all AFTER specific mocks (Playwright/Sled 3) | Register catch-all FIRST — LIFO makes it lowest priority |
| Assuming LIFO in Sled 2 | Sled 2 is **FIFO** — first match wins |
| `body: JSON.stringify(data)` in Playwright | Use `json: data` directly in `route.fulfill()` |
| `route.continue()` to compose handlers | Use `route.fallback()` — `continue()` goes to network |
| Mocking in `beforeAll` (shared state) | Mock in `beforeEach` or per-test for isolation |
| Forgetting to return `CONTINUE` in Sled 2 | Always return `{ action: Actions.CONTINUE }` for non-matching URLs |
| Mixing `page.route()` and `interceptionPipeline` on same URL | Pick one per URL pattern — overlapping causes unpredictable behavior |

## Builders: Shared Between Unit & E2E Tests

Builders placed only in the E2E directory get duplicated when unit tests need the same factories. Global counters (`let counter = 0`) cause non-deterministic tests in parallel.

**Pattern:** Place builders in `src/test/builders/` — shared by both unit and E2E tests.
- Stable defaults — no global mutable state
- Single + batch creation — `anItem()` and `items(3)` without shared counters
- Per-test customization — `anItem().withName('custom').build()`

## Storybook Visual Regression: Story ID Mismatch

Storybook derives story IDs from **export names**, NOT from the `name` property. The `name` property is display-only.

```typescript
// Title: 'App/MyComponent'
export const EmptyState: StoryObj = { name: 'Empty - No Data', ... };
//                                         ^^^^^^^^^^^^^^ display only!
// Story ID = 'app-mycomponent--empty-state'  (from export name: EmptyState)
// NOT       'app-mycomponent--empty-no-data' (from name property)
```

**Rule:** `kebab(title)--kebab(exportName)`. Always verify against actual Storybook output.

## Storybook Visual Regression: Stale Static Build

`@wix/playwright-storybook-plugin` reads from `storybook-static/` (pre-built), NOT a live dev server. Adding or renaming stories requires rebuilding:

```bash
yarn build:storybook   # Regenerates storybook-static/
```

**Organization:**
- One spec per component, all variants — don't split by variant
- One `.stories.tsx` per component — all states as separate exports

## Driver Refactoring: `page` in Constructor

When refactoring existing code:
- **Base driver** can be stateful (interceptors, request tracking, reset) — page passed per method
- **Page drivers** should be stateless — `get.*(page)`, `is.*(page)`, `when.*(page)`
- Scope of change is massive: every method signature + every test call site. Plan for this.
- Instantiate drivers at `describe` scope (stateless), not in `beforeEach`

## storiesToIgnoreRegex: The Silent Killer

The regex `['.*']` in `storybookPlugin({ storiesToIgnoreRegex: ['.*'] })` matches every story ID. The plugin generates zero snapshot tests. This is often set during initial setup to avoid snapshot failures, then forgotten.

**Audit checklist:**
1. Read `playwright.config.ts` -> `storybookPlugin` -> `storiesToIgnoreRegex`
2. If `['.*']` -> fix to `['.*--docs$', '.*-playground$']`
3. Set `deleteOldTestFiles: true` to clean up orphaned test files
4. Run tests to generate snapshot files
5. Commit the generated `.spec.ts` files and `__snapshots__/` directory

**Real Wix projects that do it right:**
- invoices: `['.*--docs$', '.*-playground$']`
- em/wix-emails: `['.*--docs$', '.*-playground$']`
- form-client: `[EXCLUDE_FROM_VISUAL_TESTS_TAG]` (tag-based)
- wix-chatbot: Positive regex to include only specific prefixes

## Test Bloat: When More Tests Means Less Value

Signs you're writing too many E2E tests:
- More than 5 per component
- Tests that only assert `isVisible` or `toBeVisible`
- Tests named "should display X" or "should render Y"
- Tests for input acceptance, maxlength, empty state without user flow
- Tests for data-hook presence or container structure

**Correct target: ~15 behavioral tests + auto-generated snapshots for a typical project.**

## Catch-All API Blocking: No Real Calls Allowed

E2E tests that make real API calls are:
- **Flaky**: Backend availability, rate limits, and data changes cause random failures
- **Slow**: Real network round-trips add seconds per test
- **Unsafe**: Test data can leak to production, real mutations can corrupt state
- **Unreproducible**: Different environments return different data

**Solution: Block everything, mock explicitly.** Use the framework's canonical interception API:

**Sled 3** -- `interceptionPipeline` (NOT `page.route`):
```typescript
// Base driver setup -- catch-all as LAST handler
async setup(interceptionPipeline: any) {
  interceptionPipeline.setup([
    ...this.interceptors,  // specific mocks registered via given.*
    {
      id: 'catch-all-api-block',
      pattern: /\/(api|_api)\//,
      handler: () => ({ action: InterceptHandlerActions.ABORT }),
    },
  ]);
}

// given.* registers specific mocks (matched before catch-all)
given.itemsLoaded(items) {
  this.interceptors.push({
    pattern: /\/api\/items/,
    handler: () => ({
      action: InterceptHandlerActions.INJECT_RESOURCE,
      resource: Buffer.from(JSON.stringify({ items })),
    }),
  });
  return this;
}
```

**Sled 2** -- `InterceptionTypes.Handler` (catch-all LAST, FIFO):
```typescript
const catchAll: InterceptionTypes.Handler = {
  execRequest: ({ url }) => url.match(/\/(api|_api)\//)
    ? { action: InterceptionTypes.Actions.ABORT }
    : { action: InterceptionTypes.Actions.CONTINUE },
};
// Pass to sled.newPage({ interceptors: [...specificMocks, catchAll] })
```

**Standalone Playwright** -- `page.route` (catch-all FIRST, LIFO):
```typescript
await page.route(/\/(api|_api)\//, route => route.abort('blockedbyclient'));
await page.route('**/api/items', route => route.fulfill({ json: { items } }));
```

If a test fails with "net::ERR_BLOCKED_BY_CLIENT" or "Route aborted": the test is calling an unmocked endpoint. Fix: add the mock. Never remove the catch-all.

## Naming & Organization

- Name test folders/files after **what they test**, not the test type (`checkout/` not `happyFlow/`)
- Move shared utilities to the **base driver** — avoid utility files
- Keep spec files comment-free — test names and driver methods should be self-documenting
