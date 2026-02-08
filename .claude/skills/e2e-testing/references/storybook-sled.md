# Storybook Visual Regression with Sled 3

`@wix/playwright-storybook-plugin` — Automatically generates visual regression tests from Storybook stories. Replaces Sled 2's custom Storybook integration.

**Source**: `wix-private/sled-playwright` → `packages/playwright-storybook-plugin`

---

## When to Use

- Project has Storybook and uses Sled 3 (`@wix/sled-playwright`)
- Need visual regression testing for UI components
- Want automated test generation from existing stories
- Migrating from Sled 2's Storybook visual tests

---

## Setup

### Install

```bash
yarn add -D @wix/playwright-storybook-plugin
```

### Configuration

```typescript
// playwright.config.ts
import { defineSledConfig } from '@wix/sled-playwright';
import { storybookPlugin } from '@wix/playwright-storybook-plugin';

export default defineSledConfig({
  plugins: [
    storybookPlugin({
      pathToStatics: 'storybook-static',        // Required: Storybook build dir
      port: 6006,                                // Local dev server port
      delayBeforeTakingImage: 1500,              // ms to wait before screenshot
      imageMatcherOptions: {
        threshold: 0.01,                         // 1% visual diff tolerance
      },
      storiesToIgnoreRegex: [
        '.*--docs$',                             // Skip documentation stories
        '.*-playground$',                        // Skip playground stories
      ],
      deleteOldTestFiles: true,                  // Remove orphaned test files
      forceGeneratingTests: false,               // Don't overwrite existing tests
      testsPath: '',                             // Subdirectory for tests
    }),
  ],
  playwrightConfig: {
    testDir: 'e2e',
    use: { testIdAttribute: 'data-hook' },
  },
});
```

### Build Storybook First

```bash
# Build Storybook statics (required before running tests)
yarn build-storybook

# Or ensure storybook-static/ exists from CI
```

---

## Plugin Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pathToStatics` | `string` | **Required** | Storybook static build directory |
| `port` | `number` | `6006` | Local dev server port |
| `delayBeforeTakingImage` | `number` | `1500` | ms delay before screenshot |
| `imageMatcherOptions` | `object` | `{threshold: 0.01}` | Playwright `toHaveScreenshot` options |
| `storiesToIgnoreRegex` | `string[]` | `[]` | Regex patterns to exclude stories |
| `deleteOldTestFiles` | `boolean` | `true` | Delete orphaned test files |
| `forceGeneratingTests` | `boolean` | `false` | Regenerate existing tests |
| `customTemplatePath` | `string` | - | Path to custom EJS test template |
| `testsPath` | `string` | - | Subdirectory under `__tests__/storybook-visual/` |
| `testFileNameSuffix` | `string` | - | Suffix before `.ts` (e.g., `.sled`) |
| `batchSize` | `number` | `1` | Stories per test file (for large repos) |

### Generation Behavior Matrix

| `deleteOldTestFiles` | `forceGeneratingTests` | Behavior |
|---------------------|----------------------|----------|
| `true` | `true` | Delete all + regenerate all (CI/fresh builds) |
| `true` | `false` | Delete orphans + skip existing (default, dev) |
| `false` | `true` | Keep all + overwrite existing |
| `false` | `false` | Keep all + generate only missing (incremental) |

---

## Generated Test Format

The plugin auto-generates test files in `__tests__/storybook-visual/`:

```typescript
// __tests__/storybook-visual/button--primary.spec.ts (auto-generated)
import { test, expect } from '@wix/sled-playwright';
import { getStorybookUrl } from '@wix/playwright-storybook-plugin';

test('Button Primary', async ({ page }) => {
  await page.goto(getStorybookUrl('button--primary'), {
    waitUntil: 'domcontentloaded',
  });
  await page.waitForTimeout(1500);
  await page.waitForLoadState('networkidle');
  await expect(page).toHaveScreenshot('button--primary.png', {
    threshold: 0.01,
  });
});
```

### `getStorybookUrl(storyId)`

Handles URL generation for both environments:
- **Local**: `http://localhost:6006/iframe?id=${storyId}`
- **CI**: `${REMOTE_STORYBOOK_URL}/iframe?id=${storyId}`

---

## Running

```bash
# Run all storybook visual tests
sled-playwright test

# Run with remote browsers (recommended for visual tests)
sled-playwright test --remote

# Update snapshots after intentional changes
sled-playwright test --update-snapshots
```

### With Existing package.json Script

```json
{
  "scripts": {
    "test:storybook": "sled-playwright test --config=playwright.storybook.config.ts",
    "test:e2e": "sled-playwright test"
  }
}
```

---

## Custom Test Templates

For custom screenshot logic beyond the default template:

### 1. Create EJS Template

```ejs
<!-- sled/storyTemplate.ejs -->
import {runStorybookTest} from './runStorybookTest';

runStorybookTest({
  cleanStoryName: '<%= cleanStoryName %>',
  storyId: '<%= storyId %>',
  delayMs: <%= delayMs %>,
  imageMatcherOptions: JSON.parse(atob('<%- btoa(JSON.stringify(imageMatcherOptions)) %>')),
});
```

### 2. Create Test Runner

```typescript
// runStorybookTest.ts
import { test, expect } from '@wix/sled-playwright';
import { getStorybookUrl, EjsParams } from '@wix/playwright-storybook-plugin';

export const runStorybookTest = (params: EjsParams) => {
  const { cleanStoryName, storyId, delayMs, imageMatcherOptions } = params;

  test(cleanStoryName, async ({ page }) => {
    await page.goto(getStorybookUrl(storyId), {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });
    await page.waitForTimeout(delayMs);
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveScreenshot(`${storyId}.png`, imageMatcherOptions);
  });
};
```

### 3. Reference in Config

```typescript
storybookPlugin({
  pathToStatics: 'storybook-static',
  customTemplatePath: './sled/storyTemplate.ejs',
});
```

---

## Memory Optimization (Large Repos)

For 500+ stories:

```typescript
storybookPlugin({
  pathToStatics: 'storybook-static',
  batchSize: 10,  // Group 10 stories per test file
});
```

This reduces:
- Test file count: 1000 → 100 (for batchSize 10)
- Peak memory: ~30-50% reduction
- File system pressure from Playwright worker management

If still OOM, reduce workers:

```typescript
defineSledConfig({
  playwrightConfig: { workers: 10 },
  plugins: [storybookPlugin({ ... })],
});
```

---

## CI Environment

Set `REMOTE_STORYBOOK_URL` to skip local server:

```bash
REMOTE_STORYBOOK_URL=https://storybook-preview.example.com sled-playwright test
```

---

## Sled 2 Comparison

| Feature | Sled 2 | Sled 3 Plugin |
|---------|--------|--------------|
| Config | `storybook-sled-e2e.json` | `storybookPlugin()` in `playwright.config.ts` |
| Test runner | Puppeteer | Playwright |
| Browser support | Chromium only | Chromium, Firefox, Safari |
| Visual testing | Custom implementation | Native Playwright screenshots |
| CI integration | Custom setup | Built-in web server management |
| Story extraction | Puppeteer + Express | Playwright + native serving |

The plugin uses the **same configuration options** as Sled 2 for easy migration — just move them into `storybookPlugin()`.
