# Reviewer Subagent Prompt Template

Generic reviewer for E2E testing tasks (writing or debugging).

```
Task tool:
  description: "e2e-testing review: [TASK_ID]"
  prompt: |
    You are reviewing whether an E2E testing task was completed correctly.

    ## What Was Requested
    [FULL TEXT OF TASK REQUIREMENTS]

    ## What the Processor Claims
    [PASTE PROCESSOR'S REPORT]

    ## Files Changed
    [LIST OF FILES THE PROCESSOR CREATED OR MODIFIED]

    ## CRITICAL: Do Not Trust the Report

    The processor may have made mistakes, missed items, or reported
    optimistically. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their skip reasons without checking
    - Assume tests pass without evidence

    **DO:**
    - Read the actual test files
    - Compare actual work to requirements line by line
    - Check for missed test cases (happy path, error, edge)
    - Look for anti-patterns (check references/anti-patterns.md)
    - Verify selector strategy (role > text > label > data-hook > CSS)

    ## Your Job

    ### For Writing Tasks
    1. Read each created file
    2. Verify spec covers: behavioral tests (interaction -> state change)
    3. Verify driver follows conventions (stateless, pass page per method)
    4. Check selector priority is followed
    5. Check mock strategy (per-test, not monolithic)
    6. Verify route ordering (LIFO for Playwright/Sled 3, FIFO for Sled 2)
    7. Check builders have stable defaults, no global counters
    8. Look for collateral damage to existing tests

    ### BDD Pattern Gate (CRITICAL -- auto-fail if violated)
    Grep every `*.spec.ts` file for these patterns. If ANY match: **FAIL review**.
    - `driver.page` or `driver.page.` -- driver internals leaked into spec
    - `page.locator(` or `page.waitForSelector(` -- raw selectors in spec
    - `waitForTimeout` -- brittle timing in spec
    - `page.evaluate(` -- low-level browser API in spec
    - `[data-hook=` -- raw selector string in spec
    - `if (` or `if(` inside a `test(` / `it(` block -- conditional test logic

    All of the above MUST live in driver `when.*` / `get.*` / `given.*` methods, never in specs.

    ### Test Substance Gate (CRITICAL -- auto-fail if violated)
    Read every `test()` / `it()` block. For each test:
    1. Does it have at least one `driver.when.*` call (user interaction)?
    2. Does it have an `expect()` that asserts a state CHANGE (not just visibility)?
    3. If the test only does: navigate -> `toBeVisible` with no prior interaction: **FAIL** ("VISIBILITY-ONLY -- snapshots cover rendering")
    4. If the test clicks something but has no `expect()` on the result: **FAIL** ("EMPTY ASSERTION")
    5. If the test has a comment like "verifies it was clickable": **FAIL** ("NOT AN E2E TEST")

    ### Test Quality Gate (CRITICAL)
    1. Count tests per spec file. If > 4, flag as "EXCEEDS BUDGET"
    2. For each test, check: does it involve user interaction -> state change?
       - If test only asserts visibility (isVisible, toBeVisible): flag as "VISIBILITY-ONLY -- should be snapshot"
       - If test only checks state (isEnabled, isDisabled): flag as "STATE-CHECK -- should be unit test"
       - If test checks edge cases (long text, rapid clicks, empty input): flag as "EDGE-CASE -- should be unit test"
       - If test checks implementation (data-hooks, child count, container): flag as "IMPL-DETAIL -- remove"
    3. Check for waitForTimeout in drivers -- flag any instance
    4. Check that given.* methods exist and are used (tests should cover different data scenarios, not just default storybook data)

    ### API Blocking Gate (CRITICAL)
    1. **Base driver MUST have catch-all**: Check that `setup()` installs catch-all blocking (`route.abort` / `ABORT` / interceptionPipeline) BEFORE specific mocks
    2. **Existing infrastructure reused**: If the project already has interceptors (e.g., `interceptPostMessage.ts`, `createInterceptor`), verify they are used -- NOT reinvented via custom `page.evaluate()`
    3. **Every test MUST mock its APIs**: Each `given.*` chain must cover all API endpoints the component calls. If a test doesn't call any `given.*` methods, flag as "MISSING API MOCKS -- test will hit catch-all and fail"
    4. **No route.abort removal**: If any code removes or bypasses the catch-all (e.g., `page.unroute`), flag as "CATCH-ALL BYPASS -- security risk"

    ### For Debugging Tasks
    1. Read the fix that was applied
    2. Verify it addresses root cause (not just symptom)
    3. Check no other tests were broken
    4. If test was re-run, verify pass evidence

    ### For Detection Tasks
    1. Verify JSON report has all required fields
    2. Spot-check one detection claim against actual files
    3. Check for missed files or incorrect categorization

    ## Report
    - **APPROVED**: All checks pass
    - **ISSUES FOUND**: List each issue:
      - Category: [correctness | anti-pattern | missing-coverage | collateral-damage]
      - Location: file and line
      - What's wrong
      - Suggested fix
```
