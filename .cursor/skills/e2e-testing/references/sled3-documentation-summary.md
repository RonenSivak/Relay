# Sled 3 (@wix/sled-playwright) — Comprehensive Documentation Summary

> Researched from `wix-private/sled-playwright` repo (wix-docs, packages) and Wix internal docs. Use this for creating specialized skills.

---

## 1. Getting Started / Setup

### Installation

**CLI (recommended):**
```bash
npx @wix/sled-playwright init
```
Interactive CLI sets up: `.gitignore` exclusions, `package.json` scripts, tests directory, `playwright.config.ts`, `postPublish` validation, and installs matching `@playwright/test`.

**Manual:**
```bash
yarn add -D @wix/sled-playwright
```

### Playwright Version

Sled 3 uses `@playwright/test` as a **peer dependency**. Install supported versions via:
```bash
npx @wix/sled-playwright install-stable   # or install-next
npx @wix/sled-playwright supported-versions
```

### Minimal Config (`playwright.config.ts`)

```typescript
import {
  defineSledConfig,
  ArtifactsOverridePolicy,
} from '@wix/sled-playwright';

export default defineSledConfig({
  artifactId: 'your-artifact-id',  // or derived from package.json
  artifactsOverridePolicy: ArtifactsOverridePolicy.DISABLE,

  playwrightConfig: {
    testDir: 'e2e',
    projects: [
      { name: 'chrome', use: { browserName: 'chromium' } },
    ],
  },
});
```

### First Test

```typescript
import { test, expect } from '@wix/sled-playwright';

test.describe('user login sanity', () => {
  test('should login a user', async ({ page, auth }) => {
    await auth.loginAsUser('your-test-user@wix.com');
    await page.goto(`https://www.wix.com/dashboard/your-msid/home`);
    await expect(
      page.getByRole('heading', { name: 'Welcome back, username' })
    ).toBeVisible();
  });
});
```

### Key Differences from Sled 2

| Aspect | Sled 2 | Sled 3 |
|--------|--------|--------|
| Framework | Puppeteer + Jest | Playwright |
| Execution | AWS Lambda | Kubernetes |
| Global object | `sled` | Fixtures (`auth`, `site`, etc.) |
| Config | `sled/sled.json` | `playwright.config.ts` + `defineSledConfig` |

---

## 2. Configuration (`defineSledConfig` Options)

### Signature

```typescript
defineSledConfig(params: WixPlaywrightConfigParams): PlaywrightTestConfig
```

### Wix-Specific Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `artifactId` | `string` | from package.json | Artifact ID for overrides and tracing |
| `pathToStatics` | `string` | `'dist/statics'` | Path to static files |
| `artifactsOverridePolicy` | `ArtifactsOverridePolicy` | `FAIL_ON_MISSING` | `DISABLE` \| `FAIL_ON_MISSING` \| `IGNORE_MISSING` |
| `artifactsUrlOverride` | `ArtifactsUrlOverride[]` | — | Override artifact URLs (version: `'1.2.3'`, `'RC'`, `'currentVersionFromMonorepo'`) |
| `baseUrlsToInterceptArtifacts` | `string[]` | `['https?://localhost:3[32]0[01]/']` | URL patterns for artifact overrides |
| `gotoConfig` | `{ queryParams?: Record<string, unknown> }` | — | Default query params for navigation |
| `fullPageScreenshotConfig` | `{ scrollableElementSelector?: string }` | — | Default for `toHaveFullPageScreenshot` (e.g. `'[data-hook="page-scrollable-content"]'`) |
| `globalExperiments` | `Experiment[]` | — | Experiments applied to all tests |
| `noAutomationFlagging` | `boolean` | `false` | Disable automation cookies |
| `disableBiEvents` | `boolean` | `true` | Block BI events via BI Interceptor |
| `artifactIdToUseForFingerprintOverride` | `string` | — | Override fingerprint for CI |
| `github` | `GithubConfig` | — | PR report and live tracker |

### `github` Config

```typescript
github: {
  report: { enabled?: boolean },   // default: true — PR comments
  liveTracker: { enabled?: boolean }  // default: false — live dashboard
}
```

### Standard Playwright Options (via `playwrightConfig`)

All options from [Playwright Test Configuration](https://playwright.dev/docs/test-configuration), e.g. `testDir`, `projects`, `timeout`, `retries`, `workers`, etc.

### Sled 2 → Sled 3 Config Mapping

| Sled 2 (`sled.json`) | Sled 3 (`playwright.config.ts`) |
|----------------------|----------------------------------|
| `artifact_id` | `artifactId` |
| `artifacts_upload.artifacts_dir` | `pathToStatics` |
| `base_urls_to_intercept_artifacts` | `baseUrlsToInterceptArtifacts` |
| `artifactsUrlOverride` | `artifactsUrlOverride` |
| `sled_folder_relative_path_in_repo` | `playwrightConfig.testDir` |
| `artifactId_to_use_for_fingerprint_override` | `artifactIdToUseForFingerprintOverride` |

---

## 3. Built-in Fixtures

### Overview

All fixtures are requested as test parameters: `async ({ page, auth, site, ... }) => { }`.

### `auth`

```typescript
// Login as registered Wix user
await auth.loginAsUser(email: string): Promise<void>

// Login as site member
await auth.loginAsMember(siteUrl: string, memberEmail: string): Promise<void>

// Create disposable member and login
await auth.loginAsDisposableMemberToSite(
  siteUrl: string,
  memberEmail?: string,
  referral?: string
): Promise<{ email: string; cookies: string[] }>
```

**Via `test.use`:** `test.use({ user: 'test@wix.com' })` for auto-login.

---

### `site`

```typescript
// Assign premium to site
await site.assignPremiumToSite(metaSiteId: string): Promise<void>

// Clone site and run callback with new context
await site.cloneSiteAndReturnOwnerToken(
  options: {
    sourceMetaSiteId: string;
    userEmail?: string;
    publish?: boolean;
    newSiteName?: string;
  },
  handler: (wixContext, params) => Promise<void>
): Promise<void>
```

`params` includes: `newMetaSiteId`, `newSiteId`, `newSiteName`, `siteOwnerEmail`, `storyId?`, `isPublished?`. Cloned sites are tagged for cleanup. Interceptors in `test.use()` are preserved; `interceptionPipeline` setup is not.

---

### `experiment` / `setExperiments`

**Config level:** `globalExperiments: [{ key, val }, ...]`  
**Per file/block:** `test.use({ experiments: [{ key, val }, ...] })`  
**Per test:** `await setExperiments(experiments: Experiment[], newContext?)`

```typescript
interface Experiment { key: string; val: string; }
```

---

### `interceptionPipeline`

See [Interception Pipeline](#4-interception-pipeline) below.

---

### `biSpy`

```typescript
// Filter by source (src) and event ID (evid)
biSpy.bySrc(src: number).byEvid(evid: number)
biSpy.byFields(fields: Record<string, string | number>)

// Retrieval
.first() | .last() | .all() | .count()

// Reset
biSpy.reset()
```

Event shape: `{ src, evid, ...customFields }`.

---

### `urlBuilder`

Fluent URL builder. Main methods:

```typescript
urlBuilder()
  .url(baseUrl: string)
  .withExperiment(name: string, value: unknown)
  .withUnpublishedExperimentOn(name) | .withUnpublishedExperimentOff(name)
  .withQueryParam(key, value) | .withQueryParams(params)
  .withViewerScriptOverride(appDefId, entryFile)
  .withWidgetUrlOverride(widgetId, entryFile)
  .withControllerUrlOverride(widgetId, entryFile)
  .withEditorScriptUrlOverride(appDefId, entryFile)
  .withEditorExtensionsOverrides(extensionId, entryFile)
  .withPlatformBaseUrls(appDefId, baseUrls)
  .withForceThunderbolt(value?)
  .withSiteRevision(revision)
  .withShowMobileView(value?)
  .withSsrWarmupOnly(value?) | .withSsrDebug(value?) | .withExcludeSiteFromSsr()
  .build(): string

  .clone(): UrlBuilder  // Copy with shared config
```

---

### `memoize`

Cache expensive async work across workers (distributed lock, cross-worker):

```typescript
const fn = memoize(
  async (...args) => { /* expensive op */ },
  {
    key: 'namespace:operation',  // Required (or namespace in some docs)
    ttl: 3000,                  // seconds, default ~50 min
    timeout: 10,                // seconds, lock timeout (default 10)
    keyResolver: (...args) => string  // For Map/Set/complex args
  }
);
```

Use `memoize(auth.loginAsUser.bind(auth), { key: 'auth:login' })` to cache login.

---

### `file`

```typescript
await file.deployCachedFile({
  content: string,
  extension: 'html' | 'js',
}): Promise<string>

await file.bundleWixCodeApp(files, wrapper, options?): Promise<string>

await file.deployWixPlatformApp(
  functions,
  buildViewerApp,
  babelOptions?,
  additionalCacheDeps?
): Promise<string>
```

---

### `getAppToken` (appTokens)

```typescript
const token = await getAppToken(appId: string): string | undefined
```

Works with App Tokens Interceptor. Call after navigation so tokens are captured.

---

### `daos`

Record/replay network traffic (HAR-based):

```typescript
// In __tests__/daos/*.daos.spec.ts (runs first)
await daos.record(stateId: string, updateMode?: 'full' | 'minimal'): Promise<void>

// In regular tests
await daos.replay(stateId: string): Promise<void>
```

DAOS tests run before others via project pattern `**/daos/*.daos.spec.ts`.

---

### `createWixContext` (base)

Create a new browser context with Sled setup:

```typescript
const { context, page } = await createWixContext();
```

---

## 4. Interception Pipeline

### Overview

`interceptionPipeline` fixture handles network interception. Uses `context.route()` under the hood.

### InterceptHandler Interface

```typescript
interface InterceptHandler {
  id?: string;
  pattern?: RegExp | string;  // URL matcher
  handler(params: HandlerParams): InterceptionResult;
  shouldReport?: boolean;
}

interface HandlerParams {
  url: string;
  headers: Headers;
  method: string;
  postData: unknown;
  resourceType: string;
}
```

### InterceptHandlerActions (enum)

From `@wix/browser-integrations` (re-exported from `@wix/sled-playwright`):

```typescript
enum InterceptHandlerActions {
  CONTINUE = 'CONTINUE',
  FALLBACK = 'FALLBACK',
  ABORT = 'ABORT',
  INJECT_RESOURCE = 'INJECT_RESOURCE',
  INJECT_REMOTE_RESOURCE = 'INJECT_REMOTE_RESOURCE',
  EMPTY_RESPONSE = 'EMPTY_RESPONSE',
  REDIRECT = 'REDIRECT',
  MODIFY_RESOURCE = 'MODIFY_RESOURCE',
  HOLD = 'HOLD',
  MODIFY_REQUEST = 'MODIFY_REQUEST',
  ASYNC_INTERCEPT = 'ASYNC_INTERCEPT',
}
```

### Action Return Shapes

| Action | Return Shape |
|--------|--------------|
| `CONTINUE` | `{ action: InterceptHandlerActions.CONTINUE }` |
| `ABORT` | `{ action: InterceptHandlerActions.ABORT }` |
| `EMPTY_RESPONSE` | `{ action: InterceptHandlerActions.EMPTY_RESPONSE }` |
| `INJECT_RESOURCE` | `{ action, resource: Buffer, responseCode?, responseHeaders?, responsePhrase? }` |
| `INJECT_REMOTE_RESOURCE` | `{ action, remoteResourceUrl, forwardHeaders?, modifyHeaders? }` |
| `REDIRECT` | `{ action, url, headers? }` |
| `MODIFY_REQUEST` | `{ action, url?, headers?, postData? }` |
| `MODIFY_RESOURCE` | `{ action, modifyBody: (body, { statusCode }) => ..., modifyHeaders?, status? }` |
| `HOLD` | `{ action, waitUntil: () => Promise<void> }` |
| `ASYNC_INTERCEPT` | `{ action, asyncResult: () => Promise<InterceptionResult> }` |

### Setup Patterns

**1. Via `interceptionPipeline.setup()` (recommended):**

```typescript
await interceptionPipeline.setup([
  { pattern: '**/api/users', handler: () => ({ action: InterceptHandlerActions.INJECT_RESOURCE, resource: Buffer.from(JSON.stringify({ id: 1 })), responseHeaders: { 'Content-Type': 'application/json' } }) },
  { pattern: '**/api/**', handler: () => ({ action: InterceptHandlerActions.ABORT }) },  // catch-all
]);
```

**2. Via `interceptionPipeline.interceptors.push()`:**

```typescript
interceptionPipeline.interceptors.push({
  pattern: 'https://api.example.com/*',
  handler({ url }) { return { action: InterceptHandlerActions.CONTINUE }; },
});
```

**3. Via `test.use({ interceptors })`:**

```typescript
test.use({
  interceptors: [
    { pattern: '**/api/mock', handler: () => ({ action: InterceptHandlerActions.INJECT_RESOURCE, resource: Buffer.from('{}') }) },
  ],
});
```

### Reports

```typescript
interceptionPipeline.reports: InterceptionReport[]
```

Filter by URL/pattern to assert intercepted requests.

### Ordering (LIFO)

Handlers run **last-in-first-out** (like Playwright `context.route()`). Specific mocks first, catch-all `ABORT` last.

### Built-in Interceptors

- BI Interceptor — BI events
- Panorama Interceptor — analytics
- Sentry Interceptor — error reports
- App Tokens Interceptor — app tokens

---

## 5. CLI Commands

### init

```bash
npx @wix/sled-playwright init
```

### install-stable / install-next / supported-versions

```bash
npx @wix/sled-playwright install-stable
npx @wix/sled-playwright install-next
npx @wix/sled-playwright supported-versions
```

### test

```bash
npx @wix/sled-playwright test [path] [options]
```

**Wix-specific flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--artifacts-override-policy` | `-a` | `DISABLE` \| `FAIL_ON_MISSING` \| `IGNORE_MISSING` |
| `--remote` | `-r` | Remote execution |
| `--with-dependency-tests` | `-d` | Run dependency tests |
| `--silent-report` | `-sr` | No auto-open report |
| `--global-experiments` | `-ge` | `key1=val1,key2=val2` |
| `--rerun-all` | — | Run full suite on rerun (skip smart rerun) |
| `--live-tracker` | `-lt` | Live dashboard |

**Standard Playwright flags:** `--config`, `--debug`, `--headed`, `--grep`, `--project`, `--timeout`, `--update-snapshots`, `--ui`, etc.

### detect-flakiness

```bash
npx @wix/sled-playwright detect-flakiness [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--base-branch` | `origin/master` | Base for changed files |
| `--repeat-count` | `20` | Runs per test |
| `--test-max-failures` | `0` | Max failures before “flaky” |
| `--test-file-suffix` | `.spec.ts` | Test file pattern |
| `--alias` | `flakiness-detection` | Custom alias |

### show-report

```bash
npx @wix/sled-playwright show-report
```

---

## 6. Visual Testing / Storybook Integration

### Playwright Snapshots

Sled 3 uses Playwright’s `toHaveScreenshot()`:

```typescript
await expect(page).toHaveScreenshot();
await expect(page.locator('div')).toHaveScreenshot();
```

### toHaveFullPageScreenshot (custom matcher)

For full-page content (e.g. scrollable containers):

```typescript
await expect(page).toHaveFullPageScreenshot(name?, options?);
```

**Options:** `additionalHeightExpand`, `scrollableElementSelector`, `maxDiffPixels`, `maxDiffPixelRatio`, `threshold`, `mask`, `timeout`.

**Config default:** `fullPageScreenshotConfig: { scrollableElementSelector: '[data-hook="page-scrollable-content"]' }` for WDS pages.

### Visual Test Best Practices

1. Run remotely: `--remote`
2. Wait for animations before snapshots
3. Use stable selectors; avoid timestamps/dynamic content
4. Update with `--update-snapshots`
5. Prefer element snapshots over full-page

### Sheshesh Migration

Sled 2 Sheshesh is replaced by Playwright visual testing. No mask/ignore; regressions shown at repo level.

---

## 7. Best Practices

### Fixtures

- Extend base fixtures via `test.extend()`
- Prefer composition and modular design
- Use `memoize` for costly setup (auth, site creation)

### API Blocking (Catch-All)

- Sled 3: `interceptionPipeline.setup([...mocks, catchAll])` with `ABORT` last
- Specific mocks before catch-all; order is LIFO

### Locators

- Prefer `getByRole`, `getByTestId`, semantic locators
- Avoid brittle CSS when possible

### Flaky Tests

- Use `detect-flakiness` on changed tests
- Wait for load/animations before assertions
- Mask dynamic content in visual tests

### Test Budget

- 2–4 behavioral tests per component
- Prefer user flows over simple visibility checks

---

## 8. Migration from Sled 2

### Global Object → Fixtures

| Sled 2 | Sled 3 |
|--------|--------|
| `sled.loginAsUser(page, email)` | `auth.loginAsUser(email)` |
| `sled.assignPremiumToSite(metaSiteId)` | `site.assignPremiumToSite(metaSiteId)` |
| `sled.cloneSiteAndExecuteWithLoggedInOwner(...)` | `site.cloneSiteAndReturnOwnerToken(...)` |
| `sled.deployCachedFile(...)` | `file.deployCachedFile(...)` |
| `sledPage.biSpy` | `biSpy` fixture |
| `sledPage.getAppToken(...)` | `getAppToken(...)` fixture |
| `sled.patchSledPageForDAOS(true)` | `daos.record(...)` |
| `sled.withDAOSState(...)` | `daos.replay(...)` |

### Request Interception

| Sled 2 | Sled 3 |
|--------|--------|
| `page.setRequestInterception(true)` + `page.on('request', ...)` | `interceptionPipeline.setup([...])` |
| FIFO ordering | LIFO ordering |

### Config

`sled.json` → `playwright.config.ts` with `defineSledConfig`.

### CLI

`@wix/sled-test-runner` → `@wix/sled-playwright`.

---

## 9. Related Files in sled-playwright Repo

| Path | Purpose |
|------|---------|
| `wix-docs/getting-started/getting-started.md` | Setup |
| `wix-docs/api/configuration.md` | Config reference |
| `wix-docs/api/cli.md` | CLI reference |
| `wix-docs/api/fixtures/*.md` | Fixture docs |
| `wix-docs/api/interceptors/*.md` | Interception docs |
| `wix-docs/api/expect/full-page-screenshot.md` | Visual API |
| `wix-docs/best-practices/*.md` | Practices |
| `packages/playwright/src/config/` | Config implementation |
| `packages/browser-integrations/src/interceptors/` | InterceptHandlerActions |

---

## 10. Wix Internal Docs

Search with `search_docs` MCP for: `sled-playwright`, `sled 3`, `e2e testing sled`, `sled configuration`, `sled getting started`.

---

<tldr>
- **Sled 3** = Playwright-based E2E framework; replace Sled 2’s Jest/Puppeteer.
- **Setup:** `npx @wix/sled-playwright init` or manual install + `defineSledConfig`.
- **Fixtures:** `auth`, `site`, `experiment`, `interceptionPipeline`, `biSpy`, `urlBuilder`, `memoize`, `file`, `getAppToken`, `daos`, `createWixContext`.
- **Interception:** `interceptionPipeline.setup([...])` with `InterceptHandler`; actions via `InterceptHandlerActions`; LIFO ordering; catch-all `ABORT` last.
- **CLI:** `init`, `test`, `install-stable`/`install-next`, `supported-versions`, `detect-flakiness`, `show-report`.
- **Visual:** Playwright snapshots + `toHaveFullPageScreenshot` for scrollable pages.
- **Migration:** Global `sled` → fixtures; `sled.json` → `defineSledConfig`; FIFO → LIFO for interceptors.
</tldr>
