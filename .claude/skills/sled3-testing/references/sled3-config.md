# Sled 3 Configuration and CLI Reference

Source-verified from `WixPlaywrightConfigParams` type in `wix-private/sled-playwright`.

## defineSledConfig

```typescript
import { defineSledConfig, ArtifactsOverridePolicy } from '@wix/sled-playwright';

export default defineSledConfig({
  // Wix-specific options (see table below)
  artifactId: 'your-artifact-id',
  // Standard Playwright config
  playwrightConfig: { ... },
});
```

## Wix-Specific Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `artifactId` | `string` | from package.json | Your artifact identifier |
| `version` | `string` | — | Artifact version |
| `pathToStatics` | `string` | `'dist/statics'` | Static files path for artifact overrides |
| `artifactsOverridePolicy` | `ArtifactsOverridePolicy` | `FAIL_ON_MISSING` | How to handle missing artifact overrides |
| `artifactsUrlOverride` | `ArtifactUrlOverride[]` | — | Override specific artifact versions |
| `baseUrlsToInterceptArtifacts` | `string[]` | — | Base URLs to intercept for artifact overrides |
| `gotoConfig` | `{ queryParams?: Record&lt;string, string&gt; }` | — | Query params auto-appended to all `page.goto()` |
| `globalExperiments` | `Experiment[]` | — | Experiments applied to all tests |
| `noAutomationFlagging` | `boolean` | `false` | Disable automation detection cookies |
| `disableBiEvents` | `boolean` | `true` | Block BI events during tests |
| `github.report.enabled` | `boolean` | `true` | PR comment with test results |
| `github.liveTracker.enabled` | `boolean` | `false` | Real-time test progress dashboard |
| `plugins` | `SledPlugin[]` | — | Sled plugins (e.g., storybook) |
| `pool` | `string` | — | Custom pool configuration |
| `poolVersion` | `string` | — | Pool version |
| `artifactIdToUseForFingerprintOverride` | `string` | — | Override CI fingerprint with another artifact |
| `lighthouseCreateFlowResultRunsNumber` | `number` | — | Lighthouse flow result runs |
| `playwrightConfig` | `PlaywrightTestConfig` | — | Standard Playwright config (merged with Sled defaults) |

### ArtifactsOverridePolicy

```typescript
enum ArtifactsOverridePolicy {
  DISABLE = 'DISABLE',                   // No artifact overrides
  FAIL_ON_MISSING = 'FAIL_ON_MISSING',   // Error if statics not found (default)
  IGNORE_MISSING = 'IGNORE_MISSING',     // Silently skip if not found
}
```

### Non-Overridable Keys

Sled controls these — your `playwrightConfig` values are ignored:
- `outputDir`, `build`, `updateSnapshots`, `snapshotPathTemplate`
- `globalSetup`, `globalTeardown` (merged with Sled's own)
- `reporter`, `webServer`, `projects`, `use`

---

## Playwright Config Options (via `playwrightConfig`)

### Parallel Execution

```typescript
playwrightConfig: {
  fullyParallel: true,              // Run tests within files in parallel
  workers: process.env.CI ? 4 : 1, // Number of parallel workers
}
```

- `fullyParallel: true` runs tests within a single file concurrently
- `workers` controls how many files run simultaneously
- Worker isolation: each worker gets its own browser context
- Default: sequential within files, parallel across files

### Retry Configuration

```typescript
playwrightConfig: {
  retries: process.env.CI ? 2 : 0,   // Retry failed tests (CI only)
  repeatEach: 1,                       // Repeat each test N times
}
```

- `retries` automatically reruns failed tests
- Use `repeatEach` with `detect-flakiness` for flakiness detection
- CI best practice: `retries: 2` to handle transient failures

### Timeouts

```typescript
playwrightConfig: {
  timeout: 120_000,          // Per-test timeout (default: 30s)
  use: {
    actionTimeout: 30_000,   // Per-action timeout (click, fill, etc.)
    navigationTimeout: 90_000, // Navigation timeout
  },
}
```

### Global Setup/Teardown

```typescript
playwrightConfig: {
  globalSetup: require.resolve('./global-setup'),
  globalTeardown: require.resolve('./global-teardown'),
}
```

Note: Sled merges your global setup/teardown with its own internal ones.

### Project Dependencies

```typescript
playwrightConfig: {
  projects: [
    { name: 'setup', testDir: 'e2e/_setup' },
    { name: 'sanity', testDir: 'e2e/tests/sanity', dependencies: ['setup'] },
    { name: 'features', testDir: 'e2e/tests/features', dependencies: ['sanity'] },
  ],
}
```

Projects with `dependencies` wait for dependency projects to complete first. Useful for:
- Setup project that creates test data
- Sanity checks before running full suite
- Run with `--no-deps` to skip dependencies locally

---

## Real Production Configs

### Standard BM App

```typescript
export default defineSledConfig({
  artifactId: 'my-bm-app',
  artifactsOverridePolicy: ArtifactsOverridePolicy.DISABLE,
  playwrightConfig: {
    testDir: 'e2e',
    timeout: 120_000,
    use: {
      testIdAttribute: 'data-hook',
      browserName: 'chromium',
      trace: 'retain-on-failure',
      video: 'retain-on-failure',
      actionTimeout: 30_000,
      navigationTimeout: 90_000,
    },
  },
});
```

### With Storybook Plugin

```typescript
import { storybookPlugin } from '@wix/playwright-storybook-plugin';

export default defineSledConfig({
  artifactsOverridePolicy: ArtifactsOverridePolicy.DISABLE,
  playwrightConfig: {
    testDir: 'e2e',
    timeout: 90_000,
    use: { testIdAttribute: 'data-hook' },
  },
  plugins: [
    storybookPlugin({
      pathToStatics: 'storybook-static',
      storiesToIgnoreRegex: ['.*--docs$', '.*-playground$'],
      deleteOldTestFiles: true,
    }),
  ],
});
```

### Multi-Project with Dependencies (responsive-editor)

```typescript
export default defineSledConfig({
  artifactId: 'responsive-editor-packages',
  baseUrlsToInterceptArtifacts: ['https?://localhost:3[2356]01/'],
  playwrightConfig: {
    testDir: './e2e',
    testMatch: '**/*.e2e.ts',
    fullyParallel: false,
    timeout: 180_000,
    globalTimeout: 840_000,
    use: { testIdAttribute: 'data-hook', actionTimeout: 15_000 },
    projects: [
      { name: 'setup', testDir: 'e2e/_setup' },
      { name: 'sanity', testDir: 'e2e/tests/sanity' },
      { name: 'studio', testDir: 'e2e/tests/studio', dependencies: ['sanity'] },
    ],
  },
});
```

### CI vs Local (thunderbolt)

```typescript
const isCI = !!process.env.CI;
export default defineSledConfig({
  artifactId: 'wix-thunderbolt-ds',
  playwrightConfig: {
    testDir: 'sled3_tests',
    repeatEach: isCI ? 3 : 1,
    timeout: 90_000,
  },
  artifactsOverridePolicy: isCI
    ? ArtifactsOverridePolicy.FAIL_ON_MISSING
    : ArtifactsOverridePolicy.DISABLE,
});
```

### Artifact Version Overrides (per test)

```typescript
test.use({
  artifactsUrlOverride: [
    { groupId: 'com.wixpress', artifactId: 'my-app', version: '1.2.3' },
    { groupId: 'com.wixpress', artifactId: 'other', version: 'RC' },
  ],
});
```

---

## CLI Reference

### Init

```bash
npx @wix/sled-playwright init
```
Interactive setup: adds .gitignore, scripts, test dir, config, postPublish, installs Playwright.

### Test

```bash
sled-playwright test [options] [test-files]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--remote` | `-r` | Run on remote Sled cluster |
| `--debug` | `-d` | Step-through debugging (Playwright Inspector) |
| `--headed` | | Show browser window |
| `--grep "pattern"` | | Filter tests by name pattern |
| `--grepInvert "pattern"` | | Exclude tests matching pattern |
| `--update-snapshots` | `-u` | Update visual baselines |
| `--repeat-each N` | | Repeat each test N times |
| `--project NAME` | | Run specific project only |
| `--no-deps` | | Skip project dependencies |
| `--rerun-all` | | Rerun all tests (not just failed) |
| `--alias NAME` | `-a` | Custom artifact alias |
| `--live-tracker` | `-lt` | Real-time progress dashboard |
| `--static-resources-override` | `-sr` | Override static resources |
| `--global-experiments` | `-ge` | Apply global experiments |

### Detect Flakiness

```bash
sled-playwright detect-flakiness [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--repeat-count` | `20` | Number of repetitions per test |
| `--test-max-failures` | `0` | Max failures before stopping (0 = unlimited) |
| `--base-branch` | `origin/master` | Branch to compare against |
| `--path` | — | Specific test file path |
| `--test-file-suffix` | — | Filter by file suffix |
| `--alias` | — | Custom artifact alias |

### Other Commands

```bash
sled-playwright show-report          # Open HTML test report
sled-playwright ci                    # Bundle tests + trigger CI with sharding
sled-playwright install-stable        # Install stable Playwright version
sled-playwright install-next          # Install next Playwright version
sled-playwright supported-versions    # Show supported Playwright versions
```

### package.json Scripts

```json
{
  "scripts": {
    "test:e2e": "sled-playwright test",
    "postPublish": "sled-playwright test"
  }
}
```

**Why `postPublish`:** Sled 3 relies on published statics on parastorage. Tests run after publish to ensure statics are available.

### Local Development

Always prefix with `CI=false` to prevent `defineSledConfig()` crashes:
```bash
CI=false npx sled-playwright test
CI=false npx sled-playwright test feature.spec.ts
CI=false npx sled-playwright test --grep "@smoke"
```
