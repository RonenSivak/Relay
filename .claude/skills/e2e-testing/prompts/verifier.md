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

    ### Verification Checks

    - [ ] **Infrastructure detected**: Read the detection report, spot-check
          one claim against actual package.json
    - [ ] **Framework identified**: Verify the detected framework matches
          actual devDependencies
    - [ ] **Test patterns analyzed**: If existing tests found, verify the
          new tests match their style
    - [ ] **Shared infrastructure created**: Check app.driver.ts and
          builders exist and follow conventions
    - [ ] **Per-feature specs written**: Each feature has spec + driver +
          builder (if needed). Check coverage: happy path + error + edge
    - [ ] **Tests pass locally**: Run the appropriate command per framework:
          Sled 3: `CI=false npx sled-playwright test 2>&1 | tail -30`
          Sled 2: `npx sled-test-runner 2>&1 | tail -30`
          Playwright: `npx playwright test 2>&1 | tail -30`
          Verify exit code 0
    - [ ] **Visual regression added**: If Storybook detected, verify
          Sled 3: `@wix/playwright-storybook-plugin` configured
          Sled 2: `storybook-sled-e2e.json` configured
    - [ ] **No lint errors**: Check test files for obvious issues
    - [ ] **No collateral damage**: Verify existing tests still pass

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
