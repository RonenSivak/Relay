# Lessons & Pitfalls from Real Implementations

## Avoid "Dumb" Visibility Tests

When Storybook visual regression is in place, do NOT write E2E tests that only check "is this element visible". Visual regression already covers appearance. E2E tests should validate **behavior, flows, and state transitions**.

| Bad (redundant with visual regression) | Good (tests behavior) |
|---|---|
| `expect(wizard).toBeVisible()` | Navigate step 1 → step 2 → back → verify state preserved |
| `expect(header).toHaveText('Title')` | Click continue → verify API call sent with correct payload |
| `expect(button).toBeEnabled()` | Fill form → submit → verify success screen shows |

**Rule of thumb:** If a test only asserts visibility/text without user interaction, it's a visual regression test — let Storybook handle it.

## API Mocking: Granular Per-Endpoint, Not Monolithic

A monolithic `setupApiMocks()` mocks everything for every test. Tests become brittle and you can't tell which test needs which API.

**Pattern:** `given.mockApi(page, endpoint, response, status?)` — each test mocks only what it needs.

**Fail-safe catch-all:** Register a route that **aborts** any unmocked API request. This prevents real API calls from leaking.

**Ordering matters (LIFO):** Playwright routes use Last In, First Out. Register the catch-all first in `reset()`, then specific mocks override it.

```typescript
// In base driver reset() — registered FIRST (lowest priority due to LIFO):
await page.route('**/<your-api-prefix>/**', (route) => {
  route.abort('blockedbyclient');  // fail-safe: no real calls leak out
});

// In test — registered AFTER (higher priority due to LIFO):
await driver.given.mockApi(page, 'users', { users: [aUser().build()] });
```

If you register them in the wrong order (specific first, catch-all second), the catch-all wins and blocks everything.

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

## Naming & Organization

- Name test folders/files after **what they test**, not the test type (`checkout/` not `happyFlow/`)
- Move shared utilities to the **base driver** — avoid utility files
- Keep spec files comment-free — test names and driver methods should be self-documenting
