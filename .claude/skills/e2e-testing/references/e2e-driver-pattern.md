# E2E Driver Pattern (BDD)

BDD architecture adapted for browser E2E tests. Same `given/when/get` philosophy as unit test drivers, but designed for Playwright's async, page-based model.

**Based on**: Real Wix production pattern (`wix-private/job-runner-ai`).

---

## Architecture

```
__e2e__/
├── constants.ts              # Test constants (BASE_URL, testUser)
├── feature.spec.ts           # BDD specs (compose drivers)
├── feature.builder.ts        # Mock data factories (optional)
└── drivers/
    ├── app.driver.ts         # Base driver: navigation + given.* (API setup)
    ├── home-page.driver.ts   # Page driver: get.* / is.* / when.*
    └── sidebar.driver.ts     # Component driver: get.* / is.* / when.*
```

### Key Differences from Unit Test BDD

| Aspect | Unit Test Driver | E2E Driver |
|--------|-----------------|------------|
| Page access | N/A (render in driver) | `page: Page` passed as parameter |
| `given.*` | On every driver (mocks, props) | On base driver only (API interception) |
| `when.*` | Sync (fireEvent) | **Async** (browser actions) |
| `get.*` | Returns values/elements | Returns **Playwright Locators** |
| `is.*` | Part of `get` | **Separate namespace** (async boolean queries) |
| Chaining | `given`/`when` return `this` | Same — `given` returns `this` |

---

## Base Driver (API Setup + Navigation)

The base driver handles API interception and navigation. `given.*` methods chain via `return this`.

```typescript
// drivers/app.driver.ts
import { InterceptHandler, InterceptHandlerActions } from '@wix/sled-playwright';
import { Page } from '@playwright/test';

const BASE_URL = 'https://manage.wix.com/dashboard/msid/my-app';

export class AppDriver {
  private interceptors: InterceptHandler[] = [];

  reset() {
    this.interceptors = [];
  }

  async setup(interceptionPipeline: any) {
    interceptionPipeline.setup(this.interceptors);
  }

  // === Navigation ===

  async navigateToHome(page: Page) {
    await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  }

  async navigateToItem(page: Page, itemId: string) {
    await page.goto(`${BASE_URL}/items/${itemId}`, { waitUntil: 'networkidle' });
  }

  // === GIVEN — API mocking (chainable) ===

  given = {
    itemsLoaded: (items: Item[]) => {
      this.interceptors.push({
        pattern: `${BASE_URL}/api/items`,
        handler: () => ({
          action: InterceptHandlerActions.INJECT_RESOURCE,
          resource: Buffer.from(JSON.stringify({ items })),
          responseCode: 200,
          responseHeaders: { 'Content-Type': 'application/json' },
        }),
      });
      return this;
    },

    apiReturnsError: (endpoint: string, statusCode = 500) => {
      this.interceptors.push({
        pattern: `${BASE_URL}/api/${endpoint}`,
        handler: () => ({
          action: InterceptHandlerActions.INJECT_RESOURCE,
          resource: Buffer.from(JSON.stringify({ error: 'Server Error' })),
          responseCode: statusCode,
          responseHeaders: { 'Content-Type': 'application/json' },
        }),
      });
      return this;
    },

    quotaIs: (currentCount: number) => {
      this.interceptors.push({
        pattern: `${BASE_URL}/api/quota`,
        handler: () => ({
          action: InterceptHandlerActions.INJECT_RESOURCE,
          resource: Buffer.from(JSON.stringify(currentCount)),
          responseCode: 200,
          responseHeaders: { 'Content-Type': 'application/json' },
        }),
      });
      return this;
    },
  };
}
```

---

## Page Driver (UI Interactions)

Page-level drivers use `get.*`, `is.*`, and `when.*`. Every method receives `page: Page` — it's never stored.

```typescript
// drivers/items-page.driver.ts
import { Page, Locator } from '@playwright/test';

export class ItemsPageDriver {
  // === GET — Returns Playwright Locators ===

  get = {
    createButton: (page: Page): Locator =>
      page.getByRole('button', { name: 'Create' }),

    itemRow: (page: Page, itemId: string): Locator =>
      page.getByTestId(`item-row-${itemId}`),

    searchInput: (page: Page): Locator =>
      page.getByLabel('Search items'),

    emptyState: (page: Page): Locator =>
      page.getByTestId('empty-state'),

    errorBanner: (page: Page): Locator =>
      page.getByRole('alert'),

    itemCount: (page: Page): Locator =>
      page.getByTestId('item-count'),
  };

  // === IS — Async boolean state queries ===

  is = {
    createButtonVisible: async (page: Page): Promise<boolean> =>
      this.get.createButton(page).isVisible(),

    emptyStateShown: async (page: Page): Promise<boolean> =>
      this.get.emptyState(page).isVisible(),

    itemHighlighted: async (page: Page, itemId: string): Promise<boolean> => {
      const row = this.get.itemRow(page, itemId);
      return (await row.getAttribute('data-active')) === 'true';
    },

    searchInputFocused: async (page: Page): Promise<boolean> => {
      const input = this.get.searchInput(page);
      return input.evaluate((el) => el === document.activeElement);
    },
  };

  // === WHEN — Async browser actions ===

  when = {
    clickCreate: async (page: Page) => {
      await this.get.createButton(page).click();
    },

    searchFor: async (page: Page, text: string) => {
      await this.get.searchInput(page).fill(text);
    },

    clickItem: async (page: Page, itemId: string) => {
      await this.get.itemRow(page, itemId).click();
    },

    clearSearch: async (page: Page) => {
      await this.get.searchInput(page).clear();
    },
  };
}
```

---

## Spec (Composing Drivers)

Specs compose multiple drivers. Use `expect.poll()` for async state assertions.

```typescript
// items.spec.ts
import { test, expect } from '@wix/sled-playwright';
import { AppDriver } from './drivers/app.driver';
import { ItemsPageDriver } from './drivers/items-page.driver';
import { anItem } from './items.builder';

test.describe('Items Page', () => {
  const appDriver = new AppDriver();
  const itemsPage = new ItemsPageDriver();

  test.beforeEach(async ({ auth }) => {
    await auth.loginAsUser('test-user@wix.com');
    appDriver.reset();
  });

  test('should display items list', async ({ page, interceptionPipeline }) => {
    const items = [anItem({ id: 'item-1', title: 'First' }), anItem({ id: 'item-2', title: 'Second' })];

    await appDriver.given
      .itemsLoaded(items)
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);

    await expect(itemsPage.get.itemRow(page, 'item-1')).toBeVisible();
    await expect(itemsPage.get.itemRow(page, 'item-2')).toBeVisible();
  });

  test('should show empty state when no items', async ({ page, interceptionPipeline }) => {
    await appDriver.given
      .itemsLoaded([])
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);

    await expect
      .poll(async () => itemsPage.is.emptyStateShown(page))
      .toBe(true);
  });

  test('should show error when API fails', async ({ page, interceptionPipeline }) => {
    await appDriver.given
      .apiReturnsError('items')
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);

    await expect(itemsPage.get.errorBanner(page)).toBeVisible();
  });

  test('should highlight item after clicking', async ({ page, interceptionPipeline }) => {
    await appDriver.given
      .itemsLoaded([anItem({ id: 'item-1' })])
      .setup(interceptionPipeline);

    await appDriver.navigateToHome(page);
    await itemsPage.when.clickItem(page, 'item-1');

    expect(await itemsPage.is.itemHighlighted(page, 'item-1')).toBe(true);
  });
});
```

---

## Builder (Mock Data Factories)

Same pattern as unit test builders — `a`/`an` prefix, sensible defaults, partial overrides.

```typescript
// items.builder.ts
interface Item {
  id: string;
  title: string;
  status: 'active' | 'draft';
  createdDate: Date;
}

export const anItem = (overrides?: Partial<Item>): Item => ({
  id: 'item-123',
  title: 'Test Item',
  status: 'active',
  createdDate: new Date(),
  ...overrides,
});

export const manyItems = (count: number, overrides?: Partial<Item>): Item[] =>
  Array.from({ length: count }, (_, i) =>
    anItem({ id: `item-${i + 1}`, title: `Item ${i + 1}`, ...overrides })
  );
```

---

## Standalone Playwright Variant

For non-Sled projects, use `page.route()` instead of interception pipeline:

```typescript
// drivers/app.driver.ts (standalone Playwright)
import { Page } from '@playwright/test';

export class AppDriver {
  // === GIVEN — API mocking via page.route() (chainable) ===

  given = {
    itemsLoaded: (items: Item[]) => {
      this._mocks.push(async (page: Page) => {
        await page.route('**/api/items', (route) => {
          route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ items }),
          });
        });
      });
      return this;
    },

    apiReturnsError: (endpoint: string, statusCode = 500) => {
      this._mocks.push(async (page: Page) => {
        await page.route(`**/api/${endpoint}`, (route) => {
          route.fulfill({
            status: statusCode,
            contentType: 'application/json',
            body: JSON.stringify({ error: 'Server Error' }),
          });
        });
      });
      return this;
    },
  };

  private _mocks: Array<(page: Page) => Promise<void>> = [];

  async setup(page: Page) {
    for (const mock of this._mocks) {
      await mock(page);
    }
  }

  reset() {
    this._mocks = [];
  }
}
```

Usage in spec:
```typescript
test('should show empty state', async ({ page }) => {
  appDriver.given.itemsLoaded([]);
  await appDriver.setup(page);

  await page.goto('/items');
  await expect(page.getByTestId('empty-state')).toBeVisible();
});
```

---

## Pattern Decision

```
Writing E2E tests?
│
├─ Tests exist → Follow their pattern (POM, flat, etc.)
│
└─ No tests exist → Use BDD architecture
   │
   ├─ Sled 3 → InterceptHandler + given.* on base driver
   │
   └─ Standalone Playwright → page.route() + given.* on base driver
```

## Composition Tips

- **One base driver** per test suite (handles API + navigation)
- **One page driver** per distinct page/panel
- **Spec composes** base + page drivers
- **Builders** stay separate — reuse across specs
- Drivers are **stateless** (page is passed in) — page drivers don't store `page`
- Base driver is **stateful** (accumulates interceptors) — call `reset()` in `beforeEach`
