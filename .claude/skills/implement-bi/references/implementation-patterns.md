# BI Implementation Patterns

Detailed patterns for implementing BI event logging in yoshi-flow-bm React projects using bi-schema-loggers.

## Contents

- Import rules (v2 paths for functions, types, testkit)
- Wiring strategy priority (shared hook → wrapper → standalone)
- Checking for existing wrappers
- Component integration (analyze, import, initialize, wire)
- Field propagation (props, parent updates, tree tracing)
- Static constants and field mapping
- Event schema fields reference
- Quality checklist

## Import Rules (CRITICAL)

All imports MUST use `/v2` tree-shakable paths.

### Event Builder Functions

```typescript
// CORRECT
import { reportMenuUpdated } from '@wix/bi-logger-menus/v2';

// WRONG — imports entire package
import { reportMenuUpdated } from '@wix/bi-logger-menus';
```

### Type Definitions

```typescript
// CORRECT
import type { ReportMenuUpdatedParams } from '@wix/bi-logger-menus/v2/types';

// WRONG
import type { ReportMenuUpdatedParams } from '@wix/bi-logger-menus/types';
import type { ReportMenuUpdatedParams } from '@wix/bi-logger-menus';
```

### Testkit

```typescript
// CORRECT
import biTestKit from 'bi-logger-menus/testkit';
// OR
import biTestKit from 'bi-logger-menus/dist/src/testkit';

// WRONG
import biTestKit from 'bi-logger-menus/testkit/client';
```

**Why `/v2`?** Tree-shaking, smaller bundles, official bi-schema-loggers standard.

---

## Wiring Strategy Priority

Always follow this order:

### Priority 1: Extend Existing Shared Hook (PREFERRED)

```typescript
// In existing shared hook file (e.g., src/hooks/useSharedBi.ts)

// Add import
import { reportMenuUpdated } from '@wix/bi-logger-menus/v2';
import type { ReportMenuUpdatedParams } from '@wix/bi-logger-menus/v2/types';

// Add method inside the hook
const reportMenuUpdatedEvent = (params: ReportMenuUpdatedParams) => {
  biLogger.report(reportMenuUpdated(params));
};

// Add to return object
return { ...existingMethods, reportMenuUpdatedEvent };
```

### Priority 2: Component Wrapper Using Shared Hook

```typescript
// src/components/MenuEditor/MenuEditor.bi.ts
import { useSharedBi } from 'src/hooks/useSharedBi';

export const useMenuEditorBi = () => {
  const { reportMenuUpdatedEvent } = useSharedBi();
  return { reportMenuUpdatedEvent };
};
```

### Priority 3: Standalone Hook (Last Resort)

```typescript
// src/hooks/useMenuEditorBi.ts
import { useBi } from '@wix/yoshi-flow-bm';
import { reportMenuUpdated } from '@wix/bi-logger-menus/v2';
import type { ReportMenuUpdatedParams } from '@wix/bi-logger-menus/v2/types';

export const useMenuEditorBi = () => {
  const biLogger = useBi();
  const reportMenuUpdatedEvent = (params: ReportMenuUpdatedParams) => {
    biLogger.report(reportMenuUpdated(params));
  };
  return { reportMenuUpdatedEvent };
};
```

---

## Checking for Existing Wrappers

Before implementing, always check:

1. **Search for logger files**: `useLogger.ts`, `logger.ts`, `bi-logger.ts`, `*Bi*.ts`
2. **Check component imports**: Does the component already use a custom logger hook?
3. **Examine wrapper pattern**: Does it wrap `useBi()`? Add common context? Follow naming conventions?

**If wrapper exists** → extend it. Add import, add method, follow its naming pattern.
**If no wrapper** → proceed with direct `useBi()` or create one if the project would benefit.

---

## Component Integration

### Step 1: Analyze Component Structure

- Read component files from analysis
- Identify integration points (event handlers, async functions)
- BI must fire on the **actual described flow** — after creation, edit, deletion success, etc.

### Step 2: Add Hook Import

```typescript
// Determine correct import based on wiring strategy
import { useSharedBi } from 'src/hooks/useSharedBi';
// OR
import { useMenuEditorBi } from './MenuEditor.bi';
```

### Step 3: Initialize Hook

```typescript
const { reportMenuUpdatedEvent } = useSharedBi();
```

### Step 4: Wire BI Call

```typescript
const handleSave = async (data) => {
  try {
    const result = await saveMenu(data);
    
    // BI after successful action
    reportMenuUpdatedEvent({
      menuId: data.id,
      locationId: data.locationId,
      action: 'save',
    });
    
    onSuccess?.(result);
  } catch (error) {
    handleError(error);
  }
};
```

---

## Field Propagation

### Adding BI Fields to Props

```typescript
interface MenuEditorProps {
  // ... existing props
  locationId?: string; // Optional BI field
  menuId: string;      // Required BI field
}
```

### Updating Parent Components

```typescript
// Parent passes BI fields down
<MenuEditor locationId={locationId} menuId={menuId} />
```

### Tracing Fields Through Component Tree

1. Find where target component is used
2. Trace field sources up the tree (e.g., `locationId` in parent's logic)
3. Propagate through all intermediate components
4. Ensure ALL required BI fields reach the reporting point

---

## Static Constants

Use existing or create a constants file for static properties:

```typescript
export const BI_CONSTANTS = {
  ORIGIN: 'menu-editor',
  APP_NAME: 'wix-menus',
} as const;
```

Map `staticProperties` from `EventorOutput` to these constants (using `.value`).
Map `dynamicProperties` to component data sources (using `.description` as guidance).

---

## Event Schema Fields

From the BI Catalog schema:
- `inputName` → field key in params
- `type` → STRING, NUMERIC, etc.
- `isMandatory` → true = must be present
- `description` → field meaning
- Fields named `src` or `evid` are sent automatically by the schema logger — don't include them

---

## Quality Checklist

Before completing Phase 2:
- All component props include necessary BI fields
- Used existing shared hooks when possible
- Project builds successfully (`yarn tsc --noEmit`)
- Linting passes (`yarn lint`)
- No broken imports or missing dependencies
- BI calls are in correct timing position (after action success)
