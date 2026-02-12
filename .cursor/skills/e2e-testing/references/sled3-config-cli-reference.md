# Sled 3 `defineSledConfig` API & CLI Complete Reference

**Source:** `wix-private/sled-playwright` (verified Feb 2026)

---

## 1. Config API Reference

### `WixPlaywrightConfigParams` = `IWixConfig` & `GlobalConfiguration` & `{ playwrightConfig?, plugins? }`

---

### IWixConfig (Wix-specific options)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `artifactId` | `string` | from `package.json` | Artifact ID for overrides and tracing. **Required** if not in package.json. |
| `version` | `string` | — | Artifact version. |
| `pathToStatics` | `string` | `'dist/statics'` | Path to static files for local serving and artifact overrides. |
| `artifactsUrlOverride` | `ArtifactsUrlOverride[]` | — | Override artifact URLs. Each item: `{ groupId, artifactId, version }`. `version` can be `'1.2.3'`, `'RC'`, or `'currentVersionFromMonorepo'` (CI only). |
| `baseUrlsToInterceptArtifacts` | `string[]` | `['https?://localhost:3[32]0[01]/']` | URL patterns to intercept for artifact overrides. |
| `artifactIdToUseForFingerprintOverride` | `string` | — | Override fingerprint from CI with this artifact's fingerprint. |
| `artifactsOverridePolicy` | `ArtifactsOverridePolicy` | `FAIL_ON_MISSING` | See enum below. Can be overridden by env `ARTIFACTS_OVERRIDE_POLICY`. |
| `globalExperiments` | `ExperimentsMap \| Experiment[]` | — | Experiments for all tests; test-level overrides conflicts. |
| `noAutomationFlagging` | `boolean` | `false` | Disable automation cookies (`automation`, `yes_this_is_sled`). |
| `disableBiEvents` | `boolean` | `true` | Block BI events during tests (BI Interceptor). |
| `github` | `GithubConfig` | — | See below. |

**Not in your list:** `version`, `artifactIdToUseForFingerprintOverride`.

---

### GlobalConfiguration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lighthouseCreateFlowResultRunsNumber` | `number` | — | Lighthouse flow runs. |
| `gotoConfig` | `GoToConfig` | — | Default navigation config. See below. |
| `fullPageScreenshotConfig` | `FullPageScreenshotConfig` | — | Defaults for `toHaveFullPageScreenshot`. |
| `pool` | `Pool` | — | `'chromium' \| 'firefox' \| 'webkit' \| 'lighthouse'`. |
| `poolVersion` | `PlaywrightVersionTag` | — | From `@wix/sled3-playwright-versions`. |

**Not in your list:** `lighthouseCreateFlowResultRunsNumber`, `pool`, `poolVersion`.

---

### Top-level `WixPlaywrightConfigParams`

| Option | Type | Description |
|--------|------|-------------|
| `playwrightConfig` | `PartialPlaywrightConfig` | Standard Playwright config. Omits `outputDir` and `build`. |
| `plugins` | `PluginResolver[]` | Custom plugins. `PluginResolver = (context: PluginContext) => WixPlaywrightPlugin`. |

---

### `GoToConfig`

```typescript
interface GoToConfig {
  queryParams?: Record<string, string>;
}
```

Effect on navigation: query params from `gotoConfig.queryParams` are appended to all `page.goto()` URLs (only if they are not already present). Implemented in `applyQueryParamsToUrl()` (fixtures/base/utils).

---

### `FullPageScreenshotConfig`

```typescript
interface FullPageScreenshotConfig {
  scrollableElementSelector?: string;  // CSS selector for scrollable container
}
```

Used for WDS pages where content is in a scrollable container.

---

### `ArtifactsOverridePolicy` (from `@wix/automation-client`)

```typescript
enum ArtifactsOverridePolicy {
  FAIL_ON_MISSING = 'fail-on-missing',
  IGNORE_MISSING = 'ignore-missing',
  DISABLE = 'disable',
}
```

Only these three values. No additional enum members.

---

### `github` config

```typescript
interface GithubConfig {
  report?: { enabled?: boolean };   // default: true
  liveTracker?: { enabled?: boolean }; // default: false
}
```

| Sub-option | Type | Default | Description |
|------------|------|--------|-------------|
| `github.report.enabled` | `boolean` | `true` | Post test results as PR comments. |
| `github.liveTracker.enabled` | `boolean` | `false` | Live dashboard URL in PR comments, real-time progress. |

---

### Relationship: `defineSledConfig` vs Playwright

1. User `playwrightConfig` is merged into Sled’s base config (e.g. `testDir`, `fullyParallel`, `projects`).
2. **Never overridable:** `outputDir`, `build`.
3. Sled always sets: `updateSnapshots: 'missing'`, `snapshotPathTemplate`, `outputDir`, `globalSetup`, `globalTeardown`, `reporter`, `webServer`, `projects`, `use`, `metadata`.
4. `use` merges Sled options (trace, locale, artifactId, gotoConfig, etc.) with user Playwright `use`. User `use` can override some fields, but Sled fills in artifact, goto, and fixture-related options.
5. `PartialPlaywrightConfig = Omit<PlaywrightTestConfig, 'outputDir' | 'build'> & { projects?: WixProject[] }`.

---

## 2. CLI Reference

### Commands overview

| Command | Description |
|---------|-------------|
| `init` | Initialize sled-playwright in the repo |
| `install-stable` | Install stable Playwright version |
| `install-next` | Install next Playwright version |
| `supported-versions` | List supported Playwright versions |
| `test` | Run Playwright tests |
| `show-report` | Show Playwright report |
| `detect-flakiness` | Detect flaky tests |
| **`ci`** | **Bundle tests and trigger CI run with sharding** (not in original list) |

---

### `sled-playwright init` [options]

| Flag | Alias | Description |
|------|-------|-------------|
| `-y`, `--yes` | — | Use defaults (no prompts) |

---

### `sled-playwright test` [patterns...] [options]

**Sled-specific flags**

| Flag | Alias | Env | Default | Description |
|------|-------|-----|---------|-------------|
| `--artifacts-override-policy <a>` | `-a` | `ARTIFACTS_OVERRIDE_POLICY` | `fail-on-missing` | `disable`, `fail-on-missing`, `ignore-missing` |
| `--remote` | `-r` | `REMOTE` | `false` | Run on remote execution |
| `--with-dependency-tests` | `-d` | `WITH_DEPENDENCY_TESTS` | `false` | Run dependency tests locally (always on in CI) |
| `--silent-report` | `-sr` | `SILENT_REPORT` | `false` | Do not auto-open report in browser |
| `--global-experiments <exp>` | `-ge`, `--global-experiment` | `GLOBAL_EXPERIMENTS` | — | `key1=value1,key2=value2` |
| `--rerun-all` | — | `RERUN_ALL` | `false` | Run all tests, skip failed-only rerun |
| `--live-tracker` | `-lt` | `LIVE_TRACKER_ENABLED` | `false` | Enable live progress dashboard |
| `--alias <alias>` | — | `ALIAS` | — | Custom run identifier |

**Playwright passthrough flags**

| Flag | Description |
|------|-------------|
| `-c`, `--config <c>` | Config file |
| `--debug` | Debug mode |
| `--last-failed` | Run last failed tests |
| `--forbid-only` | Fail if `only` tests exist |
| `--fully-parallel` | Fully parallel |
| `--grep <g>` | Run tests matching pattern |
| `--global-timeout <t>` | Global timeout |
| `--grep-invert <g>` | Invert grep |
| `--headed` | Headed mode |
| `--ignore-snapshots` | Ignore snapshots |
| `--list` | List tests |
| `--no-deps` | Skip project deps |
| `--output <o>` | Output dir |
| `--pass-with-no-tests` | Pass when no tests |
| `--project <p...>` | Project name(s) |
| `--quiet` | Quiet mode |
| `--repeat-each <r>` | Repeat each test n times |
| `--retries <r>` | Retries (default: 2) |
| `--shard <s>` | Shard tests |
| `--timeout <t>` | Test timeout |
| `--update-snapshots` | Update snapshots |
| `--ui` | UI mode |
| `--update <u>` | Update snapshots |

**Not in your list:** `--alias` (test).

---

### `sled-playwright show-report` [args...]

Shows report. Accepts pass-through args; defaults to `OUTPUT_PLAYWRIGHT_HTML_DIR` if no args.

---

### `sled-playwright detect-flakiness` [options] [-- playwright-args...]

| Flag | Default | Description |
|------|---------|-------------|
| `--base-branch <branch>` | `origin/master` | Branch for changed files |
| `--repeat-count <count>` | `20` | Runs per test |
| `--test-max-failures <count>` | `0` | Max failures before treating as flaky |
| `--path <path>` | (from cwd) | Path filter for changed files |
| `--test-file-suffix <suffix>` | `.spec.ts` | Test file suffix |
| `--alias <alias>` | `flakiness-detection` | Custom alias |
| `--test-path <path>` | — | Specific test file (bypasses git-changed) |

**Not in your list:** `--path`, `--test-file-suffix`, `--alias`, `--test-path`.

---

### `sled-playwright ci` [pattern] [options]

| Flag | Alias | Description |
|------|-------|-------------|
| `-c`, `--config <c>` | — | Config file |
| `--project <p...>` | — | Project(s) to include |
| `--grep <g>` | — | Only bundle matching tests |
| `--grep-invert <g>` | — | Invert grep |
| `--sled-version <version>` | — | Override sled-playwright version (`latest` for npm latest) |

---

## 3. Options/Commands missing from your lists

### Config

- `version`
- `artifactIdToUseForFingerprintOverride`
- `lighthouseCreateFlowResultRunsNumber`
- `pool`
- `poolVersion`

### CLI

- **`ci`** command
- `test --alias`
- `detect-flakiness --path`, `--test-file-suffix`, `--alias`, `--test-path`
- Full Playwright passthrough list in `test` (see table above)

---

## 4. Deprecations

None found in the reviewed code.
