# BI Logger Setup & Installation

How to select, install, and verify bi-schema-logger packages.

## Logger Selection

### From Event Schema

The `schemaLoggers` array in the event schema lists available logger packages. Each name (e.g., `bi-logger-data-product`) maps to npm package `@wix/bi-logger-data-product`.

### Selection Rules

| Scenario | Action |
|----------|--------|
| One logger available | Use it |
| Multiple loggers, one already installed | Reuse installed one |
| Multiple loggers, none installed | Use first in array |
| User has preference | Ask them to choose |

## Installation

### Check Current State

```bash
# Check if already installed
grep "@wix/bi-logger" package.json

# Check installed version
yarn info @wix/[logger-name] version
```

### Install

```bash
# Using yarn
yarn add @wix/[logger-name]

# Using npm
npm install @wix/[logger-name]
```

### Update to Latest

```bash
# Check latest available
npm view @wix/[logger-name] version

# Update
yarn up @wix/[logger-name]
```

## Verification

### Validate Function Exists

```bash
# Check package types for the function
grep -r "${functionName}" node_modules/@wix/${loggerPkg}/dist/types/
```

### Validate Package Structure

```bash
# Check available type definitions
find node_modules/@wix/${loggerPkg} -name "*.d.ts" | head -5
```

### If Function Not Found

1. Update package to latest: `yarn up @wix/${loggerPkg}`
2. Check for typos in function name
3. Verify evid/src mapping in BI Catalog
4. Use placeholder with TODO comment as fallback

## Package Naming Convention

All BI schema logger packages follow: `@wix/bi-logger-*`

Examples:
- `@wix/bi-logger-menus`
- `@wix/bi-logger-data-tools`
- `@wix/bi-logger-data-product`
