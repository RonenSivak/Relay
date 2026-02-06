# Frontend Review Reference

Detailed patterns and anti-patterns for reviewing React/TypeScript frontend code in Wix projects.

## React Anti-Patterns to Flag

### Prop Mutation

```typescript
// BLOCKER: Mutating props
function UserProfile({ user }: Props) {
  user.lastViewed = new Date(); // Mutating prop!
  return <div>{user.name}</div>;
}

// Correct: Notify parent to update
function UserProfile({ user, onView }: Props) {
  useEffect(() => {
    onView(user.id);
  }, [user.id, onView]);
  return <div>{user.name}</div>;
}
```

### Stale Closure in useEffect

```typescript
// BLOCKER: Stale state in interval
function Counter() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCount(count + 1); // Always uses initial count (0)
    }, 1000);
    return () => clearInterval(interval);
  }, []); // Missing count dependency — or use updater

  // Correct: Use functional updater
  useEffect(() => {
    const interval = setInterval(() => {
      setCount(prev => prev + 1);
    }, 1000);
    return () => clearInterval(interval);
  }, []);
}
```

### Missing Cleanup

```typescript
// IMPORTANT: Memory leak — no cleanup
useEffect(() => {
  const subscription = eventBus.subscribe('update', handler);
  // Missing: return () => subscription.unsubscribe();
}, []);

// IMPORTANT: Abort controller for async effects
useEffect(() => {
  const controller = new AbortController();
  fetchData({ signal: controller.signal }).then(setData);
  return () => controller.abort();
}, []);
```

### Unnecessary Re-Renders

```typescript
// IMPORTANT: New object reference every render
function Parent() {
  return <Child style={{ color: 'red' }} />; // New object each render
}

// Better: Stable reference
const style = { color: 'red' };
function Parent() {
  return <Child style={style} />;
}

// Or with useMemo for dynamic values
function Parent({ theme }: Props) {
  const style = useMemo(() => ({ color: theme.primary }), [theme.primary]);
  return <Child style={style} />;
}
```

### Key Anti-Patterns in Lists

```typescript
// BLOCKER: Using index as key for dynamic lists
{items.map((item, index) => (
  <Item key={index} data={item} /> // Causes bugs on reorder/delete
))}

// Correct: Use stable unique ID
{items.map(item => (
  <Item key={item.id} data={item} />
))}
```

## WDS-Specific Review Points

### Layout

```typescript
// SUGGESTION: Use WDS layout instead of raw divs
// Bad
<div style={{ display: 'flex', gap: '12px' }}>
  <div style={{ flex: 1 }}>...</div>
</div>

// Good — WDS layout
<Layout>
  <Cell span={6}><Card>...</Card></Cell>
  <Cell span={6}><Card>...</Card></Cell>
</Layout>
```

### Component Usage

```typescript
// SUGGESTION: Use WDS components for standard UI elements
// Bad — custom button
<button className={styles.primaryBtn} onClick={onSave}>Save</button>

// Good — WDS Button
<Button priority="primary" onClick={onSave}>Save</Button>

// IMPORTANT: Check WDS props match API
// If unsure, invoke /wds-docs to verify component props
```

### Theme Tokens

```typescript
// NIT: Hardcoded colors instead of theme tokens
.title {
  color: #3b3b3b;          /* Hardcoded */
  margin-bottom: 12px;      /* Hardcoded */
}

// Better: Theme tokens
.title {
  color: var(--wsr-color-D10);
  margin-bottom: var(--wsr-spacing-20);
}
```

## TypeScript Frontend Patterns

### Avoid `any`

```typescript
// IMPORTANT: Using `any` defeats type safety
function processData(data: any) {
  return data.value;
}

// Better: Define proper types
interface DataPayload {
  value: string;
  metadata?: Record<string, unknown>;
}
function processData(data: DataPayload) {
  return data.value;
}
```

### Proper Error Handling in Async

```typescript
// IMPORTANT: Unhandled fetch errors
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  return response.json(); // What if network fails? What if 404?
}

// Better: Handle errors properly
async function fetchUser(id: string): Promise<User> {
  const response = await httpClient.get(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.status}`);
  }
  return response.data;
}
```

### Event Handler Typing

```typescript
// NIT: Loose event typing
const handleChange = (e: any) => {
  setValue(e.target.value);
};

// Better: Proper event types
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  setValue(e.target.value);
};
```

## Accessibility Checklist

- Interactive elements (`<Button>`, `<a>`, `<input>`) have visible labels or `aria-label`
- Images have meaningful `alt` text (or `alt=""` for decorative)
- Form inputs are associated with labels (`htmlFor` or wrapping `<label>`)
- Focus management: modals trap focus, closing returns focus to trigger
- Color is not the only indicator (add icons or text for status)
- Tab order is logical (avoid positive `tabIndex`)

## i18n Checklist

- All user-facing strings use translation functions (`t('key')` or equivalent)
- Translation keys are descriptive: `settings.notifications.title` not `str_123`
- Pluralization handled: `t('items', { count })` not ternary on count
- No string concatenation for translated text (breaks RTL and grammar)
- Date/number formatting uses locale-aware utilities

## Performance Red Flags

| Pattern | Issue | Fix |
|---------|-------|-----|
| `import _ from 'lodash'` | Imports entire library | `import debounce from 'lodash/debounce'` |
| Large component in main bundle | Blocks initial render | `React.lazy()` + `Suspense` |
| Unthrottled scroll/resize handler | Layout thrashing | `useCallback` + `throttle` |
| Re-render on every context change | Unnecessary renders | Split contexts or use selectors |
| Inline SVG in component body | Re-created each render | Extract to separate component or file |
