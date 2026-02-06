---
name: js-testing
description: JavaScript/TypeScript testing skill for unit and integration tests. Adapts to existing test patterns or introduces BDD architecture (driver/builder/spec) when none exist. Use when asked to: (1) Write tests for code, (2) TDD workflow, (3) Review or improve tests, (4) Fix failing or flaky tests. Supports Jest, Vitest, React Testing Library.
---

# JS Testing

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before writing tests, invoke `/brainstorming` to clarify:
1. What exactly needs testing? (component, hook, utility, service)
2. What behaviors/scenarios should be covered?
3. Are there existing test patterns to follow?

## Core Workflow

### Step 1: Pattern Detection (Always First)

Before writing any tests, analyze existing patterns:

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
Read: package.json (look for jest, vitest, @testing-library)

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

## References

- `references/driver-pattern.md` - Full chainable driver template
- `references/builder-pattern.md` - Factory patterns with examples
- `references/common-scenarios.md` - Hooks, async, mocking patterns
