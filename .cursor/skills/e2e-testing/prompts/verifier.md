# Verifier Subagent Prompt Template

Final verification gate for the entire E2E testing workflow.

```
Task tool:
  description: "e2e-testing: Verify definition of done"
  prompt: |
    You are the final gate. Check every criterion in def-done.md against
    the actual state of the codebase. Trust nothing from previous reports.

    ## Definition of Done
    [PASTE def-done.md CONTENT]

    ## Plan
    [PASTE plan.md WITH CURRENT STATUSES]

    ## Working Directory
    [PATH_TO_PACKAGE]

    ## Your Job

    For each criterion in def-done.md:

    1. **Read the actual code** -- don't rely on processor/reviewer reports
    2. **Verify the criterion is met** with evidence
    3. **Report PASS or FAIL** with specific evidence

    ### Gate 1 -- BDD Pattern Compliance (grep-based)

    Run these commands in the e2e test directory. ALL must return 0 matches:

    ```bash
    # Spec files must not access page directly
    grep -rn "driver\.page\|\.page\." --include="*.spec.ts" . | grep -v node_modules
    # Must return 0 matches. If any: FAIL

    # No raw selectors in spec files
    grep -rn "data-hook=\|locator(\|waitForSelector\|page\.evaluate" --include="*.spec.ts" . | grep -v node_modules
    # Must return 0 matches. If any: FAIL

    # No waitForTimeout anywhere (except storybook plugin config)
    grep -rn "waitForTimeout" --include="*.spec.ts" --include="*.driver.ts" . | grep -v node_modules | grep -v "delayBeforeTakingImage"
    # Must return 0 matches. If any: FAIL

    # No conditional logic in specs
    grep -n "if (" --include="*.spec.ts" . | grep -v node_modules
    # Must return 0 matches inside test()/it() blocks. If any: FAIL
    ```

    ### Gate 2 -- API / Communication Mocking

    - [ ] **Catch-all blocking installed**: Grep base driver for `ABORT` or `route.abort` -- must exist in `setup()` method
    - [ ] **Existing infrastructure reused**: Search test dir for existing interceptors (`interceptPostMessage`, `createInterceptor`, etc.). If found, verify they are used in drivers -- NOT reinvented via custom `page.evaluate()`
    - [ ] **Framework-correct pattern**: Sled 3 = `interceptionPipeline`, Sled 2 = `InterceptionTypes.Handler`, Playwright = `page.route`, PostMessage = `addInitScript` + existing interceptor
    - [ ] **Every API mocked**: Each `given.*` method installs a mock. No test relies on real backend responses

    ### Gate 3 -- Test Substance (read each test)

    For every `test()` / `it()` block in `*.spec.ts` files:
    1. Does it call at least one `driver.when.*` method (user interaction)?
    2. Does it have an `expect()` that asserts a state CHANGE (not just `toBeVisible`)?
    3. If test only does: navigate/render -> `toBeVisible` with no interaction: **FAIL**
    4. If test clicks something but has no `expect()` on the result: **FAIL**
    5. Count visibility-only tests: MUST be 0

    ```bash
    # Quick heuristic: find tests with only toBeVisible/isVisible assertions
    grep -B5 "toBeVisible\|isVisible" --include="*.spec.ts" . | grep -v "when\.\|click\|fill\|type\|select\|check\|press"
    # Review each match -- if no prior interaction: FAIL
    ```

    ### Gate 4 -- Full-flow test (if user selected)

    - [ ] At least 1 test walks through ALL steps of the primary user journey (multiple steps/pages)
    - [ ] Final assertion verifies end result (not intermediate visibility)
    - [ ] Single-component "renders" tests don't count

    ### Gate 5 -- Budget and Scope

    - [ ] **Test budget**: Count hand-written tests. If > 4 per component or > 20 total: FAIL
    - [ ] **storiesToIgnoreRegex audit**: Read playwright.config.ts. If set to `['.*']`: FAIL
    - [ ] **No lint errors**: Check test files for obvious issues
    - [ ] **No collateral damage**: Verify existing tests still pass

    ### Infrastructure Checks

    - [ ] **Infrastructure detected**: Spot-check one detection claim against actual package.json
    - [ ] **Shared infrastructure created**: Base driver, builders exist and follow conventions
    - [ ] **Tests pass locally**: Run per detected framework (see commands below), verify exit code 0

    ### Run Commands (use per detected framework)
    ```bash
    # Sled 3: Verify tests pass
    CI=false npx sled-playwright test 2>&1 | tail -30

    # Sled 2: Verify tests pass
    npx sled-test-runner 2>&1 | tail -30

    # Standalone Playwright: Verify tests pass
    npx playwright test 2>&1 | tail -30

    # Check for lint issues (if available)
    npx eslint "e2e/**/*.ts" 2>&1 | tail -20
    ```

    ## Report

    For each criterion:
    ```
    [criterion]: PASS | FAIL
    Evidence: [what you checked and found]
    ```

    Final verdict: **ALL PASS** or **GAPS FOUND** (list gaps for master to fix)
```
