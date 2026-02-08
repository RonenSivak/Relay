# Def-Done Verifier Subagent Prompt Template

Use this template when dispatching the final def-done verification subagent after all files are processed and lint passes.

**Purpose:** Independently verify that every criterion in def-done.md is met by checking the actual codebase. This is the final gate — nothing ships until this passes.

**Only dispatch after all files are processed and lint passes.**

```
Task tool (general-purpose):
  description: "i18n: Verify definition of done"
  prompt: |
    You are the final verification gate for an i18n string replacement workflow.
    Your job is to independently check every criterion in the definition of done
    against the actual codebase. Do not trust any previous reports.

    ## Definition of Done

    [PASTE def-done.md CONTENT HERE]

    ## Plan

    [PASTE plan.md CONTENT HERE — includes file list with statuses]

    ## Modified Files

    [LIST ALL FILES MODIFIED DURING THE WORKFLOW]

    ## Babel Key Index

    [PASTE FULL KEY INDEX — or the subset used across all files]

    ## Framework

    Type: [FRAMEWORK_TYPE]
    Import: [FRAMEWORK_IMPORT_STATEMENT]

    ## CRITICAL: Trust Nothing, Verify Everything

    Previous subagents may have made mistakes, missed files, or reported
    incorrectly. You MUST check the actual codebase independently.

    ## Your Job: Check Each Criterion

    Go through every item in the Definition of Done. For each one, check the
    actual code and report PASS or FAIL with evidence.

    ### 1. Every candidate file processed
    - Read plan.md file list
    - Check that every file has status `completed` or `skipped`
    - If any file is still `pending` → FAIL
    - For `skipped` files: verify a skip reason is documented

    ### 2. All replacements use existing babel keys only
    - In each modified file, find every `t('...')` call
    - Extract the key string from each call
    - Cross-reference against the babel key index
    - If ANY key is not in the index → FAIL (invented key)

    ### 3. ICU parameters correctly mapped
    - For each `t('key', { ... })` call:
      - Look up the key in the babel key index
      - Parse the ICU placeholders from the key's English value
      - Verify parameter names in the `t()` call match the ICU template
      - Verify parameter count matches
    - If any mismatch → FAIL

    ### 4. useTranslation hook + import in every modified component
    - In each modified file that contains `t()` calls:
      - Verify `useTranslation` is imported
      - Verify `const { t } = useTranslation()` exists in the component body
    - If missing in any file → FAIL

    ### 5. Correct framework import path
    - Every `useTranslation` import must use: [FRAMEWORK_IMPORT_STATEMENT]
    - If any file uses a different import path → FAIL

    ### 6. Lint passes
    - Confirm that lint was run and passed (master handles this before dispatching you)
    - If you can run linter: `npx eslint [modified files]`
    - If new lint errors exist → FAIL

    ### 7. No TypeScript compilation errors
    - If you can run: `npx tsc --noEmit` (scoped to modified files if possible)
    - Or check for obvious type errors in the modified code
    - If compilation errors → FAIL

    ### 8. Skipped strings documented
    - For each file where strings were skipped:
      - Verify the processor report includes skip reasons
      - Each skipped string must have a reason (no_matching_key, ambiguous, etc.)
    - If any skipped string lacks a reason → FAIL

    ### 9. plan.md fully updated
    - No files left as `pending`
    - All files marked `completed` or `skipped`
    - If any pending → FAIL

    ## Report Format

    ```
    # Def-Done Verification Report

    | # | Criterion | Status | Evidence |
    |---|-----------|--------|----------|
    | 1 | Every candidate file processed | PASS/FAIL | [details] |
    | 2 | All keys exist in index | PASS/FAIL | [details] |
    | 3 | ICU parameters correct | PASS/FAIL | [details] |
    | 4 | useTranslation hook present | PASS/FAIL | [details] |
    | 5 | Correct framework import | PASS/FAIL | [details] |
    | 6 | Lint passes | PASS/FAIL | [details] |
    | 7 | No TypeScript errors | PASS/FAIL | [details] |
    | 8 | Skipped strings documented | PASS/FAIL | [details] |
    | 9 | plan.md fully updated | PASS/FAIL | [details] |

    ## Final Verdict: **PASS** / **FAIL**

    [If FAIL: list specific gaps with file:line references]
    ```
```
