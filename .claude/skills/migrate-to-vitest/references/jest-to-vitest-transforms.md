# Jest to Vitest Transform Rules

Complete mapping of Jest APIs to Vitest equivalents. Use `globals: true` in vitest config so `describe`, `it`, `expect`, `beforeAll`, `afterAll`, `beforeEach`, `afterEach` work without imports.

## Simple Renames (find-and-replace)

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.fn()` | `vi.fn()` | Identical API |
| `jest.mock('module')` | `vi.mock('module')` | Identical API |
| `jest.spyOn(obj, 'method')` | `vi.spyOn(obj, 'method')` | Identical API |
| `jest.clearAllMocks()` | `vi.clearAllMocks()` | Identical API |
| `jest.resetAllMocks()` | `vi.resetAllMocks()` | Identical API |
| `jest.restoreAllMocks()` | `vi.restoreAllMocks()` | Identical API |
| `jest.useFakeTimers()` | `vi.useFakeTimers()` | Identical API |
| `jest.useRealTimers()` | `vi.useRealTimers()` | Identical API |
| `jest.advanceTimersByTime(ms)` | `vi.advanceTimersByTime(ms)` | Identical API |
| `jest.runAllTimers()` | `vi.runAllTimers()` | Identical API |
| `jest.runOnlyPendingTimers()` | `vi.runOnlyPendingTimers()` | Identical API |
| `jest.clearAllTimers()` | `vi.clearAllTimers()` | Identical API |
| `jest.resetModules()` | `vi.resetModules()` | Identical API |
| `jest.setTimeout(ms)` | `vi.setConfig({ testTimeout: ms })` | Different API |

## Async Transforms (require function changes)

### jest.requireActual -> vi.importActual (ASYNC)

This is the most impactful change. `vi.importActual` is async and returns a Promise.

**Before:**
```typescript
jest.mock('./utils', () => {
  const actual = jest.requireActual('./utils');
  return { ...actual, myFn: jest.fn() };
});
```

**After:**
```typescript
vi.mock('./utils', async () => {
  const actual = await vi.importActual('./utils');
  return { ...actual, myFn: vi.fn() };
});
```

Key rules:
1. The mock factory must become `async`
2. `jest.requireActual(...)` becomes `await vi.importActual(...)`
3. The return type from `vi.importActual` is `unknown` -- you may need to cast: `await vi.importActual<typeof import('./utils')>('./utils')`

### jest.requireMock -> vi.importMock (ASYNC)

Same pattern as above:

**Before:**
```typescript
const mock = jest.requireMock('./module');
```

**After:**
```typescript
const mock = await vi.importMock('./module');
```

## Module Factory with External Variables -> vi.hoisted()

In Jest, `jest.mock()` is hoisted but can freely reference variables in the enclosing scope. In Vitest, `vi.mock()` is also hoisted, but referencing variables defined after the mock can cause issues.

**Before (Jest -- works because jest.mock is hoisted with full scope access):**
```typescript
const mockFn = jest.fn();
jest.mock('./module', () => ({ doThing: mockFn }));
```

**After (Vitest -- use vi.hoisted to ensure variable is available):**
```typescript
const { mockFn } = vi.hoisted(() => ({ mockFn: vi.fn() }));
vi.mock('./module', () => ({ doThing: mockFn }));
```

Rules:
- If the mock factory references a variable defined BEFORE the `vi.mock()` call AND that variable uses `vi.fn()` or similar, wrap it in `vi.hoisted()`
- If the mock factory only uses inline values or imports, no change needed
- `vi.hoisted()` returns the value from the callback and ensures it runs before any mocks

## Default Export Mocking

Jest and Vitest handle default exports differently in some cases.

**Before (Jest):**
```typescript
jest.mock('./module', () => ({
  __esModule: true,
  default: jest.fn(),
}));
```

**After (Vitest -- ESM-native, no __esModule needed):**
```typescript
vi.mock('./module', () => ({
  default: vi.fn(),
}));
```

If the project uses `"type": "module"` (ESM), the `__esModule: true` flag is unnecessary and should be removed.

## Environment Comments

**Before:**
```typescript
/**
 * @jest-environment jsdom
 */
```

**After:**
```typescript
// @vitest-environment jsdom
```

Note: Vitest uses single-line comment syntax, not JSDoc blocks.

## Snapshot Testing

Snapshots work identically. File extension changes from `.snap` to `.snap` (no change needed). If you want to update snapshots:

```bash
# Jest
jest --updateSnapshot

# Vitest
vitest run --update
```

## Import Changes

**If `globals: true` is set (recommended):**
- No need to import `describe`, `it`, `expect`, `beforeAll`, etc.
- Only import `vi` if NOT using globals, otherwise it's available as a global
- With `globals: true`, `vi` is also a global -- no import needed

**If `globals: false`:**
```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
```

**Remove jest imports:**
```typescript
// DELETE these lines if present:
import 'jest';
import type {} from 'jest';
import { jest } from '@jest/globals';
```

## TypeScript Configuration

Add to `tsconfig.json` (or the tsconfig used for tests):

```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

This provides type definitions for `vi`, `describe`, `it`, `expect`, etc. when using `globals: true`.

## Less Common Transforms

| Jest | Vitest | Notes |
|------|--------|-------|
| `jest.genMockFromModule('m')` | `vi.importActual('m')` then mock | Rarely used |
| `jest.isMockFunction(fn)` | `vi.isMockFunction(fn)` | Identical API |
| `jest.mocked(fn)` | `vi.mocked(fn)` | Identical API |
| `jest.retryTimes(n)` | `retry: n` in test config or `describe.retry(n)` | Config-level |
| `expect.assertions(n)` | `expect.assertions(n)` | Identical |
| `expect.hasAssertions()` | `expect.hasAssertions()` | Identical |
| `done` callback | Use async/await or return Promise | Same in both |

## Regex for Bulk Transforms

For automated find-and-replace across files:

```
# Simple renames (safe for bulk replace)
jest\.fn\(       ->  vi.fn(
jest\.mock\(     ->  vi.mock(
jest\.spyOn\(    ->  vi.spyOn(
jest\.clearAllMocks\(   ->  vi.clearAllMocks(
jest\.resetAllMocks\(   ->  vi.resetAllMocks(
jest\.restoreAllMocks\( ->  vi.restoreAllMocks(
jest\.useFakeTimers\(   ->  vi.useFakeTimers(
jest\.useRealTimers\(   ->  vi.useRealTimers(
jest\.advanceTimersByTime\( ->  vi.advanceTimersByTime(
jest\.runAllTimers\(    ->  vi.runAllTimers(
jest\.runOnlyPendingTimers\( ->  vi.runOnlyPendingTimers(
jest\.clearAllTimers\(  ->  vi.clearAllTimers(
jest\.resetModules\(    ->  vi.resetModules(
jest\.isMockFunction\(  ->  vi.isMockFunction(
jest\.mocked\(          ->  vi.mocked(

# Requires manual review (async change)
jest\.requireActual\(   ->  await vi.importActual(
```
