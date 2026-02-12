# E2E Anti-Patterns

Common mistakes and their better alternatives.

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
| Writing "is visible" tests when visual regression exists | Let Storybook handle appearance; E2E tests behavior |
| One monolithic `setupAllMocks()` | Each test provides only the interceptors/routes it needs |
| Registering catch-all AFTER mocks (Playwright/Sled 3) | LIFO — catch-all must be registered FIRST |
| Assuming LIFO ordering in Sled 2 | Sled 2 is **FIFO** — first interceptor to match wins |
| `body: JSON.stringify(data)` in `route.fulfill()` | Use `json: data` directly — cleaner (Playwright) |
| `route.continue()` to compose handlers | Use `route.fallback()` — `continue()` sends to network |
| Mocking in `beforeAll` (shared state) | Mock in `beforeEach` or per-test for isolation |
| Forgetting `{ action: Actions.CONTINUE }` in Sled 2 | Always return CONTINUE for non-matching URLs — otherwise handler silently blocks |
| Mixing `page.route()` + `interceptionPipeline` on same URL | Pick one per URL pattern to avoid unpredictable behavior |
| Builders with global counters | Stable defaults, no shared mutable state across tests |
| Separate spec file per story variant | One consolidated spec per component, all variants |
| Deriving story IDs from `name` property | IDs come from **export names** (kebab-cased) — always verify in Storybook |
| Running visual tests on stale `storybook-static` | Rebuild Storybook after adding/renaming stories |
| `npx playwright test` with `defineSledConfig` | Must use `sled-playwright test` — sled config crashes raw Playwright CLI |
| Builders only in E2E directory | Share builders in `src/test/builders/` across unit + E2E |
| `storiesToIgnoreRegex: ['.*']` | `['.*--docs$', '.*-playground$']` -- selective exclusion |
| 10+ tests per component | 2-4 behavioral tests -- visibility is for snapshots |
| Separate test for each button visible + enabled | One test: click button -> verify result |
| No catch-all API blocking in base driver | `await page.route('**/api/**', route => route.abort('blockedbyclient'))` in `setup()` BEFORE mocks |
| Test passes without any `given.*` mocks | Every test MUST mock all API endpoints it touches via `given.*` |
