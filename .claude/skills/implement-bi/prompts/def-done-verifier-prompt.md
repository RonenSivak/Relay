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
    - BI_CONSTANTS file: [path]
    - Modified files: [list all files modified during implementation]

    ## Your Job

    Check each criterion by reading the actual code. For each:

    1. **Hook functions exist**
       - Read each hook file
       - Confirm every event has a `report[EventName]` function

    2. **Import paths correct**
       - Functions from `@wix/[logger]/v2`
       - Types from `@wix/[logger]/v2/types`
       - Testkit from `@wix/[logger]/testkit/client` (scoped) or `[logger]/testkit` (bare alias)

    3. **Component wiring correct**
       - Each event's BI call exists in the correct component
       - BI fires AFTER described action success
       - Hook initialized at component level

    4. **Field propagation & constants**
       - All required schema fields reachable at BI call site
       - Dynamic fields use their classified source (props/state/context/computed)
       - Static properties imported from `BI_CONSTANTS` — NOT hardcoded at call sites
       - Props interfaces updated
       - Parent components pass fields down

    5. **Tests exist and are correct**
       - Each event has a test in its own test file or nearest ancestor test
       - No isolated BI-only test files
       - Testkit imported BEFORE component import
       - Testkit event name: `biTestKit.{eventNameCamelCase}Src{src}Evid{evid}`
       - Reset in `beforeEach`
       - Assertion for each event

    6. **Build health**
       - Run `yarn tsc --noEmit` — check for type errors
       - Run `yarn lint` on modified files — check for lint errors
       - Run `yarn test --testNamePattern="BI"` — check tests pass

    ## Report

    ## Per-Interaction Validation (REQUIRED)

    For EACH event, verify individually and record:
    - Hook: `path:line` where `report[EventName]` exists
    - Component: `path:line` where BI call is wired
    - Test: `path:line` where assertion exists
    - Status: `complete` | `missing-implementation` | `missing-tests` | `failed`

    A flat "all tests pass" without per-event evidence is not acceptable.

    ## Criteria Report

    For each criterion, report:
    - **PASS**: criterion met, with brief evidence
    - **FAIL**: criterion not met, with file/line and what's wrong

    Final verdict: **ALL PASS** or **FAILURES FOUND** (with fix instructions)
