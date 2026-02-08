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
| One monolithic `setupApiMocks()` | `given.mockApi()` per-endpoint; each test mocks only what it needs |
| Registering catch-all AFTER specific mocks | Playwright routes are LIFO — catch-all must be registered FIRST |
| Builders with global counters | Stable defaults, no shared mutable state across tests |
| Separate spec file per story variant | One consolidated spec per component, all variants |
| Deriving story IDs from `name` property | IDs come from **export names** (kebab-cased) — always verify in Storybook |
| Running visual tests on stale `storybook-static` | Rebuild Storybook after adding/renaming stories |
| `npx playwright test` with `defineSledConfig` | Must use `sled-playwright test` — sled config crashes raw Playwright CLI |
| Builders only in E2E directory | Share builders in `src/test/builders/` across unit + E2E |
