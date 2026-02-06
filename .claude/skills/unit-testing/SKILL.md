---
name: unit-testing
description: JavaScript/TypeScript testing skill for unit and integration tests. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist. Use when asked to: (1) Write tests for code, (2) TDD workflow, (3) Review or improve tests, (4) Fix failing or flaky tests. Covers Jest, Vitest, React Testing Library, Wix Ambassador (HTTP/RPC), WDS testkits, and @wix/patterns.
---

# JS Testing

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before writing tests, invoke `/brainstorming` to clarify:
1. What exactly needs testing? (component, hook, utility, service, API)
2. What behaviors/scenarios should be covered?
3. Are there existing test patterns to follow?

## Core Workflow

### Step 1: Pattern Detection (Always First)

**CRITICAL:** Before writing any tests, analyze existing patterns in the codebase. For Wix Ambassador and WDS cases, always follow the project's established approach (import paths, mocking style, driver conventions). Only fall back to this skill's templates when no existing patterns exist.

```bash
# Find existing test files
Glob: **/*.test.ts, **/*.spec.ts, **/__tests__/**

# If tests found, read 2-3 examples to understand patterns
Read: [existing test files]
```

**Decision:**
- **Tests exist** → Follow their patterns (naming, structure, mocking)
- **No tests** → Use BDD architecture (driver/builder/spec)

### Step 2: Framework Detection

```bash
# Check package.json for test frameworks
Read: package.json (look for test, test:unit, jest, vitest, @testing-library)

# Check for config files
Glob: jest.config.*, vitest.config.*, setupTests.*
```

**If no framework:** Recommend Vitest for new projects.

### Step 3: Write Tests

**If following existing patterns:** Match their style exactly.

**If using BDD architecture:** Create three files:

```
component/
├── component.driver.ts    # Test logic (get/given/when)
├── component.builder.ts   # Mock data factories
└── component.spec.ts      # Semantic tests
```

See `references/driver-pattern.md` and `references/builder-pattern.md` for templates.

## Triggers & Workflows

### "Write tests for X"

1. Run pattern detection (Step 1)
2. Identify what needs testing
3. Create test files following detected/BDD pattern
4. Cover: happy path, edge cases, error states

### "TDD for X"

1. Clarify requirements first
2. Write failing spec (red)
3. Implement minimal code to pass (green)
4. Refactor while keeping tests green
5. Repeat

### "Review my tests"

1. Read existing tests
2. Check for:
   - Coverage gaps (untested branches)
   - Flaky patterns (timing, shared state)
   - Readability issues
   - Missing edge cases
3. Suggest specific improvements

### "Fix failing/flaky test"

1. Run the test, observe failure
2. Common causes:
   - **Timing:** Missing `await`, wrong waitFor usage
   - **State leaks:** Tests not isolated
   - **Mock issues:** Wrong mock setup/reset
3. Propose fix with explanation

## BDD Architecture Summary

**Driver** (`component.driver.ts`):
- `given.*` - Setup/preconditions (return `this` for chaining)
- `when.*` - Actions (return `this` for chaining)
- `get.*` - Queries (return values)

**Builder** (`component.builder.ts`):
- Factory functions with sensible defaults
- Allow partial overrides

**Spec** (`component.spec.ts`):
- Reads like documentation
- Uses driver and builder only
- No implementation details

Example:
```typescript
it('should show error when API fails', () => {
  const driver = new ComponentDriver();

  driver
    .given.rendered()
    .given.apiReturnsError()
    .when.clickSubmitButton();

  expect(driver.get.errorMessage()).toBe('Something went wrong');
});
```

## Wix Ambassador Testing

**IMPORTANT: Always check the existing codebase first.** Look for existing ambassador mocks, stubs, or test helpers before writing new ones. Match the project's established mocking approach.

Four mocking approaches depending on your environment:

| Approach | Import | When to Use |
|----------|--------|-------------|
| `AmbassadorTestkit` | `@wix/ambassador-testkit` | Classic RPC stubs |
| `when()` | `@wix/ambassador-grpc-testkit` | gRPC / serverless functions (V2) |
| `whenAmbassadorCalled()` | `@wix/yoshi-flow-bm/test/serverless` or `@wix/serverless-testkit` | Yoshi BM / serverless |
| `createHttpClientMock` / `whenRequest` | `@wix/http-client-testkit` | HTTP ambassador calls via httpClient |

**Quick example (RPC with builders):**
```typescript
import { AmbassadorTestkit } from '@wix/ambassador-testkit';
import { MyService } from '@wix/ambassador-my-service-v1/rpc';
import { aGetItemResponse } from '@wix/ambassador-my-service-v1/builders';

ambassadorTestkit
  .createStub(MyService)
  .ItemService()
  .getItem.when({ id: 'item-1' })
  .resolve(aGetItemResponse().withItem({ name: 'Test' }).build());
```

**Quick example (HTTP client mock):**
```typescript
const httpRequestMock = jest.fn().mockResolvedValue({ data: mockData });
// Inject via engine or module mock:
httpClient: () => ({ request: httpRequestMock })
```

See `references/ambassador-testing.md` for full patterns, builder examples, and error mocking.

## WDS & @wix/patterns Testing

**IMPORTANT: Always check the existing codebase first.** Look for existing WDS drivers, testkit imports, and `data-hook` conventions before writing new ones. Match the project's patterns.

WDS components expose **testkits** and use `data-hook` for queries.

**Key setup (RTL):**
```typescript
import { configure } from '@testing-library/react';
configure({ testIdAttribute: 'data-hook' });
```

**Quick example (WDS testkit in driver):**
```typescript
// Preferred: new testing-library path (async-safe)
import { ButtonTestkit, InputTestkit } from '@wix/design-system/dist/testkit/testing-library';
// Legacy (still works but being deprecated):
// import { ButtonTestkit } from '@wix/design-system/dist/testkit';

get = {
  submitButton: () => ButtonTestkit({
    wrapper: this.baseElement,
    dataHook: 'submit-btn',
  }),
};
```

**Quick example (@wix/patterns Table):**
```typescript
import { TableTestkit } from '@wix/patterns/testkit/jsdom';

const table = TableTestkit({ wrapper: baseElement, dataHook: 'my-table' });
await table.getRowsCount();
await table.clickRow(0);
```

See `references/wds-testing.md` for full driver patterns, testkit API, and component examples.

## References

- `references/driver-pattern.md` - Full chainable driver template
- `references/builder-pattern.md` - Factory patterns with examples
- `references/common-scenarios.md` - Hooks, async, mocking patterns
- `references/ambassador-testing.md` - Wix Ambassador HTTP & RPC testing
- `references/wds-testing.md` - WDS testkits & @wix/patterns testing
