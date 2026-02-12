# Visual Regression with @wix/playwright-storybook-plugin

Complete reference for Storybook visual regression testing with Sled 3.

## Setup

```bash
yarn add -D @wix/playwright-storybook-plugin
```

```typescript
// playwright.config.ts
import { defineSledConfig } from '@wix/sled-playwright';
import { storybookPlugin } from '@wix/playwright-storybook-plugin';

export default defineSledConfig({
  playwrightConfig: { testDir: 'e2e' },
  plugins: [
    storybookPlugin({
      pathToStatics: 'storybook-static',
      storiesToIgnoreRegex: ['.*--docs$', '.*-playground$'],
      deleteOldTestFiles: true,
    }),
  ],
});
```

**NOTE:** Package name is `@wix/playwright-storybook-plugin` (NOT `@wix/sled-playwright-storybook-plugin`).

---

## Plugin Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pathToStatics` | `string` | **Required** | Directory with Storybook static build |
| `port` | `number` | `6006` | Port for local Storybook server |
| `delayBeforeTakingImage` | `number` | `1500` | Delay (ms) before screenshot |
| `storiesToIgnoreRegex` | `string[]` | `[]` | Regex patterns to exclude stories |
| `imageMatcherOptions` | `PageAssertionsToHaveScreenshotOptions` | `{ threshold: 0.01 }` | Playwright screenshot comparison options |
| `deleteOldTestFiles` | `boolean` | `true` | Delete orphaned test files |
| `forceGeneratingTests` | `boolean` | `false` | Force regeneration of all tests |
| `customTemplatePath` | `string` | — | Path to custom EJS template |
| `testsPath` | `string` | `{testDir}/storybook-visual/` | Output directory for generated tests |
| `testFileNameSuffix` | `string` | `''` | Suffix before .ts (e.g. `.sled` -> `*.spec.sled.ts`) |
| `batchSize` | `number` | `1` | Stories per test file |

**DEPRECATED:** `threshold` option — use `imageMatcherOptions.threshold` instead.

---

## Configuration Matrix

| `deleteOldTestFiles` | `forceGeneratingTests` | Effect |
|---------------------|------------------------|--------|
| `true` | `true` | Delete ALL test files, regenerate everything |
| `true` | `false` | Delete orphaned tests only, skip existing (default) |
| `false` | `true` | Keep files, regenerate all (overwrite) |
| `false` | `false` | Keep files, generate only missing |

---

## storiesToIgnoreRegex Patterns

### Recommended Default
```typescript
storiesToIgnoreRegex: ['.*--docs$', '.*-playground$']
```

### Common Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| `'.*--docs$'` | Skip documentation stories | `components-button--docs` |
| `'.*-playground$'` | Skip interactive playgrounds | `components-button-playground` |
| `'.*--mobile$'` | Skip mobile-only stories | `components-header--mobile` |
| `'.*nosnap.*'` | Skip by custom tag | `components-button-nosnap-variant` |
| `'^(?!widget-homepage--\|widget-chatbot--).*$'` | Whitelist: ONLY run matching stories | Negative lookahead |

### PITFALL: `['.*']` Disables ALL Tests

```typescript
// WRONG — matches every story, no tests generated
storiesToIgnoreRegex: ['.*'],

// RIGHT — only skip docs and playgrounds
storiesToIgnoreRegex: ['.*--docs$', '.*-playground$'],
```

This is a common misconfiguration. The `['.*']` pattern silently disables all visual regression.

---

## Running Visual Tests

```bash
# Local (may have rendering differences vs remote)
CI=false npx sled-playwright test

# Remote (recommended — consistent rendering environment)
sled-playwright test --remote

# Update baselines after intentional changes
CI=false npx sled-playwright test --update-snapshots

# Run only storybook tests (if in separate project)
CI=false npx sled-playwright test --project storybook
```

**Always run remote** for visual tests — local rendering varies by OS/font.

---

## Real Configuration Examples

### Standard (em/invoices pattern)
```typescript
storybookPlugin({
  pathToStatics: 'storybook-static',
  port: 6006,
  delayBeforeTakingImage: 1500,
  imageMatcherOptions: { threshold: 0.02 },
  storiesToIgnoreRegex: ['.*--docs$', '.*-playground$'],
  deleteOldTestFiles: true,
  forceGeneratingTests: false,
  testsPath: 'e2e/storybook',
}),
```

### Tag-Based Exclusion (form-client)
```typescript
const EXCLUDE_TAG = 'nosnap';
storybookPlugin({
  pathToStatics: 'storybook-static',
  delayBeforeTakingImage: 3_000,
  imageMatcherOptions: { threshold: 0 },
  storiesToIgnoreRegex: [`.*${EXCLUDE_TAG}.*`],
  deleteOldTestFiles: true,
  testsPath: './sled/tests/__storybook_visual__',
  customTemplatePath: './sled/storybook-test-template.ejs',
}),
```

### Whitelist with Negative Lookahead (wix-chatbot)
```typescript
storybookPlugin({
  imageMatcherOptions: { threshold: 0.02 },
  storiesToIgnoreRegex: ['^(?!widget-homepage--|widget-chatbot--).*$'],
  deleteOldTestFiles: true,
  testsPath: 'sled/storybook-tests',
}),
```

### Large Storybook (500+ stories)
```typescript
storybookPlugin({
  pathToStatics: 'storybook-static',
  batchSize: 10,  // Group stories to reduce file count
}),
```

---

## Custom Template

For advanced screenshot control, use a custom EJS template:

```typescript
storybookPlugin({
  customTemplatePath: './sled/storybook-template.ejs',
}),
```

The template receives story metadata and controls how screenshots are taken.

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| No tests generated | `storiesToIgnoreRegex: ['.*']` | Fix to `['.*--docs$', '.*-playground$']` |
| Story not found | Stale `storybook-static` | Rebuild: `yarn build-storybook` |
| Story ID mismatch | Using `name` instead of export name | Story IDs use export names (kebab-case) |
| Flaky screenshots | Local rendering differences | Run with `--remote` for consistent environment |
| Too many test files | 1 file per story (default) | Set `batchSize: 10` |
| Threshold too strict | Pixel-perfect comparison | Increase `imageMatcherOptions.threshold` to 0.02 |

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `REMOTE_STORYBOOK_URL` | Pre-built Storybook URL in CI (skips local server) |
| `STORYBOOK_PORT` | Override default port |
