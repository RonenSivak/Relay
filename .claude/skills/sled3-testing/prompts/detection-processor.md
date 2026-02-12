# Detection Processor Prompt

You are detecting Sled 3 E2E testing infrastructure in a Wix project.

## Your Task

Analyze the project at `{PACKAGE_PATH}` and produce a structured detection report.

## What to Detect

### Infrastructure
- [ ] `@wix/sled-playwright` in `package.json` dependencies or devDependencies (version?)
- [ ] `@playwright/test` version (must match Sled server version)
- [ ] `playwright.config.ts` exists? Uses `defineSledConfig()`?
- [ ] `@wix/playwright-storybook-plugin` in dependencies?
- [ ] Yoshi flow type: check `package.json` -> `wix.framework.type` or `@wix/yoshi-flow-*` in devDependencies
- [ ] Test directory location (e.g., `e2e/`, `__e2e__/`, `sled/`, `sled3_tests/`)
- [ ] `postPublish` script in package.json?

### Existing Patterns
- [ ] Existing test files (`.spec.ts`, `.sled3.spec.ts`, `.e2e.ts`) — count and list
- [ ] Existing driver files (`.driver.ts`) — BDD pattern in use?
- [ ] Existing builder files (`.builder.ts`) — mock data factories?
- [ ] Custom fixtures file (`fixtures.ts`, `fixtures/index.ts`)?
- [ ] Constants file (`constants.ts`) — BASE_URL, test users?
- [ ] Catch-all API blocking in place? Grep for `ABORT` in driver files

### Storybook
- [ ] `.storybook/` directory exists?
- [ ] `storybook-static/` directory exists?
- [ ] `storybookPlugin` in `playwright.config.ts`?
- [ ] `storiesToIgnoreRegex` value (check for `['.*']` which disables all tests)
- [ ] Story files (`.stories.tsx`) — count

### Configuration Details
- [ ] `artifactId` value
- [ ] `artifactsOverridePolicy` value
- [ ] `testIdAttribute` (should be `'data-hook'` for Wix)
- [ ] Timeout values
- [ ] Projects configuration (multi-project setup?)
- [ ] Global experiments

## Tools to Use

- `Read` — package.json, playwright.config.ts, existing test files
- `Glob` — find test files, driver files, story files
- `Grep` — search for patterns (ABORT, InterceptHandlerActions, defineSledConfig)

## Output Format

Return a JSON report:

```json
{
  "framework": "sled3" | "sled2" | "playwright" | "none",
  "sledVersion": "1.x.x",
  "playwrightVersion": "1.x.x",
  "yoshiFlow": "flow-bm" | "flow-editor" | "fullstack" | "none",
  "configFile": "playwright.config.ts" | null,
  "testDir": "e2e/" | null,
  "existingTests": { "count": 0, "files": [] },
  "existingDrivers": { "count": 0, "files": [], "hasBDDPattern": false },
  "existingBuilders": { "count": 0, "files": [] },
  "hasCustomFixtures": false,
  "hasCatchAllBlocking": false,
  "storybook": {
    "hasStorybook": false,
    "hasPlugin": false,
    "storiesToIgnoreRegex": null,
    "storyCount": 0,
    "allTestsDisabled": false
  },
  "config": {
    "artifactId": "",
    "artifactsOverridePolicy": "",
    "testIdAttribute": "",
    "timeout": 0,
    "hasProjects": false
  },
  "recommendations": []
}
```

## Self-Review Before Returning

- [ ] Checked package.json for all relevant dependencies
- [ ] Read playwright.config.ts if it exists
- [ ] Counted all test/driver/builder/story files
- [ ] Verified storiesToIgnoreRegex is not `['.*']`
- [ ] Listed specific recommendations based on findings
