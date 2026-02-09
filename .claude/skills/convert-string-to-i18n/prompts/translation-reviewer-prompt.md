# Translation Reviewer Subagent Prompt Template

Use this template when dispatching a translation-reviewer subagent after a file-processor completes.

**Purpose:** Verify the file-processor made correct replacements (right keys, right params, nothing missed, nothing broken).

**Only dispatch after file-processor reports completion.**

```
Task tool (general-purpose):
  description: "i18n review: [FILE_PATH]"
  prompt: |
    You are reviewing whether i18n string replacements in a single file are correct.

    ## File Reviewed

    [FILE_PATH]

    ## Available Translation Keys (for this file's namespace)

    [PASTE SAME KEY SUBSET given to file-processor]

    ## What the File-Processor Claims

    [PASTE FILE-PROCESSOR REPORT HERE]

    ## CRITICAL: Do Not Trust the Report

    The file-processor may have made mistakes: wrong keys, missed strings, broken JSX,
    incorrect ICU parameters. You MUST verify everything independently by reading the
    actual modified file.

    **DO NOT:**
    - Take their word for which keys they matched
    - Trust their skip reasons without checking
    - Accept their claim that all strings were found

    **DO:**
    - Read the actual modified file
    - Compare every `t()` call against the key subset
    - Look for remaining untranslated UI strings
    - Verify JSX structure is intact

    ## Your Job

    Read the modified file and verify:

    ### 1. Key Correctness
    For every `t('key')` call in the file:
    - Does the key exist in the provided key subset?
    - Does the key's English value semantically match the original string it replaced?
    - If you can infer the original string from context, does the match make sense?

    ### 2. ICU Parameter Correctness
    For every `t('key', { ... })` call:
    - Do the parameter names match the ICU template in the key's value?
    - Does the parameter count match?
    - Are code expressions mapped to the right ICU parameter names?

    ### 3. No Invented Keys
    - Every key referenced in `t()` must exist in the provided key subset
    - Zero tolerance: even one invented key = FAIL

    ### 4. Import Correctness
    - `useTranslation` import exists and uses the correct framework path
    - `const { t } = useTranslation()` is in the component body
    - Import is not duplicated

    ### 5. No Missed Strings
    Scan the file for remaining untranslated UI text:
    - JSX text content (text between tags)
    - JSX attributes: placeholder, label, title, subtitle, content, buttonText
    - UI object properties with string literals

    If you find missed strings:
    - Check if a matching key exists in the subset
    - If yes → flag as missed (processor should have caught it)
    - If no matching key → acceptable skip (note it)

    ### 6. No Destructive Replacements
    Scan for strings that were replaced with `undefined`, `null`, `''`, or removed entirely:
    - Every `t()` call site should have previously been a hardcoded string
    - If a prop/variable that previously held a string now holds `undefined` or `null`, flag it — the processor likely failed to match a key and destructively removed the value instead of leaving it
    - This is a **critical** issue (category: `destructive_replacement`)

    ### 7. No Collateral Damage
    - JSX structure is intact (no broken tags, missing braces)
    - No TypeScript syntax errors visible
    - Code style is preserved (indentation, quotes)

    ### 7. Test File Updated
    If a test file exists for this source file (`.spec.*` / `.test.*`):
    - Are hardcoded strings that were replaced in the source also replaced in the test?
    - Do RTL queries (`getByText`, `findByText`, `queryByText`) now use the key name?
    - Is `useTranslation` properly mocked (using the project's test runner — `vi.mock`/`jest.mock`/etc., returning `t: key => key`)?
    - If no test file exists: was this noted in the processor's report?

    ## Report Format

    - APPROVED: All checks pass, replacements are correct
    - ISSUES FOUND: List each issue with:
      - Category (key_incorrect / param_mismatch / invented_key / missing_import / missed_string / broken_jsx / destructive_replacement)
      - File location (line number or code snippet)
      - What's wrong
      - Suggested fix
```
