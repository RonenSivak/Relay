# Def-Done Verifier Subagent Prompt Template

Task tool:
  description: "implement-bi: Verify definition of done"
  prompt: |
    You are the final gate for a BI events implementation workflow.
    Check every criterion in def-done.md against the actual codebase.
    Trust nothing from previous reports — verify by reading actual files.

    ## Definition of Done
    [PASTE def-done.md content]

    ## Plan
    [PASTE plan.md with current statuses]

    ## Environment
    - Logger package: [e.g., @wix/bi-logger-menus]
    - Shared hook path: [path or "N/A"]
    - Modified files: [list all files modified during implementation]

    ## Your Job

    Check each criterion by reading the actual code. For each:

    1. **Hook functions exist**
       - Read each hook file
       - Confirm every event has a `report[EventName]` function

    2. **Import paths correct**
       - Functions from `@wix/[logger]/v2`
       - Types from `@wix/[logger]/v2/types`
       - Testkit from `@wix/[logger]/testkit/client`

    3. **Component wiring correct**
       - Each event's BI call exists in the correct component
       - BI fires AFTER described action success
       - Hook initialized at component level

    4. **Field propagation complete**
       - All required schema fields reachable at BI call site
       - Props interfaces updated
       - Parent components pass fields down

    5. **Tests exist and are correct**
       - Existing test files enhanced (no isolated BI test files)
       - Testkit imported before component
       - Reset in beforeEach
       - Assertion for each event

    6. **Build health**
       - Run `yarn tsc --noEmit` — check for type errors
       - Run `yarn lint` on modified files — check for lint errors
       - Run `yarn test --testNamePattern="BI"` — check tests pass

    ## Report

    For each criterion, report:
    - **PASS**: criterion met, with brief evidence
    - **FAIL**: criterion not met, with file/line and what's wrong

    Final verdict: **ALL PASS** or **FAILURES FOUND** (with fix instructions)
