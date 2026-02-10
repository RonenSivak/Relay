# BI Troubleshooting

Actionable solutions for common BI implementation issues.

## Contents

- Schema and package issues (missing function, mismatch, type errors)
- Source code reference (repository paths)
- Testkit issues (factory setup, import path, interception)
- Component integration issues (not found, field propagation)
- Test failures (missing events, event timing)
- Build and runtime issues
- Escalation guide

---

## Schema & Package Issues

### Function Missing in Package

```bash
# Update to latest version
yarn up @wix/${loggerPkg}

# Verify function exists
grep -r "${functionName}" node_modules/@wix/${loggerPkg}/dist/types/

# Check available versions
npm view @wix/${loggerPkg} versions --json
```

### Schema Mismatch (Catalog vs Package)

**Possible causes:**
- Outdated package version — schema was updated but package not yet rebuilt
- CI/CD pipeline still running for recent changes
- Sync issue between BI Catalog and repository

**Resolution:**
1. Update package: `yarn up @wix/${loggerPkg}`
2. Compare BI Catalog schema with package types
3. If mismatch persists → contact [#bi-logger-support](https://wix.slack.com/archives/CS9BG540L) with: package name, version, function name, differences

### Type Errors

```typescript
// CORRECT import path
import type { ${functionName}Params } from '@wix/${loggerPkg}/v2/types';

// WRONG — these will cause errors
// import type { ... } from '@wix/${loggerPkg}';
// import type { ... } from '@wix/${loggerPkg}/types';
```

If types still missing after correct import → `yarn up @wix/${loggerPkg}`

---

## Source Code Reference

When debugging package contents:
- **Repository**: `wix-private/bi-schema-loggers`
- **Functions**: `[logger-name]/src/v2/index.ts`
- **Types**: `[logger-name]/src/types.ts`
- **Testkit**: `[logger-name]/src/testkit/client-testkit.ts`

---

## Testkit Issues

### Missing Logger Factory Setup

```typescript
// Only needed for web-bi-logger projects (NOT yoshi-flow-bm)
import { biLoggerTestkit } from 'bi-logger-xxx/testkit';
import { BiLoggerClientFactory } from '@wix/web-bi-logger';

biLoggerTestkit.setLoggerClientFactory(BiLoggerClientFactory);
```

**yoshi-flow-bm** → No factory setup needed. Framework handles it.

### Incorrect Testkit Import Path

```typescript
// CORRECT
import biTestKit from '@wix/bi-logger-menus/testkit/client';

// ALTERNATIVE (bare module alias)
import biTestKit from 'bi-logger-menus/testkit';
```

### Testkit Not Intercepting Events

1. Import testkit **BEFORE** component (required for mocking):
   ```typescript
   import biTestKit from 'bi-logger-menus/testkit';  // First
   import App from './App';  // After
   ```
2. Reset in `beforeEach`:
   ```typescript
   beforeEach(() => { biTestKit.reset(); });
   ```
3. Use `waitFor` for async events:
   ```typescript
   await waitFor(() => {
     expect(biTestKit.myEvent.last()).toBeDefined();
   });
   ```

---

## Component Integration Issues

### Component Not Found

If semantic search doesn't find the target component:

1. Try broader search terms — extract keywords from event description
2. Search in alternative directories: `src/components`, `src/pages`, `src/widgets`
3. Try interaction-based searches: `onClick AND [keyword]`, `[keyword] handler`
4. Mark for manual wiring with guidance:
   - Find the UI element that triggers the described interaction
   - Locate the event handler (onClick, onSubmit, etc.)
   - Add BI call in success path after action completes

### Field Propagation Failures

If required BI fields aren't available in the component:

1. Trace field source in parent components
2. Add field to component props interface: `fieldName?: string;`
3. Update parent to pass field: `<Component fieldName={fieldName} />`
4. Use field in BI event: `reportEvent({ fieldName, ... })`

---

## Test Failures

### Tests Not Finding BI Events

1. **Check BI call exists** — search component for the BI function call
2. **Check timing** — BI should fire AFTER successful action, not before or on failure
3. **Check testkit reset** — ensure `biTestKit.reset()` in `beforeEach`
4. **Check import order** — testkit must be imported before component

### Event Timing Validation

**Good patterns** (BI after success):
```typescript
try {
  const result = await action();
  reportBiEvent(params);  // After success
}

if (success) { reportBiEvent(params); }

promise.then(() => { reportBiEvent(params); });
```

**Bad patterns** (BI in wrong position):
```typescript
reportBiEvent(params);  // Before action — wrong
throw new Error();

reportBiEvent(params);  // Before error handling — wrong
return;
```

---

## Build & Runtime Issues

### Build Failures After Implementation

```bash
# Check missing imports
yarn build 2>&1 | grep -i "cannot find module\|import"

# Check type errors
yarn tsc --noEmit

# Auto-fix lint issues
yarn lint --fix src/
```

### Runtime BI Errors

1. Check BI logger initialization — is the framework set up correctly?
2. Check function availability — does the function exist in the package?
3. Check parameter validation — are types and required fields correct?
4. Check browser console for detailed error messages

---

## Escalation Guide

When to contact [#bi-logger-support](https://wix.slack.com/archives/CS9BG540L):

| Issue | Info to Provide |
|-------|----------------|
| Schema mismatch persists after update | Package name, version, function name, differences |
| Function not found in any version | evid, src, expected function name |
| Complex integration | Component path, trigger context, required fields |
| Persistent test failures | Test output, expected vs actual BI calls |
