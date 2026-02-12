# Sled 3 (@wix/sled-playwright) Debugging — Research Findings

Research compiled from `wix-private/sled-playwright`, Wix internal docs, and Relay e2e-testing references.

---

## 1. Official Debugging Docs (sled-playwright wix-docs)

### Debug Mode & Headed Mode

| Tool | Command | Purpose |
|------|---------|---------|
| **Debug mode** | `npx @wix/sled-playwright test --debug` | Opens Playwright Inspector, step-through debugging |
| **Headed mode** | `npx @wix/sled-playwright test --headed` | Run with visible browser |
| **UI mode** | `npx @wix/sled-playwright test --ui` | Interactive Playwright UI |
| **Playwright Inspector** | `PWDEBUG=1 npx @wix/sled-playwright test` | Full Playwright Inspector experience |
| **Debug logs** | `DEBUG=pw:api npx @wix/sled-playwright test` | Detailed API logs |

### Trace Viewer

```typescript
// In your test
await context.tracing.start({ screenshots: true, snapshots: true });
// ... test code ...
await context.tracing.stop({ path: 'trace.zip' });
```

View trace:
```bash
npx @wix/sled-playwright show-trace trace.zip
# Or: npx playwright show-trace trace.zip
```

### Browser DevTools / Pause

```typescript
// Pause execution to inspect the page
await page.pause();
```

**Reference:** `wix-docs/troubleshooting/local.md` (sled-playwright repo)

---

## 2. Flakiness Detection (`detect-flakiness`)

### Command

```bash
npx @wix/sled-playwright detect-flakiness
```

### What it does

1. Validates clean state — blocks if uncommitted changes
2. Finds changed tests vs base branch
3. Runs each test multiple times (default: 20)
4. Reports stable vs flaky tests with pass/fail statistics

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--base-branch <branch>` | `origin/master` | Base branch for diff |
| `--repeat-count <count>` | 20 | Runs per test |
| `--test-max-failures <count>` | 0 | Allowed failures before flagging flaky |
| `--test-file-suffix <suffix>` | `.spec.ts` | Test file pattern |
| `--alias <alias>` | `flakiness-detection` | Custom run identifier |

### Examples

```bash
# Faster check
npx @wix/sled-playwright detect-flakiness --repeat-count 10

# Allow 1 failure per test (unstable env)
npx @wix/sled-playwright detect-flakiness --test-max-failures 1

# Pass Playwright options
npx @wix/sled-playwright detect-flakiness --project chromium
```

### Investigating flaky tests

```bash
npx @wix/sled-playwright test <file> --repeat-each=20
```

**References:** `wix-docs/api/cli.md`, FED Guild "Flaky Tests" (dev.wix.com)

---

## 3. Common Error Messages & Solutions

### 3.1 `defineSledConfig` crashes locally (no CI env vars)

| Symptom | Root cause | Solution |
|---------|------------|----------|
| Config loads fine in CI, crashes locally | Sled expects CI env vars; some paths assume CI context | Prefix local runs with `CI=false`: `CI=false npx @wix/sled-playwright test` |

**Prevention:** Use `sled-playwright test` (not raw `npx playwright test`) and add `CI=false` for local dev if needed.

---

### 3.2 Timeout issues

| Symptom | Root cause | Solution |
|---------|------------|----------|
| Test times out waiting for element | Element not visible/attached; slow network | Use `expect(locator).toBeVisible()` (auto-retries); increase `timeout` in config; check network/API mocks |
| Global timeout hit | Long-running test or infinite loop | Increase `globalTimeout` in `playwrightConfig`; add `test.setTimeout(ms)` per test |
| Action timeout | Single action too slow | Increase `actionTimeout` or `navigationTimeout` in config |

**Config example:**
```typescript
playwrightConfig: {
  timeout: 120_000,
  use: {
    actionTimeout: 30_000,
    navigationTimeout: 90_000,
  },
}
```

---

### 3.3 Interception pipeline issues

| Symptom | Root cause | Solution |
|---------|------------|----------|
| Wrong mock returned / request not mocked | Route ordering (LIFO vs FIFO confusion) | Sled 3 = **LIFO**; register catch-all **FIRST** (lowest priority) |
| Requests hitting network instead of mocks | Catch-all in wrong position | Put specific mocks AFTER catch-all in handler array |
| Mixing `page.route()` + `interceptionPipeline` on same URL | Unpredictable which handler runs | Use one mechanism per URL pattern |

**Sled 3 (LIFO):**
```typescript
// Catch-all FIRST (lowest priority)
interceptionPipeline.setup([
  { url: '**/api/**', action: InterceptHandlerActions.ABORT }, // fallback
  { url: '**/api/users', action: InterceptHandlerActions.INJECT_RESOURCE, resource: mockUsers },
]);
```

---

### 3.4 Story not found (Storybook)

| Symptom | Root cause | Solution |
|---------|------------|----------|
| Story ID not found | Story IDs come from export names (kebab-case), not `name` | Verify story ID in Storybook URL; use export name |
| Tests run on stale Storybook | `storybook-static` not rebuilt | Rebuild Storybook after adding/renaming stories |

---

### 3.5 Auth failures

| Symptom | Root cause | Solution |
|---------|------------|----------|
| User not logged in | Auth fixture not applied; wrong user email | Use `test.use({ auth: { user: 'user@example.com' } })`; ensure user exists in Garage |
| Session expired | Long test or stale cookies | Re-login in `beforeEach`; shorten test |

---

### 3.6 Artifact override issues

| Symptom | Root cause | Solution |
|---------|------------|----------|
| Local artifacts not loaded | `pathToStatics` wrong; policy `DISABLE` | Set `pathToStatics: 'dist/statics'`; use `FAIL_ON_MISSING` or `IGNORE_MISSING` |
| `currentVersionFromMonorepo` fails | Only valid in CI | Use `RC` or explicit version locally |
| Missing artifact in override | Artifact not in build output | Check `artifacts_upload` patterns; verify `artifactId` |

---

## 4. CI/CD Integration

### How Sled 3 runs in CI

- **Remote browsers:** In CI, Sled auto-uses remote execution (Kubernetes browser pools).
- **postPublish:** Init adds a `postPublish` script for Falcon/CI validation.
- **Rerun behavior:** CI reruns only previously failed tests unless `--rerun-all` is used.
- **HTML report:** Uploaded to S3; link in build logs: `🔗 Sled report: https://sled-reports.wix.com/playwright-reports/...`

### GitHub PR reports

```typescript
// playwright.config.ts
export default defineSledConfig({
  github: {
    report: { enabled: true },   // PR comment with results (default)
    liveTracker: { enabled: true },  // Real-time dashboard (optional)
  },
});
```

### Live Tracker

```bash
npx @wix/sled-playwright test --live-tracker
# or -lt
```

Posts a PR comment with a live dashboard URL at test start.

### Retry strategies

- CI uses `totalSerialRetries` (default 3 in CI, 1 locally) — see `sled.json` legacy config.
- Use `detect-flakiness` before merging to catch flaky tests.

---

## 5. Migration from Sled 2 to Sled 3

### API differences

| Sled 2 | Sled 3 |
|--------|--------|
| `sled.newPage({ user, interceptors })` | `async ({ page, auth })` + `interceptionPipeline` fixture |
| `sled.loginAsUser(page, email)` | `test.use({ auth: { user: email } })` |
| `sled/sled.json` | `playwright.config.ts` + `defineSledConfig()` |
| `npx sled-test-runner local/remote` | `npx sled-playwright test` (remote via `--remote`) |
| `InterceptionTypes.Handler` (FIFO) | `InterceptHandler` + `interceptionPipeline` (LIFO) |

### Config migration

| sled.json | playwright.config.ts |
|-----------|----------------------|
| `artifact_id` | `artifactId` |
| `artifacts_upload.artifacts_dir` | `pathToStatics` |
| `base_urls_to_intercept_artifacts` | `baseUrlsToInterceptArtifacts` |
| `sled_folder_relative_path_in_repo` | `playwrightConfig.testDir` |

### Interceptor migration (FIFO → LIFO)

| Sled 2 (FIFO) | Sled 3 (LIFO) |
|---------------|---------------|
| First match wins | Last match wins (like Playwright) |
| Catch-all goes **LAST** in array | Catch-all goes **FIRST** (lowest priority) |
| `sled.newPage({ interceptors: [specific, catchAll] })` | `interceptionPipeline.setup([catchAll, specific])` |

**Critical:** Sled 2 = FIFO; Sled 3/Playwright = LIFO. Reversing order when migrating is a common source of bugs.

---

## 6. Prevention Strategies

1. **Before PR:** Run `detect-flakiness` on changed test files.
2. **Interceptors:** Use one mechanism per URL; avoid mixing `page.route()` and `interceptionPipeline` on same pattern.
3. **Locators:** Prefer `getByRole`, `getByLabel`, `data-hook` over fragile selectors.
4. **Waiting:** Use `expect(locator).toBeVisible()` instead of `waitForTimeout`.
5. **Local runs:** Use `CI=false` if `defineSledConfig` fails locally.
6. **CLI:** Always use `sled-playwright test`, not raw `npx playwright test`, when using `defineSledConfig`.

---

## 7. Key Documentation Links

| Resource | Location |
|----------|----------|
| CLI (detect-flakiness, test options) | `wix-docs/api/cli.md` (sled-playwright) |
| Configuration | `wix-docs/api/configuration.md` (sled-playwright) |
| Local debugging | `wix-docs/troubleshooting/local.md` (sled-playwright) |
| Remote debugging | `wix-docs/troubleshooting/remote.md` (sled-playwright) |
| Flaky tests (Wix docs) | dev.wix.com → FED Guild → Infra → Sled3 → Best Practices → Flaky Tests |
| Playwright Report (CI) | dev.wix.com → Sled3 → Playwright Report |
| Relay e2e skill | `.cursor/skills/e2e-testing/` (SKILL.md, references/) |

---

## 8. Support

- Infrastructure: [#sled](https://wix.slack.com/archives/CHKPRKSG7)
- Test writing & practices: [#sled-advocates](https://wix.slack.com/archives/C0236AC9JCX)
