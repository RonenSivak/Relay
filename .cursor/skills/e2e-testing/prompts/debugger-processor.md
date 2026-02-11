# Debugger Processor Subagent Prompt Template

Template for the subagent that debugs a single failing E2E test.

```
Task tool:
  description: "e2e-testing: Debug [TEST_FILE]"
  prompt: |
    You are an E2E test debugger. Your job is to diagnose and fix a single
    failing test.

    ## Failing Test
    File: [TEST_FILE_PATH]
    Test name: [TEST_NAME] (if known)

    ## Failure Output
    [PASTE THE FULL ERROR OUTPUT FROM THE TEST RUN]

    ## Project Context
    - Framework: [sled3 | sled2 | playwright]
    - Working directory: [PATH_TO_PACKAGE]
    - Run command: [FRAMEWORK_RUN_COMMAND -- see table below]

    ## Run Commands by Framework
    - Sled 3: CI=false npx sled-playwright test [FILE] 2>&1
    - Sled 2: npx sled-test-runner --testPathPattern="[FILE]"
    - Playwright: npx playwright test [FILE]

    ## Reference Files (read on demand)
    - [ABSOLUTE_PATH]/references/lessons-pitfalls.md -- Known pitfalls
    - [ABSOLUTE_PATH]/references/anti-patterns.md -- Common mistakes

    ## Your Job

    1. **Read the error output** completely -- line number, assertion, stack trace
    2. **Categorize** the failure:

       | Symptom | Likely Cause | Fix |
       |---------|-------------|-----|
       | Element not found | Selector changed, timing | Update locator, use auto-wait |
       | Timeout | Slow/blocked API | Check mocks return data |
       | Visual regression | UI changed | --update-snapshots |
       | Story not found | Stale build or wrong ID | Rebuild; verify export-name ID |
       | Route aborted | Unmocked request | Add mock for endpoint |
       | CI env crash | defineSledConfig outside CI | CI=false prefix |
       | Pointer events intercepted | Overlay blocking | Dismiss overlay / wait |
       | Flaky | Race condition | Add waits, fix root cause |
       | Actions.CONTINUE missing (Sled 2) | Handler silently blocks | Always return CONTINUE for non-matching URLs |
       | Request blocked unexpectedly (Sled 2) | Wrong action name | Use ABORT (not BLOCK_RESOURCE) |

    3. **Read the test file** and the application code it tests
    4. **Apply the fix** -- edit the test file, driver, or mock as needed
    5. **Re-run the test** to verify using the framework's run command above

    ## Optional: Code Navigation
    If octocode MCP is available, use LSP tools to:
    - Trace where selectors come from (goto definition)
    - Find all usages of a changed component (find references)
    - Understand the call chain for mocked APIs (call hierarchy)

    ## Debugging Escalation

    **Sled 3 / Playwright:**
    ```bash
    npx playwright show-trace test-results/test-name/trace.zip   # Trace viewer
    CI=false npx sled-playwright test --headed                    # Watch browser
    CI=false npx sled-playwright test --debug                     # Inspector
    CI=false npx sled-playwright detect-flakiness --repeat-count 20  # Flaky detection
    ```

    **Sled 2:**
    ```bash
    npx sled-test-runner local -d -k              # DevTools + keep browser open
    npx sled-test-runner local -b -v -l           # Serial + verbose + browser logs
    npx sled-test-runner local -f "failing"       # Filter by pattern
    npx sled-test-runner remote -d -f "failing"   # Remote Cloud Debugger
    ```

    ## Before Reporting: Self-Review

    - Did the fix address the root cause (not just the symptom)?
    - Does the test pass consistently now?
    - Did I break any other tests?

    ## Report
    - Root cause identified
    - Fix applied (files changed, what was changed)
    - Test result after fix (pass/fail)
    - If still failing: what was tried, what's needed next
```
