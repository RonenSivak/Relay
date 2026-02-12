# Sled 3 Built-in Fixtures

Complete API reference for all fixtures available in `@wix/sled-playwright`. Source-verified from `wix-private/sled-playwright` TypeScript types.

## Import

```typescript
import { test, expect } from '@wix/sled-playwright';
// All fixtures available via destructuring in test callbacks:
test('example', async ({ page, auth, site, experiments, setExperiments,
  interceptionPipeline, biSpy, urlBuilder, memoize, file, getAppToken,
  daos, createWixContext, helper, lighthouse }) => { ... });
```

## Fixture Type

```typescript
export type Fixtures = Parameters<Parameters<typeof test>[2]>[0];
```

---

## `auth` — Authentication

Manages Wix user login for tests. Memoized — repeated calls with same email reuse the session.

| Method | Signature | Description |
|--------|-----------|-------------|
| `loginAsUser` | `(email: string): Promise<void>` | Login as a Wix user by email. No options parameter. |
| `loginAsMember` | `(siteUrl: string, memberEmail: string): Promise<void>` | Login as a site member. Takes site URL + member email (NOT an options object). |
| `loginAsDisposableMemberToSite` | `(siteUrl: string, memberEmail?: string, referral?: string): Promise<{ email: string; cookies: string[] }>` | Create disposable member. Optional email and referral. |

**NOTE:** `loginAsOwner` does NOT exist. Use `loginAsUser` with the site owner's email.

**Example:**
```typescript
test('dashboard loads', async ({ page, auth }) => {
  await auth.loginAsUser('test-user@wix.com');
  await page.goto('https://manage.wix.com/dashboard/MSID/home');
  await expect(page.getByRole('heading', { name: 'Welcome' })).toBeVisible();
});
```

---

## `site` — Site Management

| Method | Signature | Description |
|--------|-----------|-------------|
| `assignPremiumToSite` | `(metaSiteId: string): Promise<void>` | Assign premium plan to a site |
| `cloneSiteAndReturnOwnerToken` | `(params: { sourceMetaSiteId: string; userEmail?: string; publish?: boolean }, handler: (wixContext, result) => Promise<void>): Promise<void>` | Clone a site and execute test with owner token |

**Example:**
```typescript
test('premium feature', async ({ site, page, auth }) => {
  await auth.loginAsUser('owner@wix.com');
  await site.assignPremiumToSite('meta-site-id');
  // Test premium features...
});
```

---

## `experiments` + `setExperiments` — Experiment Control

**IMPORTANT:** The fixture names are `experiments` and `setExperiments` — NOT `experiment`.

| Fixture | Type | Description |
|---------|------|-------------|
| `experiments` | `ExperimentsMap \| Experiment[]` | Set via `test.use()` or config `globalExperiments` |
| `setExperiments` | `(experiments: ExperimentsMap \| Experiment[], newContext?: BrowserContext): Promise<void>` | Set experiments at runtime, optionally on a new context |

**Static (per describe/file):**
```typescript
test.use({
  experiments: [
    { key: 'specs.my.experiment', val: 'true' },
  ],
});
```

**Dynamic (per test):**
```typescript
test('with experiment', async ({ page, setExperiments }) => {
  await setExperiments([{ key: 'specs.my.feature', val: 'true' }]);
  await page.goto('/my-page');
});
```

---

## `interceptionPipeline` — Network Mocking

See `sled3-interception.md` for the full deep dive.

| Member | Type | Description |
|--------|------|-------------|
| `setup` | `(handlers: InterceptHandler[]): Promise<void>` | Register interceptors. **MUST use this — never `interceptors.push()`** |
| `reports` | `InterceptionReport[]` (getter) | Read-only list of interception reports for assertions |
| `interceptors` | `InterceptHandler[]` | Internal array — do NOT push directly |

**CRITICAL:** `interceptors.push()` only mutates the array — it does NOT call `context.route()` to register handlers. Always use `setup()`.

---

## `biSpy` — BI Event Tracking

Extends `EventsCollection`. Tracks Business Intelligence events during tests.

| Method | Signature | Description |
|--------|-----------|-------------|
| `bySrc` | `(src: number): EventsCollection` | Filter by source ID |
| `byEvid` | `(evid: number): EventsCollection` | Filter by event ID |
| `byFields` | `(fields: Partial<Fields>): EventsCollection` | Filter by field values |
| `first` | `(): BiEvent` | Get first matching event |
| `last` | `(): BiEvent` | Get last matching event |
| `all` | `(): BiEvent[]` | Get all matching events |
| `count` | `(): number` | Count matching events |
| `reset` | `(): void` | Clear all tracked events |

**Example:**
```typescript
test('tracks BI on click', async ({ page, biSpy }) => {
  await page.getByRole('button', { name: 'Submit' }).click();
  const event = biSpy.byEvid(123).first();
  expect(event).toBeDefined();
  expect(event.fields.buttonName).toBe('submit');
});
```

---

## `urlBuilder` — URL Construction

Returns a **factory function** `() => UrlBuilder` — call it to get a builder instance.

| Method | Signature | Description |
|--------|-----------|-------------|
| `url` | `(inputUrl: string): this` | Set base URL |
| `withQueryParam` | `(key: string, value: unknown): this` | Add query parameter |
| `withQueryParams` | `(params: QueryOptions): this` | Add multiple query parameters |
| `withExperiment` | `(name: string, value: unknown): this` | Add experiment override |
| `build` | `(): string` | Build final URL string |
| `clone` | `(): UrlBuilder` | Clone current builder |
| `getUrlConfig` | `(): URLConfig` | Get URL configuration object |

Additional helpers: `withUnpublishedExperimentOn`, `withUnpublishedExperimentOff`, `withViewerScriptOverride`, `withWidgetUrlOverride`, `withControllerUrlOverride`, `withForceThunderbolt`, `withShowMobileView`.

**Example:**
```typescript
test('load with experiments', async ({ page, urlBuilder }) => {
  const url = urlBuilder()
    .url('https://manage.wix.com/dashboard/MSID/home')
    .withExperiment('specs.my.feature', 'true')
    .withQueryParam('debug', 'true')
    .build();
  await page.goto(url);
});
```

---

## `memoize` — Cross-Worker Caching

Caches expensive async operations across workers. Useful for setup that all workers need.

```typescript
memoize<TArgs extends unknown[], TResult>(
  fn: (...args: TArgs) => Promise<TResult>,
  options: {
    key: string;              // Cache key (required)
    ttl?: number;             // Time to live in ms
    timeout?: number;         // Max wait time in ms
    keyResolver?: (...args: TArgs) => string;  // Dynamic key from args
  }
): (...args: TArgs) => Promise<TResult>
```

**Example:**
```typescript
test('with cached setup', async ({ memoize, page }) => {
  const getConfig = memoize(
    async () => {
      // Expensive operation — cached across workers
      return fetchRemoteConfig();
    },
    { key: 'remote-config', ttl: 60000 }
  );
  const config = await getConfig();
});
```

---

## `file` — File Deployment

| Method | Signature | Description |
|--------|-----------|-------------|
| `deployCachedFile` | `({ content: string, extension: 'html' \| 'js' }): Promise<string>` | Deploy a cached file, returns URL |
| `bundleWixCodeApp` | `(files: Record<string, string>, wrapper: (bundles) => string, options?: BundlerOptions): Promise<string>` | Bundle and deploy Wix Code app |
| `deployWixPlatformApp` | `(functions, buildViewerApp, babelOptions?, additionalCacheDeps?): Promise<string>` | Deploy Wix Platform app |

---

## `getAppToken` — App Tokens

```typescript
getAppToken: (appId: string) => Promise<string | undefined>
```

**NOTE:** The fixture is `getAppToken` (a function), NOT `appTokens` (object).

---

## `daos` — Data Access Object Storage

Record and replay test state for faster test reruns.

| Method | Signature | Description |
|--------|-----------|-------------|
| `record` | `(state: string, updateMode?: 'full' \| 'minimal'): Promise<void>` | Record current state |
| `replay` | `(state: string): Promise<void>` | Replay recorded state |

---

## `createWixContext` — New Browser Context

```typescript
createWixContext: () => Promise<WixContext>
```

Returns a new `WixContext` with its own: `context`, `page`, `auth`, `daos`, `getAppToken`, `interceptionPipeline`, `biSpy`, `site`. Useful for multi-tab or multi-user scenarios.

---

## `helper` — Test Utilities

| Method | Signature | Description |
|--------|-----------|-------------|
| `eval` | `(jsCode: string): Promise<unknown>` | Evaluate JavaScript in the browser |
| `currentTestName` | `(): void` | Log current test name |
| `currentSpecFile` | `(): void` | Log current spec file |
| `findPageByUrl` | `(url: string): Page \| undefined` | Find an open page by URL |
| `getAllPages` | `(): Page[]` | Get all open pages |

---

## `lighthouse` — Performance Audits

| Fixture | Type | Description |
|---------|------|-------------|
| `lighthouseConfig` | `Config` | Lighthouse configuration |
| `lighthouse` | `LighthouseUserFlow` | Lighthouse user flow for performance auditing |

---

## Custom Fixtures

Extend the base test with custom fixtures:

```typescript
import { test as base } from '@wix/sled-playwright';

export const test = base.extend<{
  dashboardPage: Page;
}>({
  dashboardPage: async ({ page, auth }, use) => {
    await auth.loginAsUser('test@wix.com');
    await page.goto('https://manage.wix.com/dashboard/MSID/home');
    await use(page);
  },
});
```

### Auto fixtures (run automatically):
```typescript
export const test = base.extend<{
  localhostProxy: void;
}>({
  localhostProxy: [
    async ({ interceptionPipeline }, use) => {
      await interceptionPipeline.setup([proxyHandler]);
      await use();
    },
    { auto: true, scope: 'test' },
  ],
});
```

### Worker-scoped fixtures:
```typescript
type WorkerFixtures = { testUser: string };
export const test = base.extend<{}, WorkerFixtures>({
  testUser: ['default@wix.com', { scope: 'worker', option: true }],
});
```

### Factory pattern (from wix-payments):
```typescript
export const createTest = (createSetup) => {
  return base.extend({
    sledSetup: async ({ page, auth, interceptionPipeline, site }, use) => {
      await use(createSetup({ page, auth, interceptionPipeline, site }));
    },
  });
};
```
