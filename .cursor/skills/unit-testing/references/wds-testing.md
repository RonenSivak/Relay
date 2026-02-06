# WDS & @wix/patterns Testing

Testing components built with `@wix/design-system` and `@wix/patterns`.

---

## Setup: Configure data-hook

WDS components use `data-hook` (not `data-testid`). Configure RTL:

```typescript
// In setupTests.ts or at top of test file
import { configure } from '@testing-library/react';
configure({ testIdAttribute: 'data-hook' });
```

After this, `screen.getByTestId('my-hook')` queries `[data-hook="my-hook"]`.

---

## WDS Testkits

**IMPORTANT: Always check the existing codebase first.** Look for existing WDS test files, driver patterns, and testkit import paths before writing new ones. Match the project's conventions.

Every WDS component ships a testkit for each environment:

| Environment | Import Path | Notes |
|-------------|-------------|-------|
| testing-library (preferred) | `@wix/design-system/dist/testkit/testing-library` | Modern, async-safe |
| jsdom (legacy) | `@wix/design-system/dist/testkit` | Legacy sync drivers, being deprecated |
| Puppeteer | `@wix/design-system/dist/testkit/puppeteer` | Sled / browser tests |
| Playwright | `@wix/design-system/dist/testkit/playwright` | Playwright tests |
| UniDriver | `@wix/design-system/dist/testkit/unidriver` | Universal driver (Wix one-stack) |

> **Migration note (Jan 2026):** The legacy `@wix/design-system/dist/testkit` path uses synchronous drivers that don't handle async well (Floating-UI, Tooltip issues). Prefer `testing-library` path for new tests. If existing tests use the legacy path - follow the project convention but be aware of potential async issues.

### Import Pattern

```typescript
// Preferred: testing-library (async-safe)
import {
  ButtonTestkit,
  InputTestkit,
  ModalTestkit,
  BadgeTestkit,
  LoaderTestkit,
  TextTestkit,
  BoxTestkit,
  PageHeaderTestkit,
  CustomModalLayoutTestkit,
} from '@wix/design-system/dist/testkit/testing-library';

// Legacy jsdom (still widely used in existing codebases)
import {
  ButtonTestkit,
  SidebarNextTestkit,
  WixDesignSystemProviderTestkit,
} from '@wix/design-system/dist/testkit';

// Puppeteer
import {
  ButtonTestkit,
  NotificationTestkit,
} from '@wix/design-system/dist/testkit/puppeteer';
```

### Creating a Testkit Instance

All testkits take `{ wrapper, dataHook }`:

```typescript
const button = ButtonTestkit({
  wrapper: baseElement,       // container element (from render result)
  dataHook: 'submit-button',  // data-hook attribute on the component
});
```

### Common Testkit APIs

```typescript
// Existence
await button.exists();        // boolean

// Text
await badge.text();           // string
await text.getText();         // string

// Interactions
await button.click();
await input.enterText('hello');
await input.clearText();
await dropdown.selectOptionAt(2);

// State
await button.isDisabled();    // boolean
await loader.exists();        // check loading state
await badge.getSkin();        // 'standard' | 'danger' | ...

// Modal
await modal.isOpen();
await customModalLayout.exists();
await customModalLayout.clickPrimaryButton();
await customModalLayout.clickSecondaryButton();
```

---

## @wix/patterns Testkits

`@wix/patterns` provides higher-level components (Table, etc.) with their own testkits.

### Import

```typescript
import { TableTestkit } from '@wix/patterns/testkit/jsdom';
```

### Table API

```typescript
const table = TableTestkit({
  wrapper: baseElement,
  dataHook: 'my-table',
});

// Queries
await table.exists();
await table.getRowsCount();
await table.getRowByIndex(0);

// Interactions
await table.clickRow(0);

// Row details (expandable rows)
const rowDetails = await table.getRowDetails(0);
await table.getRowDetailsText(0);

// Row data
const row = table.getRowByIndex(0);
await row.text();
```

---

## Driver Pattern with WDS Testkits

Wrap testkits in the driver's `given/when/get` pattern.

### Full Example

```typescript
import { render, RenderResult, waitFor } from '@testing-library/react';
import {
  ButtonTestkit,
  InputTestkit,
  LoaderTestkit,
  CustomModalLayoutTestkit,
} from '@wix/design-system/dist/testkit';
import { TableTestkit } from '@wix/patterns/testkit/jsdom';
import { MyComponent, Props } from './MyComponent';
import { dataHooks } from './dataHooks';

export class MyComponentDriver {
  private renderResult: RenderResult;

  constructor() {
    this.renderResult = render(<div />); // placeholder
  }

  // ============================================
  // GIVEN
  // ============================================
  given = {
    rendered: (props: Partial<Props> = {}) => {
      const defaultProps: Props = { /* defaults */ };
      this.renderResult = render(
        <MyComponent {...defaultProps} {...props} />
      );
      return this;
    },
  };

  // ============================================
  // WHEN
  // ============================================
  when = {
    clickSubmit: async () => {
      const btn = this.get.submitButton();
      await btn.click();
      return this;
    },

    enterSearchText: async (text: string) => {
      const input = this.get.searchInput();
      await input.enterText(text);
      return this;
    },

    clickTableRow: async (index: number) => {
      const table = this.get.table();
      await table.clickRow(index);
      return this;
    },

    confirmModal: async () => {
      const modal = this.get.confirmationModal();
      await modal.clickPrimaryButton();
      return this;
    },

    waitForLoaded: async () => {
      await waitFor(async () => {
        expect(await this.get.loader().exists()).toBe(false);
      });
      return this;
    },
  };

  // ============================================
  // GET
  // ============================================
  get = {
    submitButton: () => ButtonTestkit({
      wrapper: this.renderResult.baseElement,
      dataHook: dataHooks.submitButton,
    }),

    searchInput: () => InputTestkit({
      wrapper: this.renderResult.baseElement,
      dataHook: dataHooks.searchInput,
    }),

    table: () => TableTestkit({
      wrapper: this.renderResult.baseElement,
      dataHook: dataHooks.table,
    }),

    loader: () => LoaderTestkit({
      wrapper: this.renderResult.baseElement,
      dataHook: dataHooks.loader,
    }),

    confirmationModal: () => CustomModalLayoutTestkit({
      wrapper: this.renderResult.baseElement,
      dataHook: dataHooks.confirmModal,
    }),

    rowCount: async () => {
      const table = this.get.table();
      return table.getRowsCount();
    },

    pageTitle: async () => {
      const header = PageHeaderTestkit({
        wrapper: this.renderResult.baseElement,
        dataHook: dataHooks.pageHeader,
      });
      return header.titleText();
    },
  };

  // ============================================
  // Cleanup
  // ============================================
  cleanup() {
    this.renderResult.unmount();
  }
}
```

### Spec Example

```typescript
describe('MyComponent', () => {
  let driver: MyComponentDriver;

  beforeEach(() => {
    driver = new MyComponentDriver();
  });

  afterEach(() => {
    driver.cleanup();
  });

  it('should render table with data', async () => {
    driver.given.rendered({ items: mockItems });
    await driver.when.waitForLoaded();

    expect(await driver.get.rowCount()).toBe(3);
  });

  it('should open confirmation modal on row click', async () => {
    driver.given.rendered({ items: mockItems });
    await driver.when.waitForLoaded();
    await driver.when.clickTableRow(0);

    const modal = driver.get.confirmationModal();
    expect(await modal.exists()).toBe(true);
  });

  it('should filter table on search', async () => {
    driver.given.rendered({ items: mockItems });
    await driver.when.waitForLoaded();
    await driver.when.enterSearchText('test');

    expect(await driver.get.rowCount()).toBe(1);
  });
});
```

---

## Builder Pattern for WDS Props

Create builders for component props that include WDS-specific values:

```typescript
import { Props } from './MyComponent';

export const aMyComponentProps = (overrides?: Partial<Props>): Props => ({
  dataHook: 'my-component',
  items: [],
  onSubmit: jest.fn(),
  isLoading: false,
  ...overrides,
});

// Usage
driver.given.rendered(aMyComponentProps({ isLoading: true }));
```

---

## data-hook Conventions

Define hooks in a constants file for consistency:

```typescript
// dataHooks.ts
export const dataHooks = {
  submitButton: 'submit-button',
  searchInput: 'search-input',
  table: 'items-table',
  loader: 'page-loader',
  confirmModal: 'confirm-modal',
  pageHeader: 'page-header',
} as const;
```

Use in both component and driver:

```tsx
// Component
<Button dataHook={dataHooks.submitButton}>Submit</Button>

// Driver
ButtonTestkit({ wrapper, dataHook: dataHooks.submitButton })
```

---

## Querying Without Testkits

For simple cases or WDS components without testkits:

```typescript
// Using data-hook with RTL (after configure)
screen.getByTestId('my-hook');

// Manual data-hook query
baseElement.querySelector('[data-hook="my-hook"]');

// Multiple elements
baseElement.querySelectorAll('[data-hook="list-item"]');
```

---

## Common WDS Component → Testkit Map

| Component | Testkit | Key Methods |
|-----------|---------|-------------|
| `Button` | `ButtonTestkit` | `click()`, `isDisabled()`, `getText()` |
| `Input` | `InputTestkit` | `enterText()`, `clearText()`, `getValue()` |
| `Badge` | `BadgeTestkit` | `text()`, `getSkin()`, `exists()` |
| `Loader` | `LoaderTestkit` | `exists()` |
| `Modal` | `ModalTestkit` | `isOpen()`, `close()` |
| `CustomModalLayout` | `CustomModalLayoutTestkit` | `clickPrimaryButton()`, `clickSecondaryButton()` |
| `PageHeader` | `PageHeaderTestkit` | `titleText()`, `isActionBarExists()` |
| `Table` (patterns) | `TableTestkit` (from `@wix/patterns`) | `getRowsCount()`, `clickRow()`, `getRowByIndex()` |
| `Text` | `TextTestkit` | `getText()`, `exists()` |
| `Box` | `BoxTestkit` | `exists()` |
| `ToggleSwitch` | `ToggleSwitchTestkit` | `click()`, `isChecked()` |
| `Dropdown` | `DropdownTestkit` | `selectOptionAt()`, `getSelectedText()` |
