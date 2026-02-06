# WDS E2E Testkits

Testing `@wix/design-system` components in browser E2E tests. Sled 2 uses Puppeteer testkits, Sled 3 uses Playwright testkits.

---

## When to Use

Use WDS browser testkits when:
- Your E2E tests interact with WDS components
- You need reliable selectors for complex WDS widgets (Dropdown, Modal, Table)
- Direct `data-hook` queries aren't sufficient for component internals

**Check the project first.** If existing E2E tests use direct selectors (`data-hook`, CSS) to interact with WDS components, follow that convention. Only introduce testkits if the project already uses them or if direct selectors are insufficient.

---

## Import Paths

| Framework | Import Path | Used By |
|-----------|-------------|---------|
| Puppeteer | `@wix/design-system/dist/testkit/puppeteer` | Sled 2 |
| Playwright | `@wix/design-system/dist/testkit/playwright` | Sled 3 |

---

## Puppeteer Testkits (Sled 2)

### Creating Instances

```typescript
import { ButtonTestkit, InputTestkit, DropdownTestkit } from '@wix/design-system/dist/testkit/puppeteer';

// All testkits take { dataHook, page }
const button = await ButtonTestkit({ dataHook: 'submit-btn', page });
const input = await InputTestkit({ dataHook: 'search-input', page });
const dropdown = await DropdownTestkit({ dataHook: 'category-select', page });
```

### Common APIs

```typescript
// Button
await button.click();
await button.isDisabled();     // boolean
await button.getText();        // string
await button.exists();         // boolean

// Input
await input.enterText('hello');
await input.clearText();
await input.getValue();        // string
await input.isFocused();       // boolean

// Dropdown
await dropdown.click();
await dropdown.selectOptionAt(2);
await dropdown.getSelectedText(); // string

// Modal
const modal = await ModalTestkit({ dataHook: 'confirm-dialog', page });
await modal.isOpen();          // boolean
await modal.close();

// Loader
const loader = await LoaderTestkit({ dataHook: 'page-loader', page });
await loader.exists();         // boolean - useful for waiting states
```

### In Page Object Pattern

```typescript
import { Page } from 'puppeteer';
import {
  ButtonTestkit,
  InputTestkit,
  LoaderTestkit,
} from '@wix/design-system/dist/testkit/puppeteer';

export class FeaturePage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/feature');
    await this.waitForLoaded();
  }

  async waitForLoaded() {
    const loader = await LoaderTestkit({ dataHook: 'page-loader', page: this.page });
    // Wait until loader disappears
    await this.page.waitForFunction(
      () => !document.querySelector('[data-hook="page-loader"]'),
    );
  }

  async clickSubmit() {
    const btn = await ButtonTestkit({ dataHook: 'submit-btn', page: this.page });
    await btn.click();
  }

  async enterSearch(query: string) {
    const input = await InputTestkit({ dataHook: 'search-input', page: this.page });
    await input.enterText(query);
  }

  async isSubmitDisabled() {
    const btn = await ButtonTestkit({ dataHook: 'submit-btn', page: this.page });
    return btn.isDisabled();
  }
}
```

---

## Playwright Testkits (Sled 3)

### Creating Instances

```typescript
import { ButtonTestkit, InputTestkit } from '@wix/design-system/dist/testkit/playwright';

// Playwright testkits take { dataHook, page }
const button = await ButtonTestkit({ dataHook: 'submit-btn', page });
const input = await InputTestkit({ dataHook: 'search-input', page });
```

### APIs

Playwright testkits mirror the Puppeteer API. Same methods, same `{ dataHook, page }` creation pattern.

```typescript
await button.click();
await button.isDisabled();
await input.enterText('query');
await input.getValue();
```

### In Page Object Pattern (Sled 3 / Playwright)

```typescript
import { Page } from '@playwright/test';
import {
  ButtonTestkit,
  InputTestkit,
} from '@wix/design-system/dist/testkit/playwright';

export class FeaturePage {
  constructor(private page: Page) {}

  async clickSubmit() {
    const btn = await ButtonTestkit({ dataHook: 'submit-btn', page: this.page });
    await btn.click();
  }

  async isSubmitDisabled() {
    const btn = await ButtonTestkit({ dataHook: 'submit-btn', page: this.page });
    return btn.isDisabled();
  }
}
```

---

## Direct Selectors vs Testkits

| Approach | When to Use |
|----------|-------------|
| Direct `data-hook` | Simple interactions (click, text input, read text) |
| WDS Testkits | Complex components (Dropdown options, Modal buttons, Table rows) |

**Simple case - direct selector is fine:**
```typescript
await page.click('[data-hook="submit-btn"]');
```

**Complex case - testkit is better:**
```typescript
// Dropdown has internal popover, option list, scroll behavior
const dropdown = await DropdownTestkit({ dataHook: 'category', page });
await dropdown.selectOptionAt(3); // Handles opening popover + scrolling + clicking
```

---

## Common Component → Testkit Map

| Component | Testkit | Key Browser Methods |
|-----------|---------|-------------------|
| `Button` | `ButtonTestkit` | `click()`, `isDisabled()`, `getText()` |
| `Input` | `InputTestkit` | `enterText()`, `clearText()`, `getValue()` |
| `Dropdown` | `DropdownTestkit` | `selectOptionAt()`, `getSelectedText()` |
| `Modal` | `ModalTestkit` | `isOpen()`, `close()` |
| `Loader` | `LoaderTestkit` | `exists()` |
| `Notification` | `NotificationTestkit` | `getText()`, `exists()`, `close()` |
| `ToggleSwitch` | `ToggleSwitchTestkit` | `click()`, `isChecked()` |
| `Checkbox` | `CheckboxTestkit` | `click()`, `isChecked()`, `isDisabled()` |
| `Table` (WDS) | `TableTestkit` | `getRowsCount()`, `clickRow()` |

---

## Tips

- **Testkit availability**: Not all WDS components have browser testkits. Check the WDS docs for your component. Fall back to direct selectors if no testkit exists.
- **Async**: All browser testkit methods are async. Always `await`.
- **data-hook**: Testkits locate components via `data-hook`. Ensure the component has `dataHook` prop set.
- **Versions**: Keep WDS package version in sync between app and test dependencies.
