# Sled 3 Debugging and Troubleshooting

## Debug Modes

### Headed Mode (see the browser)
```bash
CI=false npx sled-playwright test --headed
```

### Debug Mode (Playwright Inspector)
```bash
CI=false npx sled-playwright test --debug
# Or via environment variable:
PWDEBUG=1 CI=false npx sled-playwright test
```
Opens Playwright Inspector for step-through debugging with locator highlighting.

### In-Test Debugging
```typescript
test('debug this', async ({ page }) => {
  await page.pause();  // Opens Playwright Inspector at this point
  
  // Debug screenshots
  await page.screenshot({ path: 'debug.png', fullPage: true });
  
  // Listen to console
  page.on('console', (msg) => console.log(msg.text()));
});
```

### Test Steps (better trace reports)
```typescript
await test.step('Navigate to dashboard', async () => {
  await page.goto('/dashboard');
});

await test.step('Create new item', async () => {
  await page.getByRole('button', { name: 'Create' }).click();
});
```

---

## Trace Viewer

Traces record a full timeline of test execution (screenshots, network, DOM snapshots).

### Enable in Config
```typescript
playwrightConfig: {
  use: {
    trace: 'retain-on-failure',  // Only keep traces for failures
    // Other options: 'on', 'off', 'on-first-retry'
  },
}
```

### View Traces
```bash
npx playwright show-trace trace.zip
```

Trace viewer shows: timeline, screenshots at each action, network requests, DOM snapshots, console logs.

---

## Flakiness Detection

Run before creating PRs to catch flaky tests early.

```bash
# Default: 20 runs per changed test, compare against origin/master
sled-playwright detect-flakiness

# Custom options
sled-playwright detect-flakiness --repeat-count 10
sled-playwright detect-flakiness --base-branch origin/develop
sled-playwright detect-flakiness --path e2e/specific-test.spec.ts
sled-playwright detect-flakiness --test-max-failures 3
```

| Flag | Default | Description |
|------|---------|-------------|
| `--repeat-count` | `20` | Runs per test |
| `--base-branch` | `origin/master` | Branch to diff against |
| `--test-max-failures` | `0` | Stop after N failures (0 = unlimited) |
| `--path` | — | Specific test file |
| `--test-file-suffix` | — | Filter by suffix |

### Preventing Flakiness
1. Never use `page.waitForTimeout()` — use explicit conditions
2. Use Playwright auto-waiting (locators wait automatically)
3. Ensure test isolation (no shared state between tests)
4. Mock all APIs (catch-all blocks unmocked calls)
5. Investigate root cause — don't just retry

---

## Common Issues and Fixes

| Symptom | Root Cause | Fix |
|---------|------------|-----|
| `defineSledConfig()` crash locally | Missing CI environment variables | Prefix with `CI=false` |
| Test timeout | Wrong locator, slow network, missing mock | Check locator exists; add mock for API; increase timeout |
| `Route aborted` / unmocked API | Catch-all blocking a needed endpoint | Add `given.*` mock for that endpoint in driver |
| `intercepted pointer events` | Overlay/modal blocking click target | Wait for overlay to dismiss; use `{ force: true }` as last resort |
| `Couldn't find story matching...` | Stale storybook-static or wrong story ID | Rebuild: `yarn build-storybook`; use export name (kebab-case) |
| Snapshot mismatch | Local vs remote rendering differences | Always run `--remote` for visual tests; update with `--update-snapshots` |
| `storiesToIgnoreRegex: ['.*']` | All visual tests silently disabled | Fix to `['.*--docs$', '.*-playground$']` |
| Auth failure | Wrong email or expired test user | Verify test user email; check user exists in Wix |
| `FAIL_ON_MISSING` error | Statics not published yet | Use `ArtifactsOverridePolicy.DISABLE` for local; keep `FAIL_ON_MISSING` for CI |
| `ECONNREFUSED` on Storybook | Storybook not running on expected port | Check `port` in plugin config; ensure `storybook-static` exists |
| Test passes locally, fails in CI | Environment differences | Use `--remote` flag; check `CI=false` not set in CI |
| Interceptor not matching | Pattern doesn't match URL | Use RegExp for complex patterns; log URL in handler for debugging |

---

## CI/CD Integration

### Remote Execution
Tests run automatically on remote Sled cluster in CI:
```bash
sled-playwright test --remote
```

### Reports
- **PR Comment:** Enabled by default (`github.report.enabled: true`)
- **HTML Report:** `npx sled-playwright show-report` (link in CI output)
- **Sled Dashboard:** Link provided in test output
- **Live Tracker:** `sled-playwright test --live-tracker` for real-time dashboard

### Reruns in CI
- Default: only failed tests rerun
- `--rerun-all`: rerun entire suite
- `retries: 2` in config: auto-retry failed tests up to 2 times

### postPublish Script
```json
{
  "scripts": {
    "postPublish": "sled-playwright test"
  }
}
```
Sled 3 needs published statics on parastorage. Tests run after publish.

### CI Sharding
```bash
sled-playwright ci  # Bundle tests + trigger CI run with sharding
```

---

## Debugging Interception Issues

### Log Intercepted Requests
```typescript
const debugHandler: InterceptHandler = {
  id: 'debug-logger',
  pattern: '**/*',
  handler: ({ url, method }) => {
    console.log(`[INTERCEPT] ${method} ${url}`);
    return { action: InterceptHandlerActions.CONTINUE };
  },
};
```

### Check Reports
```typescript
test.afterEach(async ({ interceptionPipeline }) => {
  const reports = interceptionPipeline.reports;
  console.log('Intercepted:', reports.map(r => `${r.action} ${r.interceptedRequest.url}`));
});
```

### Common Interception Pitfalls
- **LIFO ordering:** Last handler in `setup()` array runs first
- **`interceptors.push()` broken:** Does NOT register routes — use `setup()`
- **Pattern too narrow:** Request hits catch-all instead of specific mock
- **Pattern too broad:** Specific mock intercepts unintended requests

---

## Debug Decision Tree

```
Test failed
├── Exact line + assertion → Fix assertion or code under test
├── Route aborted / ABORT → Missing mock — add given.* for that endpoint
├── "intercepted pointer events" → Overlay blocking → wait/dismiss first
├── Timeout → Check: mocks return data? page loads? locator correct?
├── "Couldn't find story..." → Rebuild storybook; IDs use export names
├── Snapshot mismatch → Run --remote; update with --update-snapshots if intentional
└── Need deeper investigation → Use trace viewer (--trace on) or --debug mode
```
