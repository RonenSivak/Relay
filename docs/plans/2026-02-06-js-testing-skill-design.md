# JS Testing Skill Design

## Overview

A comprehensive JavaScript/TypeScript testing skill that adapts to existing project patterns or introduces BDD architecture (driver/builder/spec) when starting fresh.

## Scope

- **Unit Tests** - Component logic, hooks, utilities (Jest/Vitest)
- **Integration Tests** - Component interactions with services/stores (Jest/Vitest + RTL)
- **E2E** - Out of scope for now

## Pattern Detection (Always First)

1. Search for existing test files (`*.test.ts`, `*.spec.ts`, `__tests__/`)
2. If found → analyze patterns (naming, structure, mocking approach) and follow them
3. If none → use the BDD architecture below

## BDD Architecture (When No Existing Tests)

```
component/
├── component.tsx
├── component.driver.ts    # All test logic and actions
├── component.builder.ts   # Mock data factories
└── component.spec.ts      # Semantic tests using driver + builder
```

### Driver Pattern (get/given/when)

Chainable methods for readable tests:

```typescript
export class ComponentDriver {
  private wrapper: RenderResult;

  given = {
    rendered: (props?: Partial<Props>) => {
      /* render component */
      return this;
    },
    userIsLoggedIn: () => {
      /* mock auth state */
      return this;
    },
    apiReturnsError: () => {
      /* mock API failure */
      return this;
    },
  };

  when = {
    clickSubmitButton: () => {
      /* click action */
      return this;
    },
    enterText: (text: string) => {
      /* type in input */
      return this;
    },
  };

  get = {
    errorMessage: () => /* return error text */,
    submitButton: () => /* return button element */,
    isLoading: () => /* return loading state */,
  };
}
```

### Builder Pattern

```typescript
export const aUser = (overrides?: Partial<User>): User => ({
  id: 'user-123',
  name: 'Test User',
  email: 'test@example.com',
  ...overrides,
});
```

### Spec Pattern

```typescript
it('should show error when API fails', async () => {
  const driver = new ComponentDriver();

  driver
    .given.rendered()
    .given.apiReturnsError()
    .when.clickSubmitButton();

  expect(driver.get.errorMessage()).toBe('Something went wrong');
});
```

## Skill Triggers

1. **"Write tests for X"** - Analyze patterns, create driver/builder/spec
2. **"TDD for X"** - Red/green/refactor cycle
3. **"Review my tests"** - Coverage gaps, flaky patterns, readability
4. **"Fix this failing/flaky test"** - Diagnose and fix

## Skill Structure

```
js-testing/
├── SKILL.md                    # Core workflow + pattern detection
└── references/
    ├── driver-pattern.md       # get/given/when driver template
    ├── builder-pattern.md      # Factory patterns with examples
    └── common-scenarios.md     # Testing hooks, async, mocking
```

## Framework Detection

1. Check `package.json` for installed test frameworks
2. Check existing test configs (`jest.config`, `vitest.config`)
3. If multiple found → ask user which to use
4. If none → recommend Vitest for unit/integration
