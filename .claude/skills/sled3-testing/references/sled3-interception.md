# InterceptionPipeline Deep Dive

Source-verified API reference for Sled 3's network interception system. All types verified from `wix-private/sled-playwright` TypeScript source.

## CRITICAL WARNING

**`interceptors.push()` does NOT register routes.** It only mutates the array — Playwright's `context.route()` is never called. Always use `interceptionPipeline.setup()`.

---

## Types

### InterceptHandler

```typescript
interface InterceptHandler {
  id?: string;                    // Optional identifier for reporting/debugging
  pattern?: string | RegExp;      // URL pattern (default: '**/*' — matches everything)
  handler: (params: HandlerParams) => InterceptionResult | Promise<InterceptionResult>;
  shouldReport?: boolean;         // Include in reports (default: false for CONTINUE)
}
```

### HandlerParams

```typescript
interface HandlerParams {
  url: string;
  headers: Record<string, string>;
  method: string;
  postData: string | null;
  resourceType: string;
}
```

### Pattern Matching

- **String:** Playwright glob syntax (`**/*`, `**/api/**`, `https://example.com/api/*`)
- **RegExp:** Passed directly to `context.route()` (`/\/(api|_api)\//`)
- **Default:** `'**/*'` when `pattern` is omitted — matches everything
- **Tip:** Use RegExp for complex patterns; string globs for simple URL matching

---

## InterceptHandlerActions

All 11 actions with their required return shapes:

### CONTINUE
Pass through — let the request proceed to the network.
```typescript
{ action: InterceptHandlerActions.CONTINUE }
```

### FALLBACK
Pass to the previous handler in the LIFO chain.
```typescript
{ action: InterceptHandlerActions.FALLBACK }
```

### ABORT
Block the request entirely. Use for catch-all API blocking.
```typescript
{ action: InterceptHandlerActions.ABORT }
```

### INJECT_RESOURCE
Return a synthetic response without hitting the network. Most common for mocking.
```typescript
{
  action: InterceptHandlerActions.INJECT_RESOURCE,
  resource: Buffer.from(JSON.stringify(data)),  // or () => Promise<Buffer> for async
  responseCode: 200,
  responseHeaders: { 'Content-Type': 'application/json' },
}
```
**Async resource supported:** `resource: () => Promise<Buffer>` — useful for proxying.

### INJECT_REMOTE_RESOURCE
Redirect the request to a different URL.
```typescript
{
  action: InterceptHandlerActions.INJECT_REMOTE_RESOURCE,
  url: 'https://other-server.com/api/data',
}
```

### EMPTY_RESPONSE
Return an empty 200 response.
```typescript
{ action: InterceptHandlerActions.EMPTY_RESPONSE }
```

### REDIRECT
Redirect to a different URL (HTTP redirect).
```typescript
{
  action: InterceptHandlerActions.REDIRECT,
  url: 'https://redirect-target.com',
}
```

### MODIFY_RESOURCE
Modify the response after it comes back from the network.
```typescript
{
  action: InterceptHandlerActions.MODIFY_RESOURCE,
  modify: ({ body, headers }) => ({
    body: Buffer.from(JSON.stringify(modifiedData)),
    headers: { ...headers, 'x-modified': 'true' },
  }),
}
```

### HOLD
Pause the request (for timing control).
```typescript
{ action: InterceptHandlerActions.HOLD }
```

### MODIFY_REQUEST
Modify the request before it's sent.
```typescript
{
  action: InterceptHandlerActions.MODIFY_REQUEST,
  modify: ({ headers }) => ({
    headers: { ...headers, Authorization: 'Bearer token' },
  }),
}
```

### ASYNC_INTERCEPT
Run async logic before deciding action.
```typescript
{
  action: InterceptHandlerActions.ASYNC_INTERCEPT,
  handler: async (params) => {
    const data = await fetchMockData();
    return {
      action: InterceptHandlerActions.INJECT_RESOURCE,
      resource: Buffer.from(JSON.stringify(data)),
      responseCode: 200,
    };
  },
}
```

---

## Ordering: LIFO (Last In, First Out)

Playwright's `context.route()` uses reverse registration order. **Last registered handler runs first.**

```
Handler registration order:    [A, B, C, catchAll]
Execution order for a request: catchAll → C → B → A
```

When a handler returns `FALLBACK`, the request passes to the **previous** handler in the chain.

**Implication for catch-all:** Place the catch-all handler **last** in the `setup()` array so it registers last and runs first. If a specific mock matches before it, use `FALLBACK` to pass non-matching requests to the catch-all.

**Wait — correction:** Since LIFO means last-registered runs first, and `setup()` registers handlers in array order... the catch-all should go LAST in the array. Specific mocks go FIRST. The catch-all (registered last) will run first and handle unmatched requests.

Actually the correct pattern is:
```typescript
// Specific mocks first, catch-all last in the array
// BUT because LIFO: catch-all runs first, specific mocks get FALLBACK from catch-all
await interceptionPipeline.setup([
  specificMock1,   // Registered first → runs last
  specificMock2,   // Registered second → runs second-to-last
  catchAll,        // Registered last → runs FIRST
]);
```

For the catch-all to work correctly with LIFO, specific mocks should use patterns that DON'T overlap with the catch-all, OR the catch-all should be at the end so it runs first and blocks unmatched URLs.

---

## Setup Methods

### `interceptionPipeline.setup(handlers)`
The ONLY correct way to register handlers:
```typescript
test('with mocks', async ({ page, interceptionPipeline }) => {
  await interceptionPipeline.setup([
    {
      id: 'items-api',
      pattern: /\/api\/items/,
      handler: () => ({
        action: InterceptHandlerActions.INJECT_RESOURCE,
        resource: Buffer.from(JSON.stringify({ items: [] })),
        responseCode: 200,
        responseHeaders: { 'Content-Type': 'application/json' },
      }),
    },
    {
      id: 'catch-all',
      pattern: /\/(api|_api)\//,
      handler: () => ({ action: InterceptHandlerActions.ABORT }),
    },
  ]);
  await page.goto('/dashboard');
});
```

### `test.use({ interceptors })`
Static interceptors for all tests in a describe block:
```typescript
test.use({
  interceptors: [
    { pattern: /\/api\/config/, handler: () => ({ action: InterceptHandlerActions.INJECT_RESOURCE, resource: Buffer.from('{}'), responseCode: 200 }) },
  ],
});
```

---

## Reports API

```typescript
// interceptionPipeline.reports is a getter (read-only)
const reports: InterceptionReport[] = interceptionPipeline.reports;
```

Each report contains:
```typescript
interface InterceptionReport {
  action: string;              // The action taken
  interceptedRequest: {        // Request details
    url: string;
    method: string;
    // ...
  };
  change: any;                 // What was modified
  interceptBy: {
    pattern: string | RegExp;  // Which handler matched
    id?: string;               // Handler ID
  };
}
```

Only recorded when the handler has `shouldReport: true` or performs a `fulfill`/`rewrite` action.

---

## Real-World Examples

### 1. BDD Driver with Chainable Mocks (job-runner-ai)

```typescript
export class E2EDriver {
  private interceptors: InterceptHandler[] = [];

  reset = () => { this.interceptors = []; };

  setup = async (interceptionPipeline: any) => {
    interceptionPipeline.setup(this.interceptors);
  };

  given = {
    getJobs: (jobs: Job[]) => {
      this.interceptors.push({
        pattern: BASE_URL + appPaths.api.jobs,
        handler: () => ({
          action: InterceptHandlerActions.INJECT_RESOURCE,
          resource: Buffer.from(JSON.stringify({ jobs })),
          responseCode: 200,
          responseHeaders: { 'Content-Type': 'application/json' },
        }),
      });
      return this;
    },
  };
}

// Usage in spec:
await driver.given.getJobs([mockJob]).setup(interceptionPipeline);
```

### 2. Error State Testing (form-client)

```typescript
await interceptionPipeline.setup([
  {
    pattern: /v4\/form-app-automations/,
    handler: () => ({ action: InterceptHandlerActions.ABORT }),
  },
]);
await driver.openSettingsTab();
expect(await driver.automationsErrorState().exists()).toBe(true);
```

### 3. Async Localhost Proxy (site-scannerV2)

```typescript
{
  id: 'cdn-chunk-proxy',
  pattern: '***',
  handler({ url, method, postData, headers }) {
    if (url.includes('localhost:3000')) {
      return {
        action: InterceptHandlerActions.INJECT_RESOURCE,
        resource: async () => {
          const resp = await fetch(url, { method, headers, body: postData });
          return Buffer.from(await resp.arrayBuffer());
        },
      };
    }
    return { action: InterceptHandlerActions.CONTINUE };
  },
}
```

### 4. Catch-All Pattern (recommended)

```typescript
const catchAll: InterceptHandler = {
  id: 'catch-all-api-block',
  pattern: /\/(api|_api)\//,
  handler: () => ({ action: InterceptHandlerActions.ABORT }),
};

// In base driver setup():
await interceptionPipeline.setup([...specificMocks, catchAll]);
```
