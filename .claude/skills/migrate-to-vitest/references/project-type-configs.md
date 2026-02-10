# Vitest Configuration Templates by Project Type

All templates extracted from real Wix production repositories. Each section shows the complete before/after.

---

## Pattern 1: Wix Serverless

**Sources:** [wix-serverless/packages/serverless-vitest-config](https://github.com/wix-private/wix-serverless/blob/master/packages/serverless-vitest-config), [wix-serverless/example-apps/esm-example](https://github.com/wix-private/wix-serverless/blob/master/example-apps/esm-example), [cashier-client](https://github.com/wix-private/cashier-client), [viewer-infra](https://github.com/wix-private/viewer-infra), [picasso](https://github.com/wix-private/picasso), [system-dev](https://github.com/wix-private/system-dev)

**How to detect:** `@wix/serverless-jest-config` in devDependencies, or `wix.framework.type === "WIX_SERVERLESS"` in package.json.

### BEFORE

`jest.config.js`:
```javascript
const config = require("@wix/serverless-jest-config");
module.exports = {
  ...config,
  moduleNameMapper: { uuid: require.resolve("uuid") },
  testPathIgnorePatterns: ["/dist/"],
  coveragePathIgnorePatterns: ["/dist/"],
  collectCoverageFrom: ["src/**/*.{ts,tsx}", "!src/**/*.spec.{ts,tsx}"],
};
```

`package.json` (relevant parts):
```json
{
  "scripts": {
    "test": "jest --runInBand --forceExit --verbose"
  },
  "devDependencies": {
    "@wix/serverless-jest-config": "^2.0.7",
    "@wix/serverless-testkit": "^1.1169.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.4.1",
    "jest-standard-reporter": "^2.0.0",
    "jest-teamcity-reporter": "^0.9.0"
  }
}
```

What `@wix/serverless-jest-config` v2.0.9 provides:
- `testEnvironment: 'node'`
- `preset: 'ts-jest'`
- `coverageProvider: 'v8'`
- `testRunner: 'jest-circus/runner'`
- `testTimeout: 240000` (4 minutes)
- `maxWorkers: 7`
- `reporters: ['jest-standard-reporter']`
- `testResultsProcessor: 'jest-teamcity-reporter'`
- `sandboxInjectedGlobals: ['Math', 'Array', 'Object', 'Function']`
- `slowTestThreshold: 60`
- `testMatch: ['**/?(*.)+(spec|test).[jt]s?(x)']`

### AFTER

`vitest.config.ts` (simple case):
```typescript
export { default } from '@wix/serverless-vitest-config';
```

`vitest.config.ts` (with customization):
```typescript
import { mergeConfig } from 'vitest/config';
import baseConfig from '@wix/serverless-vitest-config';

export default mergeConfig(baseConfig, {
  test: {
    exclude: ['**/dist/**'],
  },
});
```

`package.json` (relevant parts):
```json
{
  "type": "module",
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@wix/serverless-vitest-config": "^1.0.3",
    "@wix/serverless-testkit": "^1.1268.0",
    "@vitest/coverage-v8": "^3.2.4",
    "vitest": "^3.2.4",
    "vitest-teamcity-reporter": "^0.3.1"
  }
}
```

What `@wix/serverless-vitest-config` v1.0.3 provides:
- `environment: 'node'`
- `include: ['**/?(*.)+(spec|test).[jt]s?(x)', '**/?(*.)+(spec|test).m[jt]s']`
- `testTimeout: 240000` (4 minutes, matches jest)
- `hookTimeout: 120000` (2 minutes)
- `pool: 'threads'`
- `poolOptions: { threads: { maxThreads: 7, minThreads: 1 } }`
- `reporters: process.env.CI ? ['vitest-teamcity-reporter'] : []`
- `globals: true`
- `slowTestThreshold: 60000`

### Migration checklist

1. `yarn add -D @wix/serverless-vitest-config vitest @vitest/coverage-v8 vitest-teamcity-reporter`
2. Create `vitest.config.ts`
3. Add `"type": "module"` to package.json
4. Update scripts: `"test": "vitest run"`, add `"test:watch": "vitest"`
5. Remove: `@wix/serverless-jest-config`, `jest`, `ts-jest`, `jest-standard-reporter`, `jest-teamcity-reporter`
6. Delete `jest.config.js`
7. Transform test files: `jest.*` -> `vi.*`
8. `@wix/serverless-testkit` -- NO changes needed

### What becomes unnecessary

- `ts-jest` -- vitest handles TypeScript natively via esbuild
- `moduleNameMapper: { uuid: require.resolve("uuid") }` -- vitest handles ESM exports
- `--runInBand --forceExit` flags -- vitest thread pool handles this
- `jest-circus/runner` -- vitest has its own runner
- `sandboxInjectedGlobals` -- vitest has different isolation model

---

## Pattern 2: React/BM/UI Project (yoshi-flow-bm, editor-flow)

**Sources:** [wix-private/dev-portal](https://github.com/wix-private/dev-portal) (Next.js), [wix-private/wix-payments](https://github.com/wix-private/wix-payments) (React monorepo)

**How to detect:** `jest-yoshi-preset` or `@wix/jest-yoshi-preset-base` in devDependencies, or `yoshi-flow-bm`/`yoshi-flow-editor` in dependencies.

### BEFORE

`jest.config.js` (typical yoshi project):
```javascript
module.exports = {
  preset: 'jest-yoshi-preset',
};
```

Or in package.json:
```json
{
  "jest": {
    "preset": "jest-yoshi-preset"
  }
}
```

What `jest-yoshi-preset-base` provides (two Jest projects):
- **jsdom project**: `testEnvironment: 'jsdom'`, unit test globs, svg/css module mappers, spec-setup detection
- **node project**: `testEnvironment: 'node'`, server test globs, e2e-setup detection
- Both: `ts-jest` transform, `regenerator-runtime`, TypeScript path mapping, CI reporters

### AFTER (from dev-portal)

`vitest.config.ts`:
```typescript
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import tsconfigPaths from 'vite-tsconfig-paths';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [
    react(),
    svgr({ exportAsDefault: true }),
    tsconfigPaths({ root: '.' }),
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['__tests__/spec-setup.ts'],
    css: true,
    include: ['src/**/*.spec.{ts,tsx}'],
    reporters: process.env.CI ? ['vitest-teamcity-reporter'] : [],
  },
  resolve: {
    mainFields: ['module'],
  },
});
```

### AFTER (from wix-payments)

`vite.config.mts`:
```typescript
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { nodePolyfills } from 'vite-plugin-node-polyfills';
import svgr from 'vite-plugin-svgr';

export default defineConfig({
  assetsInclude: ['**/*.html'],
  plugins: [
    nodePolyfills({ include: ['crypto'] }),
    react(),
    svgr({ include: '**/*.svg' }),
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/__tests__/spec-setup.ts',
    include: ['src/**/*.spec.{ts,tsx}'],
  },
});
```

### Abstracted template

```typescript
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [
    react(),
    svgr({ include: '**/*.svg' }),
    // Add tsconfigPaths({ root: '.' }) if project has tsconfig paths
    // Add nodePolyfills({ include: ['crypto'] }) if project uses Node builtins in browser
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./path/to/spec-setup.ts'],
    css: true,
    include: ['src/**/*.spec.{ts,tsx}'],
    reporters: process.env.CI ? ['vitest-teamcity-reporter'] : [],
  },
});
```

### Dependencies to install

```
vitest @vitejs/plugin-react vite-plugin-svgr @vitest/coverage-v8 vitest-teamcity-reporter jsdom
```

Optional (based on project needs):
- `vite-tsconfig-paths` -- if project uses TypeScript path aliases
- `vite-plugin-node-polyfills` -- if project uses Node.js builtins (crypto, buffer, etc.)

### Dependencies to remove

```
jest-yoshi-preset @wix/jest-yoshi-preset-base jest ts-jest jest-environment-jsdom
```

---

## Pattern 3: FED CLI Project

**Sources:** [wix-private/fed-cli/packages/fed-cli-vitest](https://github.com/wix-private/fed-cli/tree/HEAD/packages/fed-cli-vitest)

**How to detect:** `@wix/fed-cli-vitest` already in devDependencies, or `@wix/fed-cli` toolchain in use.

### AFTER

`vitest.config.ts`:
```typescript
import { mergeConfig } from 'vitest/config';
import fedConfig from '@wix/fed-cli-vitest/vitest.config.js';

export default mergeConfig(fedConfig.configs.recommended, {
  // Project-specific overrides
});
```

What `@wix/fed-cli-vitest` recommended config provides:
- `environment: 'jsdom'`
- `exclude: ['node_modules', 'dist', '**/e2e/**']`

### Dependencies to install

```
vitest @wix/fed-cli-vitest @vitest/coverage-v8
```

Note: FED CLI projects are already designed for Vitest -- this is the natural migration path from yoshi.

---

## Pattern 4: Standalone Jest Project

**How to detect:** Has `jest` in devDependencies but none of the Wix-specific configs above.

### AFTER (Node.js project)

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['**/*.spec.{ts,js}', '**/*.test.{ts,js}'],
    coverage: {
      provider: 'v8',
      reporter: ['html', 'text'],
    },
  },
});
```

### AFTER (React project without Wix presets)

```typescript
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['src/**/*.spec.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['html', 'text'],
    },
  },
});
```

### Dependencies to install

Node.js: `vitest @vitest/coverage-v8`
React: `vitest @vitejs/plugin-react @vitest/coverage-v8 jsdom`
