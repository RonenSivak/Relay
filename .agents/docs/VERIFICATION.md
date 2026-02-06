# Verification Strategies

The VERIFY gate ensures quality before publishing. This document covers automated validation and when to consult the user.

## Core Principle

**Attempt automated verification first. If uncertain about validation logic, consult user before proceeding.**

## Automated Validation Strategies

### Discover Project Commands First

**Before running any checks, understand the project environment:**

1. **Identify package manager/build system**
   - Check for: `package.json`, `pom.xml`, `build.gradle`, `Cargo.toml`, `pyproject.toml`, `Makefile`, etc.
   - Determine tool: npm, yarn, pnpm, maven, gradle, cargo, poetry, make, etc.

2. **Read available scripts**
   - For Node.js: Check `package.json` → `scripts` section
   - For Python: Check `pyproject.toml` or `Makefile`
   - For Java: Check `pom.xml` or `build.gradle` tasks
   - For Rust: Check `Cargo.toml` or `Makefile`

3. **Adapt commands to environment**
   - Don't assume command names
   - Use what's actually defined in the project

**Example discovery process:**
```bash
# Check what's available
cat package.json | grep "scripts" -A 20

# Might find:
"scripts": {
  "test": "vitest",
  "test:unit": "vitest run",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "typecheck": "tsc --noEmit",
  "build": "vite build"
}

# Or might find:
"scripts": {
  "test": "jest",
  "check": "biome check",
  "check:fix": "biome check --apply"
}
```

### Code Changes

Run these checks (using discovered commands):

**Tests**
- Look for: `test`, `test:unit`, `test:integration`, `test:e2e`, `check`, `verify`
- Run all test commands found
- All tests must pass
- If tests fail: fix issue → re-run → repeat until green

**Linters**
- Look for: `lint`, `check`, `format`, `style`, `eslint`, `biome`, `clippy`
- Try auto-fix first if available: `lint:fix`, `format`, `check:fix`, `clippy --fix`
- No linting errors allowed

**Type Checking**
- Look for: `typecheck`, `type-check`, `tsc`, `mypy`, `check`
- Run type checker
- No type errors allowed

**Build Verification**
- Look for: `build`, `compile`, `dist`, `package`
- Build must succeed
- Catches compilation errors before commit

**Example for different environments:**

```bash
# Node.js project
cat package.json    # Discover scripts
npm run test       # Or yarn test, pnpm test, bun test
npm run lint
npm run typecheck
npm run build

# Python project
cat pyproject.toml  # Check for tool.poetry.scripts or similar
poetry run pytest   # Or: python -m pytest
poetry run mypy .
poetry run ruff check

# Rust project
cat Cargo.toml      # Check for workspace commands
cargo test
cargo clippy
cargo build

# Java project
cat pom.xml         # Check for maven goals
mvn test
mvn checkstyle:check
mvn compile
```

### Documentation Changes

**Checklist for docs:**
- [ ] All links valid (no 404s)
- [ ] Code examples run successfully (actually execute them!)
- [ ] Spelling and grammar checked
- [ ] Follows project style guide
- [ ] Cross-references accurate

### Configuration Changes

**Extra caution needed:**
- Validate syntax (JSON, YAML, TOML, XML, etc.)
- Check references to files/keys exist
- If changes affect CI/CD: verify pipeline still works
- Consider impact on other developers

## Verification Checklist Template

Copy this checklist and check off items as you complete them:

```markdown
Verification Progress:
- [ ] Discovered project commands (checked package.json/build files)
- [ ] Automated checks passed (tests, linters, type check, build)
- [ ] Manual review complete (code quality, edge cases)
- [ ] Documentation updated (if needed)
- [ ] No breaking changes introduced (or documented)
- [ ] Output matches requirements
- [ ] User consulted on uncertain validation logic (if applicable)
```

## The Uncertainty Escape Hatch

**When validation logic is unclear, consult the user BEFORE proceeding.**

### Signs You Should Ask

- **Ambiguous requirements**: "Should error messages be user-facing or technical?"
- **Multiple valid approaches**: "I validated the happy path, but should I test error scenarios too?"
- **Edge cases unclear**: "The code handles empty input, but what about null vs undefined?"
- **Risk assessment needed**: "This changes authentication logic. Is manual testing required?"
- **Incomplete context**: "Tests pass but I'm not sure if this covers the security requirement you mentioned"
- **Unknown commands**: "I found `npm run test` but also `npm run test:ci`. Which should I run?"

### How to Ask

**Bad (vague)**:
```
"Does this look right?"
"Is the validation good?"
```

**Good (specific)**:
```
"I've verified the button renders and handles clicks correctly. Should I also test
keyboard navigation (Enter/Space keys) for accessibility?"

"Tests pass for standard user roles (admin, user). Should I add tests for the
'moderator' role or is existing coverage sufficient?"

"I found both 'npm run test' and 'npm run test:integration' in package.json.
Should I run both or is 'test' sufficient for this change?"
```

Be specific about:
- What you DID validate
- What you're UNCERTAIN about
- What OPTIONS exist

## Plan-Validate-Execute Pattern

For high-risk operations, add an intermediate validation step.

### When to Use
- Batch operations (multiple files/records)
- Destructive changes (deletions, overwrites)
- Complex transformations (data migrations)
- High-stakes operations (production configs, security)

### How It Works

**Standard flow**:
```
Execute → Verify → Publish
```

**Plan-Validate-Execute flow**:
```
Create plan file → Validate plan → Execute → Verify → Publish
```

**Example: Batch file rename**

1. **Create plan**: Generate `rename-plan.json`
   ```json
   [
     {"from": "old-name-1.ts", "to": "new-name-1.ts"},
     {"from": "old-name-2.ts", "to": "new-name-2.ts"}
   ]
   ```

2. **Validate plan**: Run validation script
   ```bash
   # Discover validation command first
   cat package.json  # Look for validate-rename or similar
   npm run validate:rename rename-plan.json
   # Or if no script exists, run script directly:
   node scripts/validate-rename-plan.js rename-plan.json
   ```

3. **Execute**: Apply renames only after validation passes

4. **Verify**: Confirm all files renamed, imports updated, tests pass

## Feedback Loop Pattern

**Pattern**: Run validator → fix errors → repeat until clean

**Example: Code style compliance**
```bash
# First discover the lint command
cat package.json | grep lint

# Then iterate
npm run lint              # ❌ 5 errors found
npm run lint:fix          # Fix 3 automatically (if fix command exists)
# Fix 2 manually
npm run lint              # ✅ Clean

# Only proceed when validation passes
```

**Example: Test-driven fix**
```bash
# Iteration 1
npm test                  # ❌ 2 tests failing
# Fix implementation
npm test                  # ❌ 1 test failing
# Fix edge case
npm test                  # ✅ All pass

# Only proceed when tests green
```

## Verification Decision Tree

```
Discovered project commands?
├─ No → Read package.json/build files → Identify commands
└─ Yes → Did automated checks pass?
    ├─ No → Fix issues → Re-run checks → Repeat
    └─ Yes → Are you certain about validation completeness?
        ├─ No → Consult user with specific question
        └─ Yes → Proceed to Publish
```

## Summary

1. **Discover project commands first** (read package.json, build files, Makefile)
2. **Always attempt automated validation** (tests, linters, type checks, build)
3. **Use feedback loops** (validate → fix → re-validate)
4. **Consult user when uncertain** (be specific about what you're unsure about)
5. **Use plan-validate-execute for high-risk operations**
6. **Only proceed to Publish when verification is complete**
