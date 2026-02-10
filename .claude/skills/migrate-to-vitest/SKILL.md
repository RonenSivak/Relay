---
name: migrate-to-vitest
description: Migrates test infrastructure from Jest to Vitest in Wix projects. Detects project type (serverless, yoshi-flow-bm, editor-flow, fed-cli, standalone), checks for known blockers, generates a migration plan with user approval, then executes config + test file transforms. Adaptive parallel execution for test files. Backed by real Wix production examples from 8+ repos. Use when the user says "migrate to vitest", "switch to vitest", "replace jest with vitest", "vitest migration", or wants to modernize their test setup.
compatibility: Works with Wix Serverless (@wix/serverless-jest-config), yoshi-flow-bm (jest-yoshi-preset), FED CLI (@wix/fed-cli-vitest), and standalone Jest projects. Requires octocode MCP for detection. context7 MCP optional for latest Vitest docs.
---

# Migrate to Vitest

Migrates a project's test infrastructure from Jest to Vitest, with full awareness of Wix-specific patterns and blockers.

## Execution Strategy

**Parallel subagents for test file transforms.** Config and setup changes are sequential (Phase 1-2), test file transforms run in parallel (Phase 3).

1. After Step 2 (plan approval) -> dispatch subagents for test file batches
2. Group test files by directory
3. Independent directories -> dispatch subagents in parallel (up to 4 concurrent)
4. `resource_exhausted` at runtime -> fall back to direct sequential mode

## Prerequisites

**MCP servers used:**

- `octocode` -- `localSearchCode`, `localViewStructure`, `localFindFiles` for detection and analysis
- `context7` (optional) -- Query latest Vitest docs for unfamiliar API patterns at runtime

**References (read as needed during execution):**

- [references/jest-to-vitest-transforms.md](references/jest-to-vitest-transforms.md) -- API mapping table
- [references/project-type-configs.md](references/project-type-configs.md) -- Config templates per project type with before/after
- [references/wix-specific-gotchas.md](references/wix-specific-gotchas.md) -- Known blockers and workarounds

## Input

The user provides **one of**:

1. **A directory path** -- the package or project root to migrate
2. **Nothing** -- detect from current workspace root

If the project is a monorepo, ask which package(s) to migrate.

---

## Step 1 -- Detection and Analysis

### 1.1 Run detection script

Run `scripts/detect-test-framework.sh` from the skill directory against the target path. It outputs JSON:

```json
{
  "framework": "jest",
  "projectType": "serverless|yoshi-flow-bm|editor-flow|fed-cli|standalone",
  "jestConfig": "jest.config.js",
  "packageJson": "package.json",
  "testFileCount": 42,
  "hasTypeModule": false,
  "blockers": []
}
```

If `framework` is already `vitest`, inform user and stop.

### 1.2 Scan for test patterns

Use octocode `localSearchCode` to find Jest-specific patterns in test files:

```
jest.mock(     -> needs vi.mock()
jest.fn(       -> needs vi.fn()
jest.spyOn(    -> needs vi.spyOn()
jest.requireActual(  -> needs vi.importActual() (ASYNC!)
jest.useFakeTimers(  -> needs vi.useFakeTimers()
jest.advanceTimersByTime(  -> needs vi.advanceTimersByTime()
jest.clearAllMocks(  -> needs vi.clearAllMocks()
jest.resetModules(   -> needs vi.resetModules()
@jest-environment    -> needs vitest environment comment
```

Count occurrences and categorize:
- **Simple renames** (jest.fn -> vi.fn, jest.mock -> vi.mock, etc.)
- **Async transforms** (jest.requireActual -> await vi.importActual)
- **Module factory changes** (jest.mock with factory -> vi.mock with factory, may need vi.hoisted)

### 1.3 Blocker checks

Read [references/wix-specific-gotchas.md](references/wix-specific-gotchas.md) and check:

| Blocker | How to detect | Severity |
|---------|--------------|----------|
| Stylable (.st.css) | `localSearchCode` for `.st.css` imports or `wix-style-react` in deps | **HARD BLOCKER** -- must migrate WSR -> WDS first |
| Yoshi monorepo conflicts | Multiple `yoshi-flow-*` packages in workspace | **WARNING** -- vitest in one package may crash Storybook in another |
| wix-testkit-base / ambassador-testkit | Check devDependencies | **WORKAROUND AVAILABLE** -- will add setup file fix |
| yoshi-flow-bm ESM incompatibility | `@wix/yoshi-flow-bm` in dependencies + heavy yoshi test infra usage | **WARNING** -- may need to decouple from yoshi test infra first |

If a **HARD BLOCKER** is found, inform user and stop with explanation.

For **WARNINGs**, include them in the plan and let the user decide whether to proceed.

### 1.4 Produce analysis summary

Display to user:
- Project type detected
- Test file count and pattern breakdown
- Blockers/warnings found
- Estimated complexity (simple / moderate / complex)

---

## Step 2 -- Plan Generation

### 2.1 Create plan.md

Generate a `plan.md` file in the project root with migration tasks:

```markdown
# Vitest Migration Plan

## Project: {name}
## Type: {projectType}
## Test files: {count}

### Phase 1 - Configuration (sequential)
- [ ] Create vitest.config.ts
- [ ] Update tsconfig.json
- [ ] Update package.json (deps + scripts)
- [ ] Remove jest config files

### Phase 2 - Setup Files (sequential)
- [ ] Convert spec-setup / test-setup files
- [ ] Add wix-testkit-base workaround (if needed)

### Phase 3 - Test File Transforms ({count} files)
- [ ] {directory}: {n} files -- {complexity}
...

### Phase 4 - Cleanup
- [ ] Remove jest devDependencies
- [ ] Verify no remaining jest.* references
- [ ] Run vitest and compare test count
```

### 2.2 Create def-done.md

```markdown
# Definition of Done

- [ ] All test files use vi.* instead of jest.*
- [ ] vitest.config.ts exists and uses correct project template
- [ ] jest.config.js/ts deleted
- [ ] package.json: jest deps removed, vitest deps added
- [ ] package.json scripts: "test" runs vitest
- [ ] No remaining jest.* imports or globals in test files
- [ ] vitest run passes (same test count as before)
- [ ] TypeScript compiles without errors
```

### 2.3 User approval gate

**STOP and present the plan to the user.** Migration is destructive -- do not proceed without explicit approval.

---

## Step 3 -- Execute

### Phase 1 - Configuration (sequential)

Read [references/project-type-configs.md](references/project-type-configs.md) for the correct template.

**Detect project type and apply the right config:**

#### Wix Serverless (has `@wix/serverless-jest-config` in devDependencies)

This is the simplest migration path. An official `@wix/serverless-vitest-config` package exists.

1. Create `vitest.config.ts`:
   ```typescript
   export { default } from '@wix/serverless-vitest-config';
   ```
   If project has custom jest config beyond the base, use `mergeConfig`:
   ```typescript
   import { mergeConfig } from 'vitest/config';
   import baseConfig from '@wix/serverless-vitest-config';
   export default mergeConfig(baseConfig, { test: { /* overrides */ } });
   ```

2. Add `"type": "module"` to package.json (ESM switch)

3. Update package.json scripts:
   - `"test": "vitest run"`
   - `"test:watch": "vitest"` (add if not present)

4. Install deps: `@wix/serverless-vitest-config`, `vitest`, `@vitest/coverage-v8`, `vitest-teamcity-reporter`

5. Remove deps: `@wix/serverless-jest-config`, `jest`, `ts-jest`, `jest-standard-reporter`, `jest-teamcity-reporter`, `jest-circus`

6. Delete `jest.config.js`

7. `@wix/serverless-testkit` requires NO changes -- it works identically with vitest.

#### React/BM/UI Project (has `jest-yoshi-preset` or `jest-yoshi-preset-base`)

1. Create `vitest.config.ts` using Pattern 1 from configs reference
2. Update tsconfig.json: add `"types": ["vitest/globals"]`
3. Install deps: `vitest`, `@vitejs/plugin-react`, `vite-plugin-svgr`, `@vitest/coverage-v8`, `vitest-teamcity-reporter`
4. Remove deps: `jest-yoshi-preset`, `jest-yoshi-preset-base`, `jest`, `ts-jest`
5. Delete jest config files

#### FED CLI Project (has `@wix/fed-cli-vitest` or in fed-cli ecosystem)

1. Create `vitest.config.ts` using Pattern 3 from configs reference
2. Install deps: `vitest`, `@wix/fed-cli-vitest`, `@vitest/coverage-v8`
3. Remove jest deps
4. Delete jest config files

#### Standalone Jest Project

1. Create `vitest.config.ts` with basic config (environment, globals, include patterns)
2. Install deps: `vitest`, `@vitest/coverage-v8`
3. If React: add `@vitejs/plugin-react`, `jsdom`
4. Remove jest deps
5. Delete jest config files

### Phase 2 - Setup Files (sequential)

1. Find existing setup files (spec-setup.ts, test-setup.ts, jest-setup.ts, setupFilesAfterEnv targets)
2. Rename to vitest-setup.ts (or keep name, just update references)
3. Replace any `jest.*` calls in setup files
4. If `wix-testkit-base` or `ambassador-testkit` detected, add workaround at top of setup file:
   ```typescript
   // Workaround: wix-testkit-base misidentifies vitest as Jasmine when globals: true
   // Source: https://wix.slack.com/archives/C0C89GRRB/p1748374522589649
   (global as any).before = globalThis.beforeAll;
   (global as any).beforeAll = null;
   (global as any).after = globalThis.afterAll;
   (global as any).afterAll = null;
   ```

### Phase 3 - Test File Transforms (parallel)

Read [references/jest-to-vitest-transforms.md](references/jest-to-vitest-transforms.md) for the complete transform rules.

**Dispatch strategy:**
1. Group test files by parent directory
2. Create batches of 5-10 files each
3. Dispatch subagents per batch (up to 4 concurrent)
4. Each subagent receives: file list, transform rules, project context

**Core transforms per file:**

1. Add `import { vi } from 'vitest'` at top (unless `globals: true` is set -- then skip)
2. Replace `jest.mock(` -> `vi.mock(`
3. Replace `jest.fn(` -> `vi.fn(`
4. Replace `jest.spyOn(` -> `vi.spyOn(`
5. Replace `jest.requireActual(` -> `await vi.importActual(` (make containing function async if needed)
6. Replace `jest.useFakeTimers(` -> `vi.useFakeTimers(`
7. Replace `jest.advanceTimersByTime(` -> `vi.advanceTimersByTime(`
8. Replace `jest.clearAllMocks(` -> `vi.clearAllMocks(`
9. Replace `jest.resetModules(` -> `vi.resetModules(`
10. Replace `jest.clearAllTimers(` -> `vi.clearAllTimers(`
11. Replace `jest.restoreAllMocks(` -> `vi.restoreAllMocks(`
12. Replace `jest.runAllTimers(` -> `vi.runAllTimers(`
13. Replace `jest.runOnlyPendingTimers(` -> `vi.runOnlyPendingTimers(`
14. Handle `jest.mock()` with module factory that references outer variables -> wrap with `vi.hoisted()`
15. Replace `@jest-environment jsdom` comment -> `// @vitest-environment jsdom`
16. Remove `import 'jest'` or `import type {} from 'jest'` if present

### Phase 4 - Cleanup (sequential)

1. Remove any remaining jest devDependencies from package.json
2. Use `localSearchCode` to verify no `jest.` references remain in test files (except inside strings/comments describing migration)
3. Delete `jest.config.js`, `jest.config.ts`, `jest.config.mjs` if they still exist
4. Update `.eslintrc` if it has jest-specific config (e.g., `jest: true` in env)

---

## Step 4 -- Verify

### 4.1 Run tests

```bash
npx vitest run 2>&1 | tail -30
```

Capture pass/fail count.

### 4.2 Compare counts

Compare test count from vitest run with the count from Step 1. If they differ, investigate.

### 4.3 Type check

```bash
npx tsc --noEmit 2>&1 | tail -20
```

### 4.4 Check def-done.md

Walk through each criterion in def-done.md and verify.

### 4.5 Present summary

```
Migration Complete:
- Project type: {type}
- Files transformed: {count}
- Tests passing: {pass}/{total}
- Blockers resolved: {list}
- Warnings: {list}
```

Clean up plan.md and def-done.md (or leave for user reference).

---

## Fallback: Direct Mode

If subagent dispatch fails with `resource_exhausted`, fall back to processing test files sequentially in direct mode. Apply the same transform rules from Phase 3 one file at a time.

## MCP Usage Summary

| MCP | Tools | When |
|-----|-------|------|
| octocode | `localSearchCode`, `localViewStructure`, `localFindFiles` | Step 1 detection, Step 4 verification |
| octocode | `githubSearchCode`, `githubGetFileContent` | Research novel patterns in other Wix repos |
| context7 | `resolve-library-id`, `query-docs` | Query latest Vitest docs for unfamiliar APIs |
