# Wix-Specific Vitest Migration Gotchas

All issues documented from real Wix Slack threads and production experience. Each gotcha includes: source, detection method, severity, and workaround.

---

## 1. wix-testkit-base / ambassador-testkit Jasmine Misdetection

**Source:** [#node-platform thread](https://wix.slack.com/archives/C0C89GRRB/p1748374522589649) (noamshab)

**Problem:** When vitest runs with `globals: true`, it exposes `beforeAll`/`afterAll` as globals. The `wix-testkit-base` library (used internally by `@wix/ambassador-testkit`, `@wix/ambassador-grpc-testkit`, and other testkits) scans for `globals.beforeAll` to detect the test runner. When it finds it, it assumes Jasmine and uses the deprecated `done()` callback pattern, which vitest rejects.

**Error message:**
```
Error: done() callback is deprecated, use promise instead
```

**How to detect:** Check if any of these are in devDependencies:
- `@wix/ambassador-testkit`
- `@wix/ambassador-grpc-testkit`
- `wix-testkit-base`
- `@wix/serverless-testkit` (uses wix-testkit-base internally)

**Severity:** WORKAROUND AVAILABLE

**Fix:** Add to the vitest setup file (specified in `setupFiles` config):

```typescript
// Workaround: wix-testkit-base misidentifies vitest as Jasmine when globals: true
// It detects globals.beforeAll and assumes Jasmine, using done() callbacks.
// Fix: temporarily null out beforeAll/afterAll so the detection falls through to
// the correct "mocha-like" path which uses promises.
// Source: https://wix.slack.com/archives/C0C89GRRB/p1748374522589649
(global as any).before = globalThis.beforeAll;
(global as any).beforeAll = null;
(global as any).after = globalThis.afterAll;
(global as any).afterAll = null;
```

**Important:** This must run BEFORE any testkit initialization. Place it at the very top of the setup file.

---

## 2. Stylable (.st.css) Incompatibility

**Source:** [#feds thread](https://wix.slack.com/archives/C056JMHJ5/p1740142415532899) (iaroslavs)

**Problem:** Vitest cannot process Stylable files (`.st.css`). In Jest, the `jest-yoshi-preset` provides a module name mapper that proxies `.st.css` imports to an identity function. Vitest has no equivalent Stylable plugin, and the identity-proxy approach doesn't work for Stylable imports that come from `node_modules` (e.g., `wix-style-react` components).

**How to detect:** Search for ANY of:
- `.st.css` imports in source or test files
- `wix-style-react` in dependencies
- `@stylable/` packages in devDependencies

**Severity:** HARD BLOCKER

**Resolution path:**
1. Migrate from `wix-style-react` (WSR) to `@wix/design-system` (WDS) first
2. WDS does not use Stylable -- it uses standard CSS modules
3. After WSR -> WDS migration, the Stylable blocker is removed
4. Then proceed with Jest -> Vitest migration

**User message:** "This project uses Stylable (.st.css files) via wix-style-react. Vitest cannot process Stylable files. You need to migrate from wix-style-react to @wix/design-system first, then migrate to Vitest."

---

## 3. Yoshi Monorepo Dependency Hoisting Conflicts

**Source:** [#feds thread](https://wix.slack.com/archives/C056JMHJ5/p1740142415532899) (iaroslavs)

**Problem:** In yoshi monorepos using yarn workspaces, adding vitest to one package causes its dependencies to be hoisted to the root `node_modules`. This can crash other packages' Storybook builds because Storybook's webpack config picks up vitest-related modules unexpectedly.

**How to detect:**
- Project is in a monorepo (has `workspaces` in root package.json)
- Multiple packages use `yoshi-flow-*` or `jest-yoshi-preset`
- Root has `yoshi` or `@wix/yoshi-*` in devDependencies

**Severity:** WARNING

**Mitigation options:**
1. **Migrate all packages at once** -- eliminates the mixed jest/vitest state
2. **Use `nohoist`** in package.json to prevent vitest from being hoisted (fragile)
3. **Wait for FED CLI migration** -- FED CLI replaces yoshi entirely and natively supports vitest

**User message:** "This is a yoshi monorepo. Adding vitest to one package may crash Storybook in other packages due to dependency hoisting. Consider migrating all packages at once, or waiting for the FED CLI migration path."

---

## 4. yoshi-flow-bm ESM Incompatibility

**Source:** [#yoshi thread](https://wix.slack.com/archives/CAL591CDV/p1766078907136879) (iaroslavs, Artem Demo)

**Problem:** `yoshi-flow-bm` and related packages (`@wix/yoshi-flow-bm`, `yoshi-flow-bm-runtime`) have non-ESM-compatible imports throughout. Vitest runs in ESM mode and cannot handle these CommonJS-only patterns. The issue is not just in test files but in the runtime packages themselves.

**How to detect:**
- `@wix/yoshi-flow-bm` in dependencies
- Heavy usage of yoshi test infrastructure (e.g., `yoshi-flow-bm/test` utilities)

**Severity:** WARNING (may be a blocker depending on coupling)

**Context:** FED CLI is working on bm-flow support (expected 2026) but it's not yet ready for mass adoption. The recommended path is:
1. Check if the project can decouple its test files from yoshi-specific test utilities
2. If tests only use standard jest/react-testing-library patterns, migration may work
3. If tests import from `yoshi-flow-bm/test` or similar, wait for FED CLI

**User message:** "This project uses yoshi-flow-bm which has ESM compatibility issues with Vitest. If your tests only use standard jest/RTL patterns (not yoshi test utilities), migration may work. Otherwise, consider waiting for FED CLI's bm-flow support."

---

## 5. Complex Projects: "Not Enough to Naively Change jest to vi"

**Source:** [#yoshi](https://wix.slack.com/archives/CAL591CDV/p1766151388093739) (iaroslavs)

**Problem:** In mature, large projects with legacy parts, simply replacing `jest.` with `vi.` is insufficient. Common additional issues:
- Module resolution differences between Jest (CommonJS) and Vitest (ESM)
- Dynamic imports that worked in CommonJS but fail in ESM
- Test isolation differences (vitest re-executes module-level code differently)
- CSS/asset imports that need different handling
- Third-party libraries that don't properly support ESM

**How to detect:** Not a single check -- this is a complexity indicator:
- More than 100 test files
- Test files older than 3 years (legacy patterns likely)
- Heavy use of `jest.mock()` with complex factories
- Multiple `jest.config.js` overrides beyond the base preset

**Severity:** WARNING (complexity, not a hard blocker)

**Mitigation:**
1. Run vitest after initial migration and carefully review ALL failures
2. Don't assume failures are due to incorrect transforms -- check module resolution
3. For complex mock factories, consider rewriting rather than mechanically transforming
4. Set `pool: 'forks'` instead of `pool: 'threads'` if test isolation issues appear (threads share memory, forks don't)

**User message:** "This is a large project with {n} test files. Mechanical transform will handle most cases, but some tests may need manual fixes for module resolution, ESM compatibility, or test isolation differences. Plan for a review pass after the automated migration."

---

## Detection Script Integration

The `scripts/detect-test-framework.sh` checks for these blockers automatically and reports them in the JSON output:

```json
{
  "blockers": [
    { "id": "stylable", "severity": "hard", "detail": "Found .st.css imports in 12 files" },
    { "id": "testkit-base", "severity": "workaround", "detail": "@wix/ambassador-testkit in devDependencies" },
    { "id": "yoshi-monorepo", "severity": "warning", "detail": "3 yoshi-flow packages in workspace" }
  ]
}
```
