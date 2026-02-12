# Sled 3 InterceptionPipeline API — Complete Verified Reference

> Deep-search verification from `wix-private/sled-playwright` (Jan 2026). Source: `packages/browser-integrations`, `packages/playwright`, `wix-docs`.

---

## 1. Core Types

### InterceptHandler

```typescript
interface InterceptHandler {
  id?: string;
  pattern?: RegExp | string;
  handler(params: HandlerParams): InterceptionResult;
  shouldReport?: boolean;
}
```

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | `string` | No | `'interceptor-without-id'` | Used in `reports.interceptBy.id` |
| `pattern` | `RegExp \| string` | No | `'**/*'` | Playwright glob (string) or RegExp; passed to `context.route()` |
| `handler` | `(params) => InterceptionResult` | **Yes** | — | Synchronous; use `ASYNC_INTERCEPT` for async |
| `shouldReport` | `boolean` | No | `true` | When false, no entry in `reports` for fulfill/rewrite |

**Source:** `packages/browser-integrations/src/interceptors/interceptors.types.ts`

---

### HandlerParams

```typescript
interface HandlerParams {
  url: string;        // Full request URL
  headers: Headers;   // Record<string, string>
  method: string;    // GET, POST, etc.
  postData: unknown; // Request body
  resourceType: string; // document, script, xhr, fetch, etc.
}
```

**Source:** `packages/browser-integrations/src/interceptors/interceptors.types.ts`

---

### InterceptionResult (Union)

Handler must return one of these shapes:

| Action | Return Shape |
|--------|--------------|
| `CONTINUE` | `{ action }` |
| `FALLBACK` | `{ action }` |
| `ABORT` | `{ action }` |
| `EMPTY_RESPONSE` | `{ action }` |
| `INJECT_RESOURCE` | `{ action, resource, responseCode?, responseHeaders?, responsePhrase? }` |
| `INJECT_REMOTE_RESOURCE` | `{ action, remoteResourceUrl, forwardHeaders, modifyHeaders?, handleMissingUrl? }` |
| `REDIRECT` | `{ action, url, headers?, handleMissingUrl? }` |
| `MODIFY_REQUEST` | `{ action, url?, headers?, postData? }` |
| `MODIFY_RESOURCE` | `{ action, status?, modifyBody?, modifyHeaders? }` |
| `HOLD` | `{ action, waitUntil }` |
| `ASYNC_INTERCEPT` | `{ action, asyncResult }` |

---

## 2. InterceptHandlerActions Enum

```typescript
enum InterceptHandlerActions {
  CONTINUE = 'CONTINUE',
  FALLBACK = 'FALLBACK',
  ABORT = 'ABORT',
  INJECT_RESOURCE = 'INJECT_RESOURCE',
  INJECT_REMOTE_RESOURCE = 'INJECT_REMOTE_RESOURCE',
  EMPTY_RESPONSE = 'EMPTY_RESPONSE',
  REDIRECT = 'REDIRECT',
  MODIFY_RESOURCE = 'MODIFY_RESOURCE',
  HOLD = 'HOLD',
  MODIFY_REQUEST = 'MODIFY_REQUEST',
  ASYNC_INTERCEPT = 'ASYNC_INTERCEPT',
}
```

**Source:** `packages/browser-integrations/src/interceptors/interceptors.constants.ts`

---

## 3. Action Return Shapes (Verified from executeAction.ts)

### CONTINUE / FALLBACK

```typescript
return { action: InterceptHandlerActions.CONTINUE };
// or
return { action: InterceptHandlerActions.FALLBACK };
```

- **CONTINUE**: Pass to next handler via `route.fallback()`; if none, original request continues.
- **FALLBACK**: Same behavior as CONTINUE.

---

### ABORT

```typescript
return { action: InterceptHandlerActions.ABORT };
```

- Calls `route.abort()`.

---

### EMPTY_RESPONSE

```typescript
return { action: InterceptHandlerActions.EMPTY_RESPONSE };
```

- Returns 204, empty body, CORS headers.

---

### INJECT_RESOURCE

```typescript
return {
  action: InterceptHandlerActions.INJECT_RESOURCE,
  resource: Buffer.from(JSON.stringify({ data: 'mocked' })),
  responseCode: 200,        // optional, default 200
  responseHeaders: {},      // optional
  responsePhrase: 'OK',     // optional — NOT IMPLEMENTED (type vs impl gap)
};
```

**Async resource (supported):**

```typescript
return {
  action: InterceptHandlerActions.INJECT_RESOURCE,
  resource: async () => {
    const res = await fetch('http://localhost:3200/chunk.js');
    return Buffer.from(await res.arrayBuffer());
  },
};
```

- `resource`: `Buffer | (() => Promise<Buffer>)`
- `responsePhrase`: in types but not used in `executeAction` — no `statusText` passed to Playwright `fulfill`. **Gap.**

---

### INJECT_REMOTE_RESOURCE

```typescript
return {
  action: InterceptHandlerActions.INJECT_REMOTE_RESOURCE,
  remoteResourceUrl: 'https://api.example.com/data',
  forwardHeaders: true,  // forward request headers to remote
  modifyHeaders: (headers) => [...headers, { name: 'X-Custom', value: '1' }],  // optional
  handleMissingUrl: () => {},  // optional; called on 4xx, then FALLBACK
};
```

- `modifyHeaders`: receives `{ name, value }[]`, returns same shape.
- On 4xx: if `handleMissingUrl` present, calls it and falls back; otherwise fulfills with error.

---

### REDIRECT

```typescript
return {
  action: InterceptHandlerActions.REDIRECT,
  url: 'https://api.example.com/new-path',
  headers: { Authorization: 'Bearer x' },  // optional
  handleMissingUrl: () => {},  // optional
};
```

- Uses `route.fallback(change)` to rewrite URL and headers.

---

### MODIFY_REQUEST

```typescript
return {
  action: InterceptHandlerActions.MODIFY_REQUEST,
  url: 'https://api.example.com/new-path',  // optional
  headers: { 'X-Modified': 'true' },         // optional
  postData: 'modified body',                 // optional
};
```

- Rewrites request via `route.fallback(change)`.

---

### MODIFY_RESOURCE

```typescript
return {
  action: InterceptHandlerActions.MODIFY_RESOURCE,
  status: 201,  // optional, override response status
  modifyBody: (body, { statusCode }) => {
    const json = typeof body === 'object' ? body : JSON.parse(body.toString());
    json.modified = true;
    return json;  // or string (JSON.stringify handled when object)
  },
  modifyHeaders: (headers) => [...headers, { name: 'X-Modified', value: 'true' }],  // optional
};
```

- Fetches original response, then applies `modifyBody` / `modifyHeaders`.
- `body` type: `Buffer | string | object` depending on `content-type` (JSON → object, text → string, else Buffer).

---

### HOLD

```typescript
const deferred = new Promise<void>(resolve => setTimeout(resolve, 5000));
return {
  action: InterceptHandlerActions.HOLD,
  waitUntil: () => deferred,
};
```

- Awaits `waitUntil()` before continuing (`route.continue()`).

---

### ASYNC_INTERCEPT

```typescript
return {
  action: InterceptHandlerActions.ASYNC_INTERCEPT,
  asyncResult: async () => {
    const data = await fetchFromSomewhere();
    return data.shouldMock
      ? { action: InterceptHandlerActions.INJECT_RESOURCE, resource: Buffer.from(...) }
      : { action: InterceptHandlerActions.CONTINUE };
  },
};
```

- Awaits `asyncResult()` and then runs the returned `InterceptionResult`.

---

## 4. Ordering and Pattern Matching

### Handler Order (LIFO)

Playwright’s route handlers run in reverse registration order. Last registered runs first, then fallback goes backward.

- `setup([A, B, C])` registers A, B, C → C runs first, then B, then A on fallback.
- Built-in order (in `interceptors.init.ts`): user interceptors → staticOverride → artifactOverride → sentry → panorama → biInterceptor. Last in this list runs first.

**Conclusion: LIFO — last interceptor in the array gets first chance.**

### Pattern Matching

- **String**: Playwright glob (`**/*`, `**/api/**`, `*://**/*`, etc.).
- **RegExp**: Matches URL.
- **Default**: `'**/*'` if `pattern` is omitted.
- Patterns are passed directly to `context.route()`.

### Multiple Matching Handlers

When several patterns match, the last registered handler for that request runs first. It can `CONTINUE`/`FALLBACK` to the previous one, or handle the request (fulfill, abort, etc.).

---

## 5. Setup Methods

### interceptionPipeline.setup(interceptors)

```typescript
await interceptionPipeline.setup([
  { pattern: '**/api/**', handler: ({ url }) => ({ action: InterceptHandlerActions.CONTINUE }) },
]);
```

- Appends to `interceptionPipeline.interceptors`.
- Registers each with `context.route()`.

### interceptionPipeline.interceptors.push(handler)

```typescript
interceptionPipeline.interceptors.push({
  id: 'MyInterceptor',
  pattern: 'https://api.example.com/*',
  handler: ({ url }) => ({ action: InterceptHandlerActions.ABORT }),
});
```

**Critical:** `push()` only mutates the internal array. It does **not** call `context.route()` — no new route is registered. Handlers added via `push()` alone will **not** intercept requests.

To add interceptors at test runtime, use `setup()` (it appends, does not replace):

```typescript
await interceptionPipeline.setup([
  { pattern: '**/new-api/**', handler: () => ({ action: InterceptHandlerActions.ABORT }) },
]);
```

The `base.md` example showing `push()` before `page.goto()` is misleading; use `setup()` for runtime additions.

### test.use({ interceptors })

```typescript
test.use({
  interceptors: [
    { pattern: '**/api/**', handler: ({ url }) => ({ action: InterceptHandlerActions.CONTINUE }) },
  ],
});
```

- Injected at context init; they are first in the built-in list, so they run last in the chain.

---

## 6. Reports API

### interceptionPipeline.reports

```typescript
interceptionPipeline.reports: InterceptionReport[]
```

- Read-only array, populated for fulfill/rewrite when `shouldReport` is true.

### InterceptionReport

```typescript
interface InterceptionReport {
  action: 'rewrite' | 'fulfill' | 'abort' | 'fallback' | 'continue';
  interceptedRequest: string;  // URL
  change: {
    contentType?: string;
    method?: string;
    url?: string;
    path?: string;
    status?: number;
  };
  interceptBy: {
    pattern: string;  // string form of pattern (regex → "/source/flags")
    id?: string;
  };
}
```

### Asserting on Intercepted Requests

```typescript
// By interceptor id
const sentryCalls = interceptionPipeline.reports.filter(
  (r) => r.interceptBy.id === 'SentryInterceptor'
);

// By URL
const apiCalls = interceptionPipeline.reports.filter(
  (r) => r.interceptedRequest.includes('/api/')
);

// Check if any were intercepted
expect(interceptionPipeline.reports.some(
  (r) => r.interceptBy.id === 'MyInterceptor'
)).toBeTruthy();
```

**Source:** `packages/playwright/src/fixtures/base/classes/interceptionPipeline/interceptionPipeline.types.ts`, `InterceptionPipeline.ts`

---

## 7. Undocumented / Partially Documented Features

| Feature | Status | Notes |
|--------|--------|------|
| `resource: () => Promise<Buffer>` for INJECT_RESOURCE | Supported, under-documented | Used in site-scannerV2 `setupLocalhostProxy.ts` |
| `responsePhrase` for INJECT_RESOURCE | In types, not implemented | `executeAction` does not pass `statusText` to `fulfill` |
| HOLD | Documented in `wix-docs/api/interceptors/index.md` | Not in interception-pipeline.md |
| ASYNC_INTERCEPT | Documented in `wix-docs/api/interceptors/index.md` | Not in interception-pipeline.md |
| `modifyHeaders` signature | `(headers: {name,value}[]) => {name,value}[]` | ResponseHeaders type |

---

## 8. Best Real-World Examples

### 1. site-scannerV2 — Async INJECT_RESOURCE (Localhost Proxy)

```typescript
// packages/rules-catalog-client/e2e/fixtures/setupLocalhostProxy.ts
await interceptionPipeline.setup([{
  id: 'cdn-chunk-proxy',
  pattern: '**/*',
  handler({ url, method, headers }) {
    const chunkMatch = url.match(/static\.parastorage\.com\/...\/(.+\.chunk\.js)$/);
    if (chunkMatch) {
      return {
        action: InterceptHandlerActions.INJECT_RESOURCE,
        resource: async () => {
          const response = await fetch(`http://localhost:3200/${chunkMatch[1]}`, { method, headers });
          return Buffer.from(await response.arrayBuffer());
        },
      };
    }
    return { action: InterceptHandlerActions.CONTINUE };
  },
}]);
```

### 2. premium-testing — MODIFY_RESOURCE (Rate Limit Detection)

```typescript
// packages/domains-testing-purchase-flow/.../domainPurchaseExample.e2e.ts
await interceptionPipeline.setup([{
  id: 'rate-limit-interceptor',
  pattern: '**/_serverless/premium-domains-serverless/**',
  handler() {
    return {
      action: InterceptHandlerActions.MODIFY_RESOURCE,
      modifyBody: (body, { statusCode }) => {
        if (statusCode === 429) rateLimitDetected = true;
        return body;
      },
    };
  },
}]);
```

### 3. appTokens (sled-playwright) — MODIFY_RESOURCE (Token Extraction)

```typescript
// packages/playwright/src/fixtures/features/appTokens/appTokens.init.ts
await interceptionPipeline.setup([{
  id: 'LiveSiteAccessTokensHandler',
  pattern: '**/_api/v1/access-tokens',
  handler: (params) => ({
    action: InterceptHandlerActions.MODIFY_RESOURCE,
    modifyBody: (body) => {
      const tokens = body.apps;
      // ... resolve promise with tokens
      return body;
    },
  }),
}]);
```

### 4. crm-financial-falcon — ABORT + Request Tracking

```typescript
// packages/price-quotes-web/e2e/PriceQuotePreview.spec.ts
const apiCalls: { method: string; url: string }[] = [];
await interceptionPipeline.setup([{
  pattern: /https:\/\/manage\.wix\.com\/wix-quotes-web\/api\/.*create-invoice/,
  handler: ({ url, method }) => {
    apiCalls.push({ method, url });
    return { action: InterceptHandlerActions.ABORT };
  },
}]);
```

---

## 9. Gaps and Discrepancies

| Item | Issue |
|------|-------|
| `responsePhrase` | In `InterceptionResult` but not used in `executeAction`; Playwright `fulfill` supports `statusText`. |
| `interceptors.push()` | Adds to array but does not register new routes. Registration happens in `setup()`. |
| Pattern `(url) => boolean` | Playwright supports it, but `InterceptHandler.pattern` is typed as `RegExp | string` only. |
| `interception-pipeline.md` | Missing HOLD and ASYNC_INTERCEPT; `index.md` has them. |

---

## 10. Quick Reference

| Action | Required Fields | Optional |
|--------|-----------------|----------|
| CONTINUE | `action` | — |
| FALLBACK | `action` | — |
| ABORT | `action` | — |
| EMPTY_RESPONSE | `action` | — |
| INJECT_RESOURCE | `action`, `resource` | `responseCode`, `responseHeaders`, `responsePhrase` (unused) |
| INJECT_REMOTE_RESOURCE | `action`, `remoteResourceUrl`, `forwardHeaders` | `modifyHeaders`, `handleMissingUrl` |
| REDIRECT | `action`, `url` | `headers`, `handleMissingUrl` |
| MODIFY_REQUEST | `action` | `url`, `headers`, `postData` |
| MODIFY_RESOURCE | `action` | `status`, `modifyBody`, `modifyHeaders` |
| HOLD | `action`, `waitUntil` | — |
| ASYNC_INTERCEPT | `action`, `asyncResult` | — |

---

<tldr>
- **InterceptionPipeline API** is fully documented from source: types, actions, reports, and ordering.
- **Gaps:** `responsePhrase` in INJECT_RESOURCE is not implemented; `interceptors.push()` does not register routes by itself.
- **Ordering:** LIFO; last registered handler runs first.
- **Patterns:** string (glob) and RegExp via Playwright; default `'**/*'`.
- **Async:** `resource: () => Promise<Buffer>` and `ASYNC_INTERCEPT` are supported and used in real projects.
</tldr>
