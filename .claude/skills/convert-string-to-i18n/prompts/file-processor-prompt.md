# File Processor Subagent Prompt Template

Use this template when dispatching a file-processor subagent. Fill in the bracketed placeholders.

```
Task tool (general-purpose):
  description: "i18n: Process [FILE_PATH]"
  prompt: |
    You are replacing hard-coded UI strings with existing Babel translation keys in a single file.

    ## File to Process

    [FILE_PATH]

    ## Available Translation Keys (for this file's namespace)

    [PASTE KEY SUBSET HERE — format: key → englishValue, one per line]
    [Include ICU parameter annotations where applicable]

    ## Framework

    Type: [FRAMEWORK_TYPE]
    Import: [FRAMEWORK_IMPORT_STATEMENT]
    Hook: const { t } = useTranslation();

    ## Namespace Context

    This file is in [DIRECTORY]. Prefer keys from namespace: [NAMESPACE_PREFIX].

    ## Reference Files (read on demand)

    - ICU parameter guide: [ABSOLUTE_PATH_TO_SKILL]/references/icu-guide.md
    - Replacement patterns: [ABSOLUTE_PATH_TO_SKILL]/references/replacement-patterns.md

    Read these files if you need guidance on ICU matching or replacement syntax.

    ## Before You Begin

    If anything is unclear about requirements, matching, or ICU params — **ask now**.

    ## Your Job

    1. **Read the file**
    2. **Identify translatable strings** — JSX text, JSX attrs (placeholder, label, title), UI object props, string constants used in UI, template literals. **Skip**: URLs, CSS, data-testid, data-hook, className, key, id, console/error messages, enum values, config keys, regex, and anything already translated (`t()`, `Trans`, `localeKeys`, `this.props.t()`).
    3. **Match each string to a key** — Exact > near-exact > semantic. Prefer keys from this file's namespace. For ICU: param count must match, use key's param names. Never invent keys. **No match = leave the original string untouched.** Skip with reason (`no_matching_key`, `ambiguous`, `uncertain`, `param_mismatch`, `already_translated`).
    4. **Apply replacements** (bottom-up, last line first) — Add import + hook if missing. Replace with `t('key')` or `t('key', { params })`. For keys with `<0>` tags use `<Trans>`. For class components use `withTranslation` HOC. Match existing code style. **CRITICAL: Every replacement must produce a `t()` or `<Trans>` call. Never replace a string with `undefined`, `null`, `''`, or remove it.**
    5. **Update test file** — Find the matching `.spec.*` / `.test.*` file:
       - For each replaced string, search the test for the same hardcoded string in RTL queries (`getByText`, `findByText`, `queryByText`, `getByRole`) and assertions
       - Replace with the translation key name (e.g., `getByText('verse.foo.save')`)
       - Add a `useTranslation` mock if not already present. Detect the test runner (vi.mock for vitest, jest.mock for jest) by checking devDependencies and existing test patterns. The mock should make `t(key)` return the key.
       - If no test file exists, skip and note in report

    **While you work:** Process all files in your assignment without stopping. Only pause to ask if you hit a genuine blocker (e.g., conflicting key matches, broken file syntax that prevents processing). Do NOT pause to ask "should I continue?" — finish all assigned files, then report.

    ## Before Reporting: Self-Review

    Review your work with fresh eyes before handing off:
    - **Completeness**: Did I find all translatable strings? Missed any? Test file updated?
    - **Quality**: Do all key matches make semantic sense? ICU params correct? Import added?
    - **Discipline**: Did I avoid inventing keys? Only matched what was confident? Did I leave unmatched strings untouched (not replaced with undefined/null)?
    - **No collateral damage**: JSX structure intact? No broken syntax? No string values removed or nullified? Test file still valid?

    If you find issues during self-review, fix them now.

    ## Report

    - Strings replaced: count + list (original → key)
    - Strings skipped: count + list (string → reason)
    - Files changed
    - Self-review findings (if any)
    - Any concerns for reviewer
```
