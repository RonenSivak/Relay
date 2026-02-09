# Testing BI Events

How to write unit tests that verify React components correctly emit BI events using the bi-logger testkit.

## Contents

- Workflow overview (import, reset, trigger, assert)
- Testkit API and event name patterns
- Complete working example
- Import order (critical)
- Assertion patterns (mandatory fields, multiple events, async, field propagation)
- Testkit configuration (yoshi-flow-bm vs web-bi-logger)
- Debugging utilities (raw events, type validation)
- Common pitfalls

## Workflow

1. Import the BI logger testkit
2. Reset testkit in `beforeEach`
3. Render component and simulate interaction
4. Assert BI event(s) were sent with correct payload

---

## 1. Import the Testkit

Every logger package exposes a client-side testkit:

```typescript
import biTestKit from '@wix/bi-logger-xxx/testkit/client';
```

Replace `xxx` with your schema logger name (e.g., `bi-logger-data-tools`).

The testkit is tree-shake-friendly and does not ship to production.

## 2. Reset Before Each Test

```typescript
beforeEach(() => {
  biTestKit.reset();
});
```

Failing to reset causes flaky tests from event leakage.

## 3. Trigger the Event

Use RTL, Enzyme, or your preferred renderer to simulate the interaction that emits the BI event. Component code stays untouched — the logger works exactly as in production.

## 4. Assert the Event

### Testkit API

| Method | Description |
|--------|-------------|
| `.last()` | Last event instance or `undefined` |
| `.getAll()` | All captured events as array |
| `.length` | Shorthand for `getAll().length` |

### Testkit Event Name Pattern

Testkit accessors follow: `{eventNameCamelCase}Src{src}Evid{evid}`

Example: event `crmCategoryChange` with `src: 189`, `evid: 1318` → `biTestKit.crmCategoryChangeSrc189Evid1318`

---

## CRITICAL: Enhance Existing Tests

**NEVER create isolated BI test files.** Always add BI assertions to existing component test files.

```bash
# Find existing tests
find . -name "*.spec.ts*" -o -name "*.test.ts*" | grep -E "(ComponentName)"
```

---

## Complete Working Example

```typescript
import 'jsdom-global/register';
import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

/* CRITICAL: Must be imported BEFORE component import */
import biTestKit from '@wix/bi-logger-data-tools/testkit/client';

import DataGridComponent from './DataGridComponent';
import eventually from 'wix-eventually';

describe('DataGridComponent BI Events', () => {
  let wrapper;

  beforeEach(() => biTestKit.reset());
  afterEach(() => wrapper?.detach());

  it('should send filterApplied BI event when filter is applied', () => {
    wrapper = mount(
      <DataGridComponent collectionId="test-collection" />,
      { attachTo: document.createElement('div') }
    );

    wrapper.find('.filter-apply-button').simulate('click');

    return eventually(() => {
      const event = biTestKit.filterAppliedSrc72Evid245.last();
      expect(event.collectionId).to.eql('test-collection');
      expect(event.filterType).to.eql('advanced');
    });
  });

  it('should send multiple events when applied multiple times', () => {
    wrapper = mount(<DataGridComponent collectionId="test-collection" />);

    wrapper.find('.filter-apply-button').simulate('click');
    wrapper.find('.filter-apply-button').simulate('click');

    return eventually(() => {
      expect(biTestKit.filterAppliedSrc72Evid245.getAll().length).to.equal(2);
    });
  });
});
```

---

## Import Order (CRITICAL)

1. Testing framework imports (jsdom, React, chai, enzyme)
2. **BI testkit import** (before component — required for mocking)
3. Component import
4. Helper libraries (eventually, etc.)

---

## Assertion Patterns

### Mandatory Fields Only

```typescript
import type { someEventParams } from '@wix/bi-logger-xxx/v2/types';

const expected: Partial<someEventParams> = {
  click: HeaderActionType.ADHOC,
  userName: 'testUser',
};

expect(biTestKit.someEvent.last()).toEqual(
  expect.objectContaining(expected),
);
```

### Multiple Events

```typescript
expect(biTestKit.someEvent.length).toBe(2);
expect(biTestKit.someEvent.getAll()[0]).toEqual(expect.objectContaining({ /* first */ }));
expect(biTestKit.someEvent.getAll()[1]).toEqual(expect.objectContaining({ /* second */ }));
```

### Async Events (wix-eventually)

```typescript
import eventually from 'wix-eventually';

await eventually(() => {
  const event = biTestKit.eventName.last();
  expect(event).toBeDefined();
  expect(event.field).toEqual('expectedValue');
});
```

### Field Propagation Tests

```typescript
it('should propagate BI fields from parent', async () => {
  const wrapper = mount(<ParentComponent locationId="loc-1" menuId="menu-1" />);
  
  wrapper.find(ChildComponent).props().onAction();
  
  await eventually(() => {
    const event = biTestKit.eventName.last();
    expect(event).toEqual(expect.objectContaining({
      locationId: 'loc-1',
      menuId: 'menu-1',
    }));
  });
});
```

---

## Testkit Configuration

### yoshi-flow-bm Projects

No configuration needed. The framework handles everything automatically. Simply import the testkit and reset in `beforeEach`.

### web-bi-logger Projects (non-yoshi-flow-bm)

Requires logger factory initialization:

```typescript
import webBiLogger from '@wix/web-bi-logger';
const logger = webBiLogger.factory().logger();
```

---

## Debugging Utilities

### View All Raw Events

```typescript
// Bypass type checking for debugging
console.log('All BI events:', biTestKit.util.getRawEvents());
```

### Quick Type Validation

```typescript
describe('MyComponent', () => {
  // Adds afterEach that validates all event types
  biTestKit.util.assertAllEventsCorrectTypes();
  
  it('renders correctly', () => {
    // If any BI event has wrong types, test fails in afterEach
  });
});
```

### Utility Reference

| Method | Description |
|--------|-------------|
| `biTestKit.util.getRawEvents()` | All events without type checking (debug) |
| `biTestKit.util.assertAllEventsCorrectTypes()` | afterEach type validation |
| `biTestKit.eventName.last()` | Last event of type |
| `biTestKit.eventName.getAll()` | All events of type |
| `biTestKit.reset()` | Clear event history |

---

## Common Pitfalls

1. **Always reset** in `beforeEach`
2. **Import testkit before component** — required for mocking
3. **Match event builder names exactly** — use IntelliSense
4. **Use `eventually()`** for async event assertions
5. **Use `mount()` with `attachTo`** for DOM interactions in Enzyme
