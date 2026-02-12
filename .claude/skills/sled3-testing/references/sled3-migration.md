# Sled 2 to Sled 3 Migration Guide

## Overview

| Feature | Sled 2 (`@wix/sled-test-runner`) | Sled 3 (`@wix/sled-playwright`) |
|---------|----------------------------------|--------------------------------|
| Browser engine | Puppeteer (Chromium only) | Playwright (Chromium, Firefox, WebKit) |
| Test runner | Jest | Playwright Test |
| Execution | AWS Lambda | Kubernetes |
| Config | `sled/sled.json` | `playwright.config.ts` with `defineSledConfig()` |
| CLI | `npx sled-test-runner` | `sled-playwright test` |
| Auth | `sled.newPage({ user })` | `auth` fixture |
| Interceptors | FIFO (first match wins) | LIFO (last registered runs first) |
| Visual testing | `storybook_config` in sled.json | `@wix/playwright-storybook-plugin` |
| File naming | `*.sled.spec.ts` | `*.sled3.spec.ts` or `*.spec.ts` |
| Browser access | `sled.newPage()` | `async ({ page }) =>` fixture |

---

## Config Migration

### Sled 2 (`sled/sled.json`)
```json
{
  "artifact_id": "my-app",
  "artifacts_upload": {
    "artifacts_dir": "dist/statics"
  },
  "base_urls_to_intercept_artifacts": ["https://static.parastorage.com"],
  "test_path_patterns": ["tests/**/*.spec"],
  "sled_folder_relative_path_in_repo": "sled"
}
```

### Sled 3 (`playwright.config.ts`)
```typescript
import { defineSledConfig, ArtifactsOverridePolicy } from '@wix/sled-playwright';

export default defineSledConfig({
  artifactId: 'my-app',
  pathToStatics: 'dist/statics',
  baseUrlsToInterceptArtifacts: ['https://static.parastorage.com'],
  playwrightConfig: {
    testDir: 'e2e',
    use: { testIdAttribute: 'data-hook' },
  },
});
```

### Config Key Mapping

| Sled 2 (sled.json) | Sled 3 (playwright.config.ts) |
|---------------------|-------------------------------|
| `artifact_id` | `artifactId` |
| `artifacts_upload.artifacts_dir` | `pathToStatics` |
| `base_urls_to_intercept_artifacts` | `baseUrlsToInterceptArtifacts` |
| `sled_folder_relative_path_in_repo` | `playwrightConfig.testDir` |
| `totalSerialRetries` | `playwrightConfig.retries` |
| `storybook_config` | `plugins: [storybookPlugin({...})]` |

---

## Code Migration

### Test Structure

**Sled 2 (Jest + Puppeteer):**
```typescript
import type { Page } from '@wix/sled-test-runner';

describe('Feature', () => {
  let page: Page;
  beforeAll(async () => {
    const result = await sled.newPage();
    page = result.page;
  });
  afterAll(async () => { await page.close(); });

  it('should work', async () => {
    await page.goto(url);
    await page.waitForSelector('[data-hook="el"]');
    await page.click('[data-hook="btn"]');
    const text = await page.$eval('[data-hook="el"]', el => el.textContent);
    expect(text).toBe('expected');
  });
});
```

**Sled 3 (Playwright):**
```typescript
import { test, expect } from '@wix/sled-playwright';

test.describe('Feature', () => {
  test('should work', async ({ page }) => {
    await page.goto(url);
    await page.getByTestId('btn').click();  // auto-waits
    await expect(page.getByTestId('el')).toHaveText('expected');
  });
});
```

### Key Changes
- No `sled.newPage()` — use `{ page }` fixture
- No `beforeAll`/`afterAll` for page lifecycle — Playwright manages it
- No `waitForSelector` — Playwright locators auto-wait
- No `$eval` — use `expect` assertions or `locator.textContent()`
- `it()` -> `test()`, `describe()` -> `test.describe()`

### Auth

**Sled 2:**
```typescript
const { page } = await sled.newPage({ user: 'test@wix.com' });
// or
await sled.loginAsUser(page, 'test@wix.com');
```

**Sled 3:**
```typescript
test('with auth', async ({ page, auth }) => {
  await auth.loginAsUser('test@wix.com');
  await page.goto('/dashboard');
});
```

### Selectors

| Sled 2 (Puppeteer) | Sled 3 (Playwright) |
|---------------------|---------------------|
| `page.waitForSelector('[data-hook="el"]')` | `page.getByTestId('el')` (auto-waits) |
| `page.click('[data-hook="btn"]')` | `page.getByTestId('btn').click()` |
| `page.$eval('[data-hook="el"]', el => el.textContent)` | `page.getByTestId('el').textContent()` |
| `page.$('[data-hook="el"]')` | `page.getByTestId('el')` |
| `page.waitForFunction(() => ...)` | `expect.poll(async () => ...).toBe(...)` |

---

## Interceptor Migration

**CRITICAL:** Sled 2 uses FIFO (first match wins), Sled 3 uses LIFO (last registered runs first).

### Sled 2 (FIFO — catch-all goes LAST)
```typescript
import { InterceptionTypes } from '@wix/sled-test-runner';

const specificMock: InterceptionTypes.Handler = {
  execResponse({ url }) {
    if (url.includes('/api/items')) {
      return {
        action: InterceptionTypes.Actions.MODIFY_RESOURCE,
        modify: ({ body }) => ({
          body: Buffer.from(JSON.stringify({ items: [] })),
        }),
      };
    }
    return { action: InterceptionTypes.Actions.CONTINUE };
  },
};

const catchAll: InterceptionTypes.Handler = {
  execRequest({ url }) {
    if (url.match(/\/(api|_api)\//)) {
      return { action: InterceptionTypes.Actions.ABORT };
    }
    return { action: InterceptionTypes.Actions.CONTINUE };
  },
};

// FIFO: specific first, catch-all last
const { page } = await sled.newPage({
  interceptors: [specificMock, catchAll],
});
```

### Sled 3 (LIFO — catch-all goes LAST in array but runs FIRST)
```typescript
import { InterceptHandlerActions, type InterceptHandler } from '@wix/sled-playwright';

const specificMock: InterceptHandler = {
  pattern: /\/api\/items/,
  handler: () => ({
    action: InterceptHandlerActions.INJECT_RESOURCE,
    resource: Buffer.from(JSON.stringify({ items: [] })),
    responseCode: 200,
    responseHeaders: { 'Content-Type': 'application/json' },
  }),
};

const catchAll: InterceptHandler = {
  id: 'catch-all',
  pattern: /\/(api|_api)\//,
  handler: () => ({ action: InterceptHandlerActions.ABORT }),
};

// Specific mocks first, catch-all last in array
// LIFO: catch-all runs first, specific mocks handle their patterns
await interceptionPipeline.setup([specificMock, catchAll]);
```

### Key Differences

| Aspect | Sled 2 | Sled 3 |
|--------|--------|--------|
| Hook type | `execRequest` / `execResponse` | Single `handler` function |
| Actions import | `InterceptionTypes.Actions` | `InterceptHandlerActions` |
| MODIFY response | `MODIFY_RESOURCE` via `execResponse` | `MODIFY_RESOURCE` via `handler` |
| INJECT response | `INJECT_RESOURCE` via `execRequest` | `INJECT_RESOURCE` via `handler` |
| Ordering | FIFO (first match wins) | LIFO (last registered runs first) |
| Setup | `sled.newPage({ interceptors })` | `interceptionPipeline.setup([...])` |
| Pattern matching | Manual URL check in handler | `pattern` field (string glob or RegExp) |

---

## CLI Migration

| Action | Sled 2 | Sled 3 |
|--------|--------|--------|
| Run all (remote) | `npx sled-test-runner remote` | `sled-playwright test --remote` |
| Run all (local) | `npx sled-test-runner local` | `CI=false npx sled-playwright test` |
| Filter by file | `--testPathPattern="file"` | `sled-playwright test file.spec.ts` |
| Filter by name | `--testPathPattern="name"` | `--grep "name"` |
| Debug | `sled-test-runner local -d -k` | `sled-playwright test --debug` |
| Verbose | `-v -l` | `--trace on` |

---

## Storybook Migration

### Sled 2 (Sheshesh)
```json
// sled.json
{
  "storybook_config": {
    "storybook_path": "storybook-static",
    "ignore_stories": ["*--docs"]
  }
}
```

### Sled 3 (playwright-storybook-plugin)
```typescript
import { storybookPlugin } from '@wix/playwright-storybook-plugin';

export default defineSledConfig({
  plugins: [
    storybookPlugin({
      pathToStatics: 'storybook-static',
      storiesToIgnoreRegex: ['.*--docs$'],
      deleteOldTestFiles: true,
    }),
  ],
});
```

---

## BM App Migration

### Sled 2
```typescript
import { injectBMOverrides } from '@wix/yoshi-flow-bm/sled';
await injectBMOverrides({
  page,
  appConfig: require('../target/module-sled.merged.json'),
});
```

### Sled 3
BM apps generally work without `injectBMOverrides` in Sled 3 due to artifact override support. If still needed, check if `@wix/yoshi-flow-bm` exports a Sled 3-compatible version.

---

## Migration Checklist

- [ ] Install `@wix/sled-playwright` and matching `@playwright/test`
- [ ] Create `playwright.config.ts` with `defineSledConfig()`
- [ ] Migrate `sled.json` config keys
- [ ] Convert test files: `it()` -> `test()`, add fixtures
- [ ] Replace `sled.newPage()` with `{ page, auth }` fixtures
- [ ] Replace Puppeteer selectors with Playwright locators
- [ ] Migrate interceptors: FIFO -> LIFO ordering, new action names
- [ ] Add `postPublish` script to `package.json`
- [ ] Run `detect-flakiness` to verify stability
- [ ] Update CI configuration if needed
