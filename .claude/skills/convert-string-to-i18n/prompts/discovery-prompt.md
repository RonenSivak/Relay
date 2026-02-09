# Discovery Subagent Prompt Template

Use this template when dispatching a discovery subagent for Steps 1-2. This is a **read-only** agent that scans the codebase and returns structured data for plan building.

**Dispatch this FIRST, before any file processing.**

```
Task tool (generalPurpose):
  description: "i18n: Discover files & keys"
  model: fast
  prompt: |
    You are a fast discovery agent for i18n string replacement. Scan the codebase
    and return structured data. Do NOT modify any files.

    ## Project Root

    [PROJECT_ROOT_PATH]

    ## Scope (optional)

    [SCOPE_PATH_OR_EMPTY]

    ## Reference Files (read on demand)

    - Skill definition: [ABSOLUTE_PATH_TO_SKILL]/SKILL.md

    ## Your Job

    ### 1. Load Babel Config
    Find `babel_config.json` in the project root. Extract projectId, projectName, langFilePath.
    If not found, report what's missing.

    ### 2. Load & Index Translation Keys
    **Use Bash (not Read)** — messages_en.json is often too large for the Read tool's token limit.
    ```bash
    node -e "const k=require('<path>/messages_en.json'); for(const[n,v]of Object.entries(k)) console.log(n+' → '+(typeof v==='string'?v:JSON.stringify(v)))"
    ```
    Build key index from the output: { keyName → englishValue }.
    Flag ICU keys (containing {param} placeholders) with parameter names and count.
    If missing → report the error.

    ### 3. Build Namespace Map
    - Group keys by first 2 namespace segments
    - Grep for existing `t('namespace.` patterns to learn directory→namespace mapping
    - Map component directory names to namespace segments

    ### 4. Detect Framework
    Check package.json dependencies (priority): yoshi-flow-bm > fe-essentials-standalone >
    fe-essentials > wix-i18n-config > fed-cli-i18next.
    Check infra readiness (translations.enabled, i18n.messages config).

    ### 5. Find Candidate Files
    Run the scanner script to get the candidate file list:
    ```bash
    node [ABSOLUTE_PATH_TO_SKILL]/scripts/scan-ui-strings.cjs [SCOPE_OR_SRC_DIR]
    ```
    The script detects JSX text, JSX attrs, string literals, filters out code-like strings,
    and outputs a markdown table sorted by estimated string count.
    Use the script output directly. For each candidate, identify the likely namespace.

    ### 6. Check Already-Translated Coverage
    Note files already using t(), Trans, localeKeys, useLocaleKeys.
    Flag dominantly-translated files as low-priority.

    ## Report Format

    Return a structured report with these sections:
    - Babel Config (projectId, projectName, langFilePath)
    - Translation Keys (total count, ICU count, namespace prefixes)
    - Framework (type, import statement, infra ready yes/no)
    - Namespace Map (prefix → directories)
    - Candidate Files table (file, est. strings, namespace, already translated, priority)
    - Summary (total candidates, estimated strings, partially translated count)
```
