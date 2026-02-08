# Standalone Playwright E2E Testing

Use when **Sled is not available** (non-Wix-internal projects). For Wix projects, use `@wix/sled-playwright` instead (see `sled-testing.md`).

---

## Setup

```bash
npm init playwright@latest
# Or add to existing project:
npm install --save-dev @playwright/test
npx playwright install
```

---

## Configuration

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.e2e.ts',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  timeout: 30000,

  use: {
    baseURL: 'http://localhost:3000',
    testIdAttribute: 'data-hook',        // Wix convention if applicable
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature', () => {
  test('should complete user flow', async ({ page }) => {
    await page.goto('/feature');

    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText('Created successfully')).toBeVisible();
  });
});
```

---

## Page Object Pattern

```typescript
// feature.page.ts
import { Page, Locator, expect } from '@playwright/test';

export class FeaturePage {
  readonly createButton: Locator;
  readonly successMessage: Locator;

  constructor(private page: Page) {
    this.createButton = page.getByRole('button', { name: 'Create' });
    this.successMessage = page.getByText('Created successfully');
  }

  async navigate() {
    await this.page.goto('/feature');
  }

  async create() {
    await this.createButton.click();
  }

  async expectSuccess() {
    await expect(this.successMessage).toBeVisible();
  }
}
```

```typescript
// feature.e2e.ts
import { test } from '@playwright/test';
import { FeaturePage } from './feature.page';

test('should create successfully', async ({ page }) => {
  const feature = new FeaturePage(page);
  await feature.navigate();
  await feature.create();
  await feature.expectSuccess();
});
```

---

## CLI

```bash
npx playwright test                     # All tests
npx playwright test feature.e2e.ts      # Specific file
npx playwright test --headed            # Visible browser
npx playwright test --debug             # Step-through debugging
npx playwright test --ui                # Interactive test runner
npx playwright test -g "should create"  # By title
npx playwright show-report              # HTML report
```

---

## Key APIs

```typescript
// Locators (auto-wait + auto-retry)
page.getByRole('button', { name: 'Submit' })
page.getByText('Welcome')
page.getByLabel('Email')
page.getByTestId('submit-btn')       // with testIdAttribute config

// Assertions (auto-retry)
await expect(locator).toBeVisible();
await expect(locator).toHaveText('expected');
await expect(locator).toBeEnabled();
await expect(page).toHaveURL('/path');

// Navigation
await page.goto('/path');
await page.waitForURL('/expected');

// Screenshots
await page.screenshot({ path: 'debug.png', fullPage: true });
```

---

## Waiting Strategies

```typescript
// ❌ Bad: Fixed timeouts
await page.waitForTimeout(3000); // Flaky!

// ✅ Good: Auto-waiting assertions
await expect(page.getByText('Welcome')).toBeVisible();
await expect(page.getByRole('button', { name: 'Submit' })).toBeEnabled();

// ✅ Good: Wait for URL change
await page.waitForURL('/dashboard');

// ✅ Good: Wait for API response
const responsePromise = page.waitForResponse(
  (response) => response.url().includes('/api/users') && response.status() === 200,
);
await page.getByRole('button', { name: 'Load Users' }).click();
const response = await responsePromise;
const data = await response.json();

// ✅ Good: Wait for multiple conditions
await Promise.all([
  page.waitForURL('/success'),
  expect(page.getByText('Payment successful')).toBeVisible(),
]);
```

---

## Network Mocking

```typescript
// Mock API responses
test('shows error when API fails', async ({ page }) => {
  await page.route('**/api/users', (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal Server Error' }),
    });
  });

  await page.goto('/users');
  await expect(page.getByText('Failed to load users')).toBeVisible();
});

// Intercept and modify requests
test('modifies request payload', async ({ page }) => {
  await page.route('**/api/users', async (route) => {
    const postData = JSON.parse(route.request().postData() || '{}');
    postData.role = 'admin';
    await route.continue({ postData: JSON.stringify(postData) });
  });
});

// Mock third-party services
test('payment flow with mocked Stripe', async ({ page }) => {
  await page.route('**/api/stripe/**', (route) => {
    route.fulfill({
      status: 200,
      body: JSON.stringify({ id: 'mock_payment_id', status: 'succeeded' }),
    });
  });
});
```

---

## Custom Fixtures

```typescript
// fixtures/test-data.ts
import { test as base } from '@playwright/test';

type TestFixtures = {
  authenticatedPage: Page;
  testUser: { email: string; password: string };
};

export const test = base.extend<TestFixtures>({
  testUser: async ({}, use) => {
    const user = {
      email: `test-${Date.now()}@example.com`,
      password: 'Test123!@#',
    };
    await createTestUser(user);  // Setup
    await use(user);
    await deleteTestUser(user.email);  // Teardown
  },

  authenticatedPage: async ({ page, testUser }, use) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(testUser.email);
    await page.getByLabel('Password').fill(testUser.password);
    await page.getByRole('button', { name: 'Login' }).click();
    await page.waitForURL('/dashboard');
    await use(page);
  },
});

// Usage in specs
import { test } from './fixtures/test-data';

test('user can update profile', async ({ authenticatedPage }) => {
  await authenticatedPage.goto('/profile');
  await authenticatedPage.getByLabel('Name').fill('Updated Name');
  await authenticatedPage.getByRole('button', { name: 'Save' }).click();
  await expect(authenticatedPage.getByText('Profile updated')).toBeVisible();
});
```

---

## Visual Regression

```typescript
test('homepage visual regression', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixels: 100,
  });
});

test('button states', async ({ page }) => {
  await page.goto('/components');
  const button = page.getByRole('button', { name: 'Submit' });

  await expect(button).toHaveScreenshot('button-default.png');

  await button.hover();
  await expect(button).toHaveScreenshot('button-hover.png');
});
```

Update snapshots: `npx playwright test --update-snapshots`

---

## Accessibility Testing

```typescript
// Install: npm install @axe-core/playwright
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('page has no accessibility violations', async ({ page }) => {
  await page.goto('/');

  const results = await new AxeBuilder({ page })
    .exclude('#third-party-widget')  // Skip known 3rd-party issues
    .analyze();

  expect(results.violations).toEqual([]);
});

test('form is accessible', async ({ page }) => {
  await page.goto('/signup');
  const results = await new AxeBuilder({ page }).include('form').analyze();
  expect(results.violations).toEqual([]);
});
```

---

## Debugging

```bash
npx playwright test --headed          # Visible browser
npx playwright test --debug           # Step-through debugging
npx playwright test --ui              # Interactive test runner
npx playwright show-report            # HTML report
npx playwright show-trace trace.zip   # Trace viewer
```

```typescript
// In-test debugging
await page.pause();  // Opens Playwright Inspector

// Structured test steps (better trace/report)
test('checkout flow', async ({ page }) => {
  await test.step('Add item to cart', async () => {
    await page.goto('/products');
    await page.getByRole('button', { name: 'Add to Cart' }).click();
  });

  await test.step('Complete checkout', async () => {
    await page.goto('/cart');
    await page.getByRole('button', { name: 'Checkout' }).click();
  });
});

// Console logging
page.on('console', (msg) => console.log(msg.text()));

// Screenshot for debugging
await page.screenshot({ path: 'debug.png', fullPage: true });
```

---

## Tips

- **Auto-waiting**: Locators wait automatically. Avoid manual `waitForSelector`.
- **Web-first assertions**: `expect(locator)` auto-retries. Prefer over manual checks.
- **Test isolation**: Each test gets a fresh browser context by default.
- **Parallel**: Files run in parallel, tests within a file run sequentially.
- **Fixtures**: Use Playwright fixtures for shared setup (auth, custom pages).
- **BDD architecture**: For new projects, use BDD drivers — see `e2e-driver-pattern.md`.
