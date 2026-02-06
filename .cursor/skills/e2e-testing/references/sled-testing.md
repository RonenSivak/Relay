# Sled E2E Testing

## Sled 3 (`@wix/sled-playwright`) — Current Recommended

Wix's internal E2E testing framework built on **Playwright**. Runs tests in a Kubernetes cluster with multiple browser types and versions. Replaces Sled 2 (Jest + Puppeteer + AWS Lambda).

**Source**: `wix-private/sled-playwright` repo. Official docs at `wix-docs/` in that repo.

---

## Sled 2 vs Sled 3

| Feature | Sled 2 (`@wix/sled-test-runner`) | Sled 3 (`@wix/sled-playwright`) |
|---------|----------------------------------|--------------------------------|
| Browser engine | Puppeteer (Chromium only) | Playwright (Chromium, Firefox, WebKit) |
| Test runner | Jest | Playwright Test |
| Execution | AWS Lambda | Kubernetes |
| Config | `sled/sled.json` | `playwright.config.ts` with `defineSledConfig()` |
| CLI | `npx sled-test-runner` | `sled-playwright test` |
| Auth | Manual | Built-in `auth` fixture |
| Visual testing | Custom implementation | Native Playwright screenshots |
| Storybook | Custom config (`storybook-sled-e2e.json`) | `@wix/playwright-storybook-plugin` |
| File naming | `*.sled.spec.ts` | `*.sled3.spec.ts` or `*.spec.ts` |
| Browser access | `global.__BROWSER__.newPage()` | `async ({ page }) =>` fixture |

---

## Sled 3: Setup

### CLI Init (Recommended)

```bash
npx @wix/sled-playwright init
```

This interactive CLI:
1. Adds `.gitignore` exclusions
2. Adds test scripts to `package.json`
3. Creates test directory with example test
4. Creates `playwright.config.ts`
5. Adds `postPublish` validation script
6. Installs matching `@playwright/test` version

### Manual Setup

```bash
yarn add -D @wix/sled-playwright
# IMPORTANT: Install @playwright/test with version matching Sled's server version
# See wix-docs/getting-started/versions.md for current supported version
```

---

## Sled 3: Configuration

```typescript
// playwright.config.ts
import {
  defineSledConfig,
  ArtifactsOverridePolicy,
} from '@wix/sled-playwright';

export default defineSledConfig({
  // === Wix-Specific Options ===
  artifactId: 'your-artifact-id',           // Default: from package.json
  artifactsOverridePolicy: ArtifactsOverridePolicy.DISABLE,
  pathToStatics: 'dist/statics',            // Path to static files for overrides

  // === Standard Playwright Config ===
  playwrightConfig: {
    testDir: 'e2e',
    timeout: 120 * 1000,
    use: {
      testIdAttribute: 'data-hook',         // Wix convention
      browserName: 'chromium',
      trace: 'retain-on-failure',
      video: 'retain-on-failure',
      actionTimeout: 30000,
      navigationTimeout: 90000,
    },
    projects: [
      { name: 'chrome', use: { browserName: 'chromium' } },
      // Add firefox/webkit if needed
    ],
  },
});
```

### Configuration Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `artifactId` | `string` | from `package.json` | Your artifact identifier |
| `artifactsOverridePolicy` | `enum` | `FAIL_ON_MISSING` | `DISABLE`, `FAIL_ON_MISSING`, `IGNORE_MISSING` |
| `pathToStatics` | `string` | `'dist/statics'` | Static files path |
| `artifactsUrlOverride` | `array` | - | Override specific artifact versions |
| `gotoConfig` | `object` | - | Default query params for navigation |
| `globalExperiments` | `array` | - | Experiments applied to all tests |
| `noAutomationFlagging` | `boolean` | `false` | Disable automation cookies |
| `disableBiEvents` | `boolean` | `true` | Block BI events during tests |
| `github.report.enabled` | `boolean` | `true` | PR comment with results |
| `github.liveTracker.enabled` | `boolean` | `false` | Real-time test progress dashboard |
| `plugins` | `array` | - | Sled plugins (e.g., storybook) |
| `playwrightConfig` | `object` | - | Standard Playwright config options |

### Artifact Version Overrides (In Tests)

```typescript
test.use({
  artifactsUrlOverride: [
    { groupId: 'com.wixpress', artifactId: 'my-app', version: '1.2.3' },
    { groupId: 'com.wixpress', artifactId: 'other', version: 'RC' },
  ],
});
```

---

## Sled 3: Writing Tests

```typescript
import { test, expect } from '@wix/sled-playwright';

test.describe('Dashboard', () => {
  test('should show welcome message after login', async ({ page, auth }) => {
    await auth.loginAsUser('test-user@wix.com');
    await page.goto('https://manage.wix.com/dashboard/msid/home');

    await expect(
      page.getByRole('heading', { name: 'Welcome back' })
    ).toBeVisible();
  });
});
```

### Built-in Fixtures

| Fixture | Purpose |
|---------|---------|
| `page` | Standard Playwright page |
| `auth` | Login as Wix user: `auth.loginAsUser(email)` |
| `file` | Deploy and manage files |
| `biSpy` | Track Business Intelligence events |
| `appTokens` | Manage app access tokens |
| `experiments` | Control experiments per test |
| `memoize` | Cache expensive operations across workers |

### Custom Fixtures

```typescript
import { test as base } from '@wix/sled-playwright';

export const test = base.extend({
  dashboardPage: async ({ page, auth }, use) => {
    await auth.loginAsUser('test-user@wix.com');
    await page.goto('https://manage.wix.com/dashboard/msid/home');
    await use(page);
  },
});
```

---

## Sled 3: CLI

```bash
# Run tests
sled-playwright test                            # All tests
sled-playwright test feature.spec.ts            # Specific file
sled-playwright test --remote                   # Remote execution (for visual tests)
sled-playwright test --project chromium          # Specific browser
sled-playwright test --live-tracker              # Real-time dashboard

# Flakiness detection
sled-playwright detect-flakiness                # Check changed tests (20 runs)
sled-playwright detect-flakiness --repeat-count 10  # Fewer runs
sled-playwright detect-flakiness --base-branch origin/develop

# Other
sled-playwright test --update-snapshots         # Update visual baselines
sled-playwright test --debug                    # Step-through debugging
sled-playwright test --repeat-each=5            # Repeat each test N times
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

**Why `postPublish`**: Sled 3 relies on published statics on parastorage. Tests run after publish to ensure statics are available.

---

## Sled 3: Best Practices

### Locators (from official docs)

```typescript
// BEST: Role-based (accessible, user-facing)
await page.getByRole('button', { name: 'Submit' }).click();

// GOOD: Text-based
await page.getByText('Welcome back').isVisible();

// GOOD: Label-based (forms)
await page.getByLabel('Username').fill('user');

// OK: data-hook (Wix convention, use when roles aren't suitable)
await page.getByTestId('submit-btn').click();  // with testIdAttribute: 'data-hook'

// AVOID: CSS selectors
await page.locator('.submit-button').click();

// AVOID: XPath
await page.locator('//button[text()="Submit"]').click();
```

### Visual Testing

- **Always run remote**: `sled-playwright test --remote` for consistent results
- Keep visual tests focused — one component per test
- Wait for animations before snapshots
- Update snapshots intentionally: `--update-snapshots`

### Waiting Strategies

```typescript
// ❌ Bad: Fixed timeouts — flaky!
await page.waitForTimeout(3000);

// ❌ Bad: Old-style selector waiting
await page.waitForSelector('[data-hook="element"]');

// ✅ Good: Auto-waiting assertions (auto-retry)
await expect(page.getByText('Welcome')).toBeVisible();
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled();

// ✅ Good: Wait for URL
await page.waitForURL('/dashboard');

// ✅ Good: Wait for specific API response
const responsePromise = page.waitForResponse(
  (response) => response.url().includes('/api/items') && response.status() === 200,
);
await page.getByRole('button', { name: 'Load' }).click();
const response = await responsePromise;

// ✅ Good: Poll for async state (with BDD drivers)
await expect.poll(async () => itemsPage.is.emptyStateShown(page)).toBe(true);
```

### Network Mocking (Standalone Playwright)

For tests **not** using Sled 3 interception pipeline, use `page.route()`:

```typescript
// Mock API responses
test('shows error when API fails', async ({ page }) => {
  await page.route('**/api/items', (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal Server Error' }),
    });
  });

  await page.goto('/items');
  await expect(page.getByText('Failed to load items')).toBeVisible();
});

// Intercept and modify requests
test('modifies request data', async ({ page }) => {
  await page.route('**/api/items', async (route) => {
    const request = route.request();
    const postData = JSON.parse(request.postData() || '{}');
    postData.role = 'admin';
    await route.continue({ postData: JSON.stringify(postData) });
  });
});
```

**For Sled 3**: Use `interceptionPipeline` fixture + BDD base driver `given.*` (see `e2e-driver-pattern.md`).

### Debugging

```bash
# Run with visible browser
sled-playwright test --headed

# Step-through debugging (opens Playwright Inspector)
sled-playwright test --debug
```

```typescript
// In-test debugging
await page.pause();  // Opens Playwright Inspector

// Structure tests with steps for better trace reports
await test.step('Navigate to dashboard', async () => {
  await page.goto('/dashboard');
});

await test.step('Create new item', async () => {
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByText('Created')).toBeVisible();
});

// Take debug screenshots
await page.screenshot({ path: 'debug.png', fullPage: true });

// Listen to console for debugging
page.on('console', (msg) => console.log(msg.text()));
```

**Trace viewer**: `npx playwright show-trace trace.zip`

### Flaky Test Prevention

1. Run `detect-flakiness` before creating PRs
2. Use Playwright's auto-waiting (locators wait automatically)
3. Avoid `page.waitForTimeout()` — use explicit conditions
4. Ensure test isolation (no shared state)
5. Investigate and fix — don't just retry

---

## Sled 2: Legacy Reference

**Only reference this if the project uses `@wix/sled-test-runner` v1.x/v2.x.**

### Config (`sled/sled.json`)

```json
{
  "artifacts_upload": {
    "artifacts_dir": "dist/statics",
    "patterns": ["**/*.json", "**/*.min.js"]
  },
  "test_path_patterns": ["tests/**/*.spec"],
  "sled_folder_relative_path_in_repo": "sled"
}
```

### Test Structure

```typescript
// feature.sled.spec.ts
describe('Feature', () => {
  let page;
  beforeEach(async () => { page = await global.__BROWSER__.newPage(); });
  afterEach(async () => { await page.close(); });

  it('should work', async () => {
    await page.goto('https://your-app.wix.com/feature');
    await page.waitForSelector('[data-hook="loaded"]');
    await page.click('[data-hook="action-btn"]');
    const text = await page.$eval('[data-hook="result"]', el => el.textContent);
    expect(text).toContain('Success');
  });
});
```

### Running

```bash
npx sled-test-runner              # Remote (cloud)
npx sled-test-runner local        # Local
npx sled-test-runner remote       # Explicit remote
```

---

## Migration: Sled 2 → Sled 3

| Sled 2 (`sled.json`) | Sled 3 (`playwright.config.ts`) |
|----------------------|--------------------------------|
| `artifact_id` | `artifactId` |
| `artifacts_upload.artifacts_dir` | `pathToStatics` |
| `base_urls_to_intercept_artifacts` | `baseUrlsToInterceptArtifacts` |
| `sled_folder_relative_path_in_repo` | `playwrightConfig.testDir` |

### Key Code Changes

```typescript
// Sled 2: Jest + Puppeteer
const page = await global.__BROWSER__.newPage();
await page.goto(url);
await page.waitForSelector('[data-hook="el"]');
await page.click('[data-hook="btn"]');
const text = await page.$eval('[data-hook="el"]', el => el.textContent);
expect(text).toBe('expected');

// Sled 3: Playwright
// import { test, expect } from '@wix/sled-playwright';
test('my test', async ({ page }) => {
  await page.goto(url);
  await page.getByTestId('btn').click();  // auto-waits
  await expect(page.getByTestId('el')).toHaveText('expected');
});
```
