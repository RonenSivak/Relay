# Debugger Processor Prompt

You are debugging a failing Sled 3 E2E test.

## Your Task

Diagnose and fix the failing test: `{TEST_FILE}`
**Error output:** `{ERROR_OUTPUT}`
**Package path:** `{PACKAGE_PATH}`

## Before You Begin

1. Read the failing test file
2. Read the associated driver file(s)
3. Read the error output carefully — identify the exact failure point
4. Categorize the failure using the decision tree below

## Debug Decision Tree

```
Test failed
├── Exact line + assertion failure
│   → Fix the assertion or the code under test
│
├── "Route aborted" or unmocked API
│   → Identify the URL being blocked
│   → Add a given.* mock for that endpoint in the driver
│   → Ensure mock is added BEFORE the catch-all in setup()
│
├── "intercepted pointer events"
│   → An overlay/modal is blocking the click target
│   → Add a wait for the overlay to dismiss
│   → Or dismiss the overlay explicitly before clicking
│
├── Timeout (action or navigation)
│   → Check: does the mock return correct data?
│   → Check: does the page actually load?
│   → Check: is the locator correct? (try getByTestId, getByRole)
│   → Check: is there a missing mock causing the page to hang?
│
├── "Couldn't find story matching..."
│   → Story IDs use EXPORT NAMES (kebab-case), not the name property
│   → Rebuild storybook: yarn build-storybook
│
├── Snapshot mismatch
│   → If intentional change: run --update-snapshots
│   → If unintentional: investigate what changed in the component
│   → Always verify with --remote (local rendering differs)
│
├── defineSledConfig() crash
│   → Prefix command with CI=false
│
└── Other
    → Run with --debug for Playwright Inspector
    → Add page.pause() before the failing line
    → Check trace viewer for timeline of events
```

## Steps

1. **Reproduce:** Run the specific test to confirm the failure
   ```bash
   CI=false npx sled-playwright test {TEST_FILE} 2>&1 | tail -50
   ```

2. **Diagnose:** Read error output and categorize using the decision tree

3. **Fix:** Apply the appropriate fix:
   - Missing mock → Add `given.*` method to driver and use in test
   - Wrong locator → Fix the selector in the driver
   - Timing issue → Replace `waitForTimeout` with proper wait condition
   - Assertion wrong → Update assertion or fix the test logic
   - Infrastructure → Fix config, imports, or setup

4. **Verify:** Run the test again to confirm the fix
   ```bash
   CI=false npx sled-playwright test {TEST_FILE} 2>&1 | tail -50
   ```

5. **Check for side effects:** Run the full suite to ensure no regressions
   ```bash
   CI=false npx sled-playwright test 2>&1 | tail -30
   ```

## Common Fixes

| Issue | Fix |
|-------|-----|
| Missing API mock | Add `given.*` method in driver; call before `setup()` |
| `interceptors.push()` used | Replace with adding to the array before `setup()` call |
| `waitForTimeout` | Replace with `expect(locator).toBeVisible()` or `expect.poll()` |
| Wrong selector | Use `getByRole`/`getByTestId` instead of CSS |
| Stale storybook | Run `yarn build-storybook` |
| Local-only failure | Try `--remote`; check if `CI=false` is needed |

## Self-Review

- [ ] Root cause identified and documented
- [ ] Fix applied
- [ ] Test passes after fix
- [ ] No regressions in other tests
- [ ] No `waitForTimeout` introduced
- [ ] No raw selectors added to spec files
