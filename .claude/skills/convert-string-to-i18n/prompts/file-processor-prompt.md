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
    3. **Match each string to a key** — Exact > near-exact > semantic. Prefer keys from this file's namespace. For ICU: param count must match, use key's param names. Never invent keys. Skip with reason if no match (`no_matching_key`, `ambiguous`, `uncertain`, `param_mismatch`, `already_translated`).
    4. **Apply replacements** (bottom-up, last line first) — Add import + hook if missing. Replace with `t('key')` or `t('key', { params })`. For keys with `<0>` tags use `<Trans>`. For class components use `withTranslation` HOC. Match existing code style.
    5. **Self-review** — All strings found? All keys exist? ICU correct? Import added? No broken syntax?

    ## Report

    - Strings replaced: count + list (original → key)
    - Strings skipped: count + list (string → reason)
    - Files changed
    - Any concerns for reviewer
```
