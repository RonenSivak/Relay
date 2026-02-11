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
    2. Verify spec covers: happy path, error states, edge cases
    3. Verify driver follows conventions (stateless, pass page per method)
    4. Check selector priority is followed
    5. Check mock strategy (per-test, not monolithic)
    6. Verify route ordering (LIFO for Playwright/Sled 3, FIFO for Sled 2)
    7. Check builders have stable defaults, no global counters
    8. Look for collateral damage to existing tests

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
