# BDD Driver Patterns for Sled 3

Templates and real production examples for the BDD architecture (driver/builder/spec).

## Directory Structure

```
__e2e__/
├── constants.ts                    # BASE_URL, test users, MSIDs
├── drivers/
│   ├── app.driver.ts               # Base driver: navigation + given.* + catch-all
│   ├── dashboard.driver.ts         # Page driver: get.*/when.*/is.*
│   └── settings.driver.ts          # Another page driver
├── builders/
│   └── item.builder.ts             # Mock data factory
├── fixtures/
│   └── index.ts                    # Custom fixtures (optional)
├── dashboard.spec.ts               # Spec file
└── settings.spec.ts                # Another spec
```

Or use `src/test/builders/` for builders shared between unit + E2E.

---

## Base Driver Template

The base driver manages interception setup, navigation, and API mocking.

```typescript
// drivers/app.driver.ts
import {
  InterceptHandlerActions,
  type InterceptHandler,
} from '@wix/sled-playwright';
import type { Page } from '@playwright/test';
import { BASE_URL, TEST_EMAIL, MSID } from '../constants';

export class AppDriver {
  private interceptors: InterceptHandler[] = [];

  reset() {
    this.interceptors = [];
  }

  async setup(interceptionPipeline: any) {
    // Add catch-all LAST (LIFO: runs first, blocks unmocked APIs)
    this.interceptors.push({
      id: 'catch-all-api-block',
      pattern: /\/(api|_api)\//,
      handler: () => ({ action: InterceptHandlerActions.ABORT }),
    });
    await interceptionPipeline.setup(this.interceptors);
  }

  async navigateToDashboard(page: Page, auth: any) {
    await auth.loginAsUser(TEST_EMAIL);
    await page.goto(`${BASE_URL}/${MSID}/home`);
  }

  given = {
    items: (items: any[]) => {
      this.interceptors.push({
        id: 'get-items',
        pattern: /\/api\/items/,
        handler: ({ method }) => {
          if (method === 'GET') {
            return {
              action: InterceptHandlerActions.INJECT_RESOURCE,
              resource: Buffer.from(JSON.stringify({ items })),
              responseCode: 200,
              responseHeaders: { 'Content-Type': 'application/json' },
            };
          }
          return { action: InterceptHandlerActions.CONTINUE };
        },
      });
      return this;
    },

    emptyState: () => {
      return this.given.items([]);
    },

    apiError: (endpoint: RegExp, statusCode = 500) => {
      this.interceptors.push({
        id: `error-${endpoint.source}`,
        pattern: endpoint,
        handler: () => ({
          action: InterceptHandlerActions.INJECT_RESOURCE,
          resource: Buffer.from(JSON.stringify({ error: 'Server Error' })),
          responseCode: statusCode,
          responseHeaders: { 'Content-Type': 'application/json' },
        }),
      });
      return this;
    },
  };
}
```

---

## Page Driver Template

Page drivers handle element queries and interactions. They are **stateless** — receive `page` per method call.

```typescript
// drivers/dashboard.driver.ts
import type { Page } from '@playwright/test';
import { expect } from '@wix/sled-playwright';

export class DashboardDriver {
  get = {
    heading: (page: Page) =>
      page.getByRole('heading', { name: /dashboard/i }),

    itemCount: async (page: Page) => {
      const badge = page.getByTestId('item-count');
      return parseInt(await badge.textContent() || '0', 10);
    },

    errorMessage: (page: Page) =>
      page.getByTestId('error-message'),
  };

  is = {
    loaded: async (page: Page) => {
      await expect(page.getByTestId('dashboard-content')).toBeVisible();
      return true;
    },

    emptyStateShown: (page: Page) =>
      page.getByTestId('empty-state').isVisible(),

    errorStateShown: (page: Page) =>
      page.getByTestId('error-state').isVisible(),
  };

  when = {
    clickCreateButton: async (page: Page) => {
      await page.getByRole('button', { name: 'Create' }).click();
      return this;
    },

    searchFor: async (page: Page, query: string) => {
      await page.getByPlaceholder('Search...').fill(query);
      await page.getByRole('button', { name: 'Search' }).click();
      return this;
    },

    deleteItem: async (page: Page, name: string) => {
      const row = page.getByRole('row', { name });
      await row.getByRole('button', { name: 'Delete' }).click();
      await page.getByRole('button', { name: 'Confirm' }).click();
      return this;
    },
  };
}
```

---

## Builder Template

Builders create mock data with sensible defaults and partial overrides.

```typescript
// builders/item.builder.ts
interface Item {
  id: string;
  title: string;
  status: 'active' | 'draft' | 'archived';
  createdDate: Date;
  owner: string;
}

export const anItem = (overrides: Partial<Item> = {}): Item => ({
  id: crypto.randomUUID(),
  title: 'Test Item',
  status: 'active',
  createdDate: new Date(),
  owner: 'test-user@wix.com',
  ...overrides,
});

export const anActiveItem = (overrides: Partial<Item> = {}) =>
  anItem({ status: 'active', ...overrides });

export const aDraftItem = (overrides: Partial<Item> = {}) =>
  anItem({ status: 'draft', ...overrides });
```

**Rules:**
- No global counters or state
- Stable defaults (tests shouldn't rely on random data)
- Place in `src/test/builders/` if shared with unit tests

---

## Spec File Template

Specs compose drivers and read like documentation.

```typescript
// dashboard.spec.ts
import { test, expect } from '@wix/sled-playwright';
import { AppDriver } from './drivers/app.driver';
import { DashboardDriver } from './drivers/dashboard.driver';
import { anItem } from './builders/item.builder';

test.describe('Dashboard', () => {
  const app = new AppDriver();
  const dashboard = new DashboardDriver();

  test.beforeEach(() => {
    app.reset();
  });

  test('shows items after login', async ({ page, auth, interceptionPipeline }) => {
    const items = [anItem({ title: 'My Item' }), anItem({ title: 'Another' })];
    app.given.items(items);
    await app.setup(interceptionPipeline);
    await app.navigateToDashboard(page, auth);

    await expect(dashboard.get.heading(page)).toBeVisible();
    expect(await dashboard.get.itemCount(page)).toBe(2);
  });

  test('shows empty state when no items', async ({ page, auth, interceptionPipeline }) => {
    app.given.emptyState();
    await app.setup(interceptionPipeline);
    await app.navigateToDashboard(page, auth);

    expect(await dashboard.is.emptyStateShown(page)).toBe(true);
  });

  test('deletes item and updates count', async ({ page, auth, interceptionPipeline }) => {
    const items = [anItem({ title: 'Delete Me' }), anItem({ title: 'Keep Me' })];
    app.given.items(items);
    await app.setup(interceptionPipeline);
    await app.navigateToDashboard(page, auth);

    await dashboard.when.deleteItem(page, 'Delete Me');
    expect(await dashboard.get.itemCount(page)).toBe(1);
  });

  test('shows error state on API failure', async ({ page, auth, interceptionPipeline }) => {
    app.given.apiError(/\/api\/items/, 500);
    await app.setup(interceptionPipeline);
    await app.navigateToDashboard(page, auth);

    expect(await dashboard.is.errorStateShown(page)).toBe(true);
  });
});
```

**Rules for specs:**
- ZERO direct `page.*` calls for queries — use `driver.get.*`, `driver.is.*`
- ZERO raw selectors — no `[data-hook=...]`, `.css-class`, `locator(...)`
- ZERO `waitForTimeout` — use `expect` auto-retry or `expect.poll`
- ZERO conditional logic (`if/else`) — tests must be deterministic
- Every test: interaction -> state change -> assertion on NEW state

---

## Constants Template

```typescript
// constants.ts
export const BASE_URL = 'https://manage.wix.com/dashboard';
export const TEST_EMAIL = 'my-team-test@wix.com';
export const MSID = {
  REGULAR: '20274665-2c84-4837-a799-18077d6e1d36',
  PREMIUM: 'b251be59-d9d8-447d-953e-ca1b3627deb8',
};
export const SPECS_OVERRIDES = [
  { key: 'specs.my.feature', val: 'true' },
];
```

---

## Custom Fixture Patterns

### Auto Fixture (localhost proxy — site-scannerV2)

```typescript
import { test as base } from '@wix/sled-playwright';

export const test = base.extend<{ localhostProxy: void }>({
  localhostProxy: [
    async ({ interceptionPipeline }, use) => {
      await interceptionPipeline.setup([{
        id: 'localhost-proxy',
        pattern: '***',
        handler({ url, method, postData, headers }) {
          if (url.includes('localhost:3000')) {
            return {
              action: InterceptHandlerActions.INJECT_RESOURCE,
              resource: async () => {
                const resp = await fetch(url, { method, headers, body: postData });
                return Buffer.from(await resp.arrayBuffer());
              },
            };
          }
          return { action: InterceptHandlerActions.CONTINUE };
        },
      }]);
      await use();
    },
    { auto: true, scope: 'test' },
  ],
});
```

### Worker-Scoped Test User (ricos)

```typescript
import { test as base, expect } from '@wix/sled-playwright';

type WorkerFixtures = { testUser: string };
type TestFixtures = { testkit: MyTestkit };

export const test = base.extend<TestFixtures, WorkerFixtures>({
  testUser: ['default-user@wix.com', { scope: 'worker', option: true }],
  testkit: async ({ page, auth, testUser }, use) => {
    await auth.loginAsUser(testUser);
    const testkit = await MyTestkit.create(page);
    await use(testkit);
    await testkit.teardown();
  },
});
export { expect };
```

### Factory Pattern (wix-payments)

```typescript
import { test as base, expect, type Fixtures } from '@wix/sled-playwright';

type SetupArgs = Pick<Fixtures, 'page' | 'auth' | 'interceptionPipeline' | 'site'>;

export const createTest = <T>(createSetup: (args: SetupArgs) => T) => {
  return base.extend<{ sledSetup: T }>({
    sledSetup: async ({ page, auth, interceptionPipeline, site }, use) => {
      await use(createSetup({ page, auth, interceptionPipeline, site }));
    },
  });
};
```

---

## BM App Pattern (injectBMOverrides)

For Business Manager apps using `@wix/yoshi-flow-bm`:

```typescript
// Sled 2 pattern (may still be needed for some BM apps)
import { injectBMOverrides } from '@wix/yoshi-flow-bm/sled';

test.beforeEach(async ({ page }) => {
  await injectBMOverrides({
    page,
    appConfig: require('../target/module-sled.merged.json'),
  });
});
```

In Sled 3, most BM apps work without `injectBMOverrides` thanks to artifact overrides. Test without it first; add only if needed.

---

## Tag Convention for Test Filtering

Use `@tag` in test names with `--grep` for selective execution:

```typescript
test('@smoke should load dashboard', async ({ page, auth }) => { ... });
test('@regression should handle edge case', async ({ page }) => { ... });

// Run only smoke tests:
// CI=false npx sled-playwright test --grep @smoke
// Exclude regression:
// CI=false npx sled-playwright test --grepInvert @regression
```

---

## Real Production Examples

### job-runner-ai — BDD Driver + Interception

```typescript
// Spec: chainable given.* -> setup -> when -> assert
test('highlights current job', async ({ page, interceptionPipeline }) => {
  const jobId = uuid();
  await driver.given
    .getCurrentQuota(0)
    .given.createJobWithMessage(jobId)
    .given.getJobs([{ id: uuid(), title: 'Existing Job', createdDate: new Date() }])
    .setup(interceptionPipeline);

  await driver.navigateToHomePage(page);
  await homePageDriver.when.typeInInputArea(page, 'Plan a party');
  await homePageDriver.when.clickSubmitButton(page);
  expect(await sidePanelDriver.is.jobHighlighted(page, jobId)).toBe(true);
});
```

### form-client — Inline Interception for Error State

```typescript
test('shows error when automations API fails', async ({
  page, auth, setExperiments, interceptionPipeline,
}) => {
  const { driver } = await openDashboard({ page, auth, setExperiments, msid });

  await interceptionPipeline.setup([{
    pattern: /v4\/form-app-automations/,
    handler: () => ({ action: InterceptHandlerActions.ABORT }),
  }]);

  await driver.openSettingsTab();
  expect(await driver.composerDriver().automationsErrorState().exists()).toBe(true);
});
```

### members-area — Editor Frame Driver

```typescript
import type { FrameLocator } from '@playwright/test';
import type { Page } from '@wix/sled-playwright';

export class EditorComponentsDriver {
  private previewFrame: FrameLocator;

  constructor(page: Page) {
    this.previewFrame = page.locator('iframe[name="preview-frame"]').contentFrame();
  }

  async getComponentByDataHook(dataHook: string) {
    return this.previewFrame.locator(`[data-hook="${dataHook}"]`);
  }
}
```
