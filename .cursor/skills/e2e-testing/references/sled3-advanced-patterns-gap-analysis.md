# Sled 3 Advanced Patterns — Gap Analysis

> Deep-search across `wix-private/sled-playwright`, Wix internal docs, and Relay skill references.
> For each topic: COVERED (in plan), GAP (should add), or OUT_OF_SCOPE.

---

## 1. Parallel Test Execution Patterns

### 1.1 `fullyParallel`, `workers`

**Status: GAP** (partially covered)

**Findings:**
- Sled 3 `playwrightConfig` accepts all standard Playwright options; `defineSledConfig` passes them through.
- CLI: `--fully-parallel` flag exists.
- `sled3-documentation-summary.md` mentions `retries`, `workers` in passing.
- `configuration.md` says "For a complete list, refer to official Playwright configuration documentation" but does not list `fullyParallel` or `workers`.

**GAP:** No explicit Sled 3 guidance on:
- When to use `fullyParallel: true` vs `false`
- Worker isolation guarantees
- Recommended `workers` for CI vs local (e.g. `workers: process.env.CI ? 1 : undefined` for deterministic CI)
- Impact of Sled remote execution on worker count

**Add to skill:**
```typescript
// playwright.config.ts — inside playwrightConfig
fullyParallel: true,           // Run test files in parallel (default Playwright)
workers: process.env.CI ? 4 : undefined,  // CI: explicit; local: auto
```

---

### 1.2 Shared State Between Workers

**Status: GAP**

**Findings:**
- `memoize` fixture provides **cross-worker caching** with distributed locking.
- `sled3-documentation-summary.md` and `sled-testing.md` mention `memoize` briefly.
- No explicit guidance on: when workers share state, race conditions, or worker-scoped vs test-scoped fixtures.

**Add to skill:**
- `memoize` for expensive ops (auth, site creation) — cross-worker cache.
- Worker-scoped fixtures: Playwright `{ scope: 'worker' }` in `test.extend()`.
- Avoid mutable shared state; use `memoize` only for read-heavy caches.

---

### 1.3 Project Dependencies (setup → test projects)

**Status: GAP**

**Findings:**
- Playwright supports `project.dependencies` for running setup projects before test projects.
- Sled 3 docs do not mention project dependencies.
- Dependency tests (provider/consumer artifacts) are a **different concept** — see `annotations.dependencyTest.consumers()`.
- CLI has `--no-deps` to skip project dependencies.

**Add to skill:**
```typescript
// playwright.config.ts — inside playwrightConfig.projects
projects: [
  { name: 'setup', testMatch: /\.setup\.ts/, teardown: 'test-project' },
  { name: 'test-project', dependencies: ['setup'] },
],
```

---

## 2. `test.use()` Patterns

### 2.1 Override fixtures per test/describe

**Status: COVERED** (via fixture docs; could be consolidated)

**Findings:**
- `auth.md`: `test.use({ user: '...' })` for default user; scoping to `test.describe` blocks.
- `experiments.md`: `test.use({ experiments: [...] })` for file/block; `setExperiments` for per-test.
- `base.fixture.ts`: Options with `{option:true}`: `user`, `interceptors`, `experiments`, `artifactsUrlOverride`, `disableBiEvents`, `gotoConfig`, etc.

**Add to skill (consolidate):**
- Quick reference table: which options support `test.use()`:
  - `user` — auto-login
  - `experiments` — merge with global
  - `interceptors` — add to pipeline
  - `artifactsUrlOverride` — per-file/block artifact overrides
- Scoping: `test.describe('block', () => { test.use({ user: 'x' }); ... })`

---

### 2.2 Experiment overrides per test

**Status: COVERED**

**Findings:**
- `experiments.md` documents `setExperiments(experiments, newContext?)` for per-test.
- `test.use({ experiments })` for describe/file level.

---

### 2.3 Artifact overrides per test

**Status: COVERED**

**Findings:**
- `sled-testing.md` documents:
```typescript
test.use({
  artifactsUrlOverride: [
    { groupId: 'com.wixpress', artifactId: 'my-app', version: '1.2.3' },
  ],
});
```

---

## 3. Global Setup/Teardown

### 3.1 `globalSetup` / `globalTeardown` in Sled 3

**Status: GAP**

**Findings:**
- `lifecycle.manager.ts`: Sled merges `context.config.globalSetup` and `globalTeardown` from `playwrightConfig` with defaults.
- `defineSledConfig` → `playwrightConfig` passes through to Playwright.
- **No Sled 3 wix-docs page** explains how to add custom globalSetup/globalTeardown.

**Add to skill:**
```typescript
// playwright.config.ts
playwrightConfig: {
  globalSetup: './e2e/global-setup.ts',
  globalTeardown: './e2e/global-teardown.ts',
  // ... rest
},
```

---

### 3.2 Worker-scoped vs test-scoped fixtures

**Status: GAP**

**Findings:**
- Playwright supports `{ scope: 'worker' }` in fixture definition.
- Sled 3 fixture docs do not explain worker-scoped vs test-scoped.
- `memoize` is effectively worker-scoped (cross-worker cache).

**Add to skill:**
- Worker-scoped: one setup per worker; use for expensive, read-only setup.
- Test-scoped (default): fresh per test; use for mutable state.

---

## 4. Retry and Flakiness

### 4.1 Playwright `retries` config in Sled 3

**Status: GAP** (partially covered)

**Findings:**
- `playwrightConfig` accepts `retries`.
- CLI: `--repeat-each` for manual flakiness runs.
- Skill mentions `detect-flakiness` and debugging, but not `retries` config.

**Add to skill:**
```typescript
playwrightConfig: {
  retries: process.env.CI ? 2 : 0,  // Retry failed tests in CI
  // ...
},
```

---

### 4.2 `repeatEach` for flakiness detection

**Status: COVERED**

**Findings:**
- CLI: `sled-playwright detect-flakiness --repeat-count 20`
- Manual: `sled-playwright test --repeat-each=5` for ad-hoc runs.
- `sled3-debugging-research.md` documents both.

---

### 4.3 CI retry behavior

**Status: GAP** (partial)

**Findings:**
- Sled 2: `totalSerialRetries` (1–5), default 3 in CI.
- Sled 3: Uses Playwright `retries`; no explicit Sled-level retry doc.
- CI rerun: `--rerun-all` bypasses smart rerun (run full suite).

**Add to skill:**
- CI uses Playwright retries; Sled adds `--rerun-all` for full rerun on failure.

---

## 5. Tags and Filtering

### 5.1 `@tag` annotation support

**Status: GAP**

**Findings:**
- No formal `@tag` annotation in Sled 3 (unlike Cypress).
- Playwright uses `--grep` on **test names**.
- Convention: include tags in test names, e.g. `test('@smoke should load', ...)` and run `--grep @smoke`.

**Add to skill:**
- Use test name convention: `test('@smoke user can login', ...)` and `sled-playwright test --grep @smoke`.
- Or `test.describe.configure` for project-level config.

---

### 5.2 `--grep` and `--grepInvert`

**Status: COVERED**

**Findings:**
- CLI explicitly documents `--grep`, `--grep-invert`.
- Skill run-commands table includes `--grep "name"`.
- `e2e-testing-patterns` SKILL shows `grepInvert: /@slow/` in project config.

---

### 5.3 Project-based test organization

**Status: COVERED**

**Findings:**
- `playwrightConfig.projects` for browser variants (chromium, firefox, etc.).
- Dependency tests use `annotations.dependencyTest.consumers()` for cross-artifact runs.
- `--project <name>` to run specific project.

---

## 6. Network Features

### 6.1 WebSocket interception

**Status: OUT_OF_SCOPE** (or minimal add)

**Findings:**
- No Sled-specific WebSocket support.
- Playwright has `page.route()` for HTTP; WebSockets need `page.on('websocket', ...)` and manual handling.
- Rare in typical Wix E2E; defer to Playwright docs.

**Recommendation:** OUT_OF_SCOPE for general skill. If needed, link to Playwright network docs.

---

### 6.2 Download handling

**Status: GAP** (minimal)

**Findings:**
- Playwright: `page.waitForEvent('download')`, `download.path()`, etc.
- No Sled 3 examples.
- Common need for export/CSV flows.

**Add to skill (brief):**
```typescript
const [download] = await Promise.all([
  page.waitForEvent('download'),
  page.getByRole('button', { name: 'Export' }).click(),
]);
expect(await download.path()).toContain('.csv');
```

---

### 6.3 File upload handling

**Status: GAP** (minimal)

**Findings:**
- Playwright: `page.setInputFiles()` or `locator.setInputFiles()`.
- No Sled 3 examples.
- Common for BM/editor flows.

**Add to skill (brief):**
```typescript
await page.getByLabel('Upload file').setInputFiles('path/to/file.pdf');
```

---

### 6.4 Multi-tab / multi-context scenarios

**Status: GAP** (minimal)

**Findings:**
- Playwright: `context.waitForEvent('page')` for new tabs.
- Sled 3: `createWixContext` for new context with Sled setup.
- No explicit multi-tab guidance.

**Add to skill (brief):**
- Use `createWixContext()` for additional context with Sled fixtures.
- For new tab: `const [newPage] = await Promise.all([context.waitForEvent('page'), ...])`.

---

## 7. BM (Business Manager) Specific Patterns

### 7.1 `injectBMOverrides` from `@wix/yoshi-flow-bm/sled`

**Status: GAP**

**Findings:**
- `sled-testing.md` documents `injectBMOverrides` under **Sled 2** BM apps.
- Writer processor and skill mention it for BM apps.
- **Unclear if `injectBMOverrides` works with Sled 3 (Playwright)** — it accepts `{ page, appConfig }` and may be framework-agnostic if `page` is Playwright-compatible.
- No Sled 3–specific BM docs in sled-playwright wix-docs.

**Add to skill:**
- Clarify: `injectBMOverrides` is from `@wix/yoshi-flow-bm/sled`; verify compatibility with Sled 3 `page` fixture.
- Example: `await injectBMOverrides({ page, appConfig: require('../target/module-sled.merged.json') });` in `beforeEach` or fixture.
- If Sled 3–specific BM patterns exist (e.g. dashboard URL builder), document them.

---

### 7.2 BM-specific navigation, dashboard URL patterns

**Status: GAP**

**Findings:**
- `urlBuilder` fixture exists for URL construction.
- BM apps typically navigate to `https://www.wix.com/dashboard/{msid}/{appEntry}`.
- No consolidated BM navigation section in skill.

**Add to skill:**
- BM dashboard base: `https://www.wix.com/dashboard/{msid}/home` (or app entry).
- Use `auth.loginAsUser` then `page.goto(urlBuilder.url(base).build())` if experiments needed.

---

## 8. Editor-Specific Patterns

### 8.1 Editor preview frame access

**Status: OUT_OF_SCOPE**

**Findings:**
- Sled 3 primary target: flow-bm. Editor flow typically uses Sled 2.
- Editor preview frame = iframe; Playwright supports `frameLocator`, but editor-specific setup is complex.
- Flow-editor projects use `sled-test-runner` (Sled 2).

**Recommendation:** OUT_OF_SCOPE for general Sled 3 skill. Consider a separate editor-E2E skill if needed.

---

### 8.2 Editor API, iframe handling

**Status: OUT_OF_SCOPE**

Same rationale as 8.1. Playwright provides `page.frameLocator()`, but editor-specific patterns are out of scope.

---

## Summary Table

| Topic | Status | Priority |
|-------|--------|----------|
| Parallel: fullyParallel, workers | GAP | High |
| Worker isolation, shared state | GAP | Medium |
| Project dependencies (setup → test) | GAP | Medium |
| test.use consolidation | GAP | Low (docs exist, consolidate) |
| Global setup/teardown | GAP | Medium |
| Worker vs test-scoped fixtures | GAP | Low |
| retries config | GAP | High |
| CI retry behavior | GAP | Low |
| @tag convention | GAP | Medium |
| grep/grepInvert | COVERED | — |
| WebSocket | OUT_OF_SCOPE | — |
| Download handling | GAP | Low |
| File upload | GAP | Low |
| Multi-tab/context | GAP | Low |
| injectBMOverrides (Sled 3) | GAP | Medium |
| BM navigation patterns | GAP | Low |
| Editor patterns | OUT_OF_SCOPE | — |

---

## Recommended Additions to Skill

1. **New reference section**: `sled3-advanced-config.md` covering:
   - fullyParallel, workers, retries
   - globalSetup/globalTeardown
   - Project dependencies
   - test.use options table (user, experiments, interceptors, artifactsUrlOverride)

2. **Extend `sled-testing.md`**:
   - BM section: injectBMOverrides + Sled 3 compatibility note
   - Network: download, file upload, multi-tab minimal examples
   - @tag convention with grep

3. **Update SKILL.md**:
   - Add "Advanced config" to Framework Quick Reference
   - Link to new reference from debugging/run commands
