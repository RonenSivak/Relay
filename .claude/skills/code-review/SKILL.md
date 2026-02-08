---
name: code-review
description: Systematic code review for PRs and local changes in Wix React/Node.js/TypeScript projects. Analyzes diffs for correctness, security, performance, and maintainability with separate frontend and backend review paths. Integrates with GitHub (read-only), Jira, and Slack. Use when the user says "review", "PR", "pull request", "code review", "check my changes", "review this diff", or "review #123".
---

# Code Review

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before reviewing, invoke `/brainstorming` to clarify:

1. **What's being reviewed?** - PR URL/number, local diff, specific files?
2. **Review focus?** - Full review, security-focused, performance-focused?
3. **Context?** - New feature, bug fix, refactor, config change?
4. **Scope?** - Frontend, backend, or full-stack?

## Core Principles

**Goals of code review:**
- Catch bugs, security issues, and edge cases
- Ensure code maintainability and readability
- Share knowledge across the team
- Enforce project patterns and Wix conventions

**Not the goals:**
- Show off knowledge or rewrite to your preference
- Nitpick formatting (use linters for that)
- Block progress unnecessarily
- Bikeshed on trivial details

## Decision Tree: Which Review Path?

```
What are you reviewing?
│
├─ PR number/URL provided?
│  └─ Fetch PR diff (Step 1A)
│
├─ Local changes?
│  └─ Use git diff (Step 1B)
│
└─ Specific files?
   └─ Read files directly (Step 1C)

Then determine scope:
│
├─ Frontend files? (.tsx, .scss, components/, pages/)
│  └─ Apply: Frontend Review Checklist
│
├─ Backend files? (.ts server, routes, services, DAL)
│  └─ Apply: Backend Review Checklist
│
├─ Serverless files? (app.ts, FunctionsBuilder, Greyhound consumers)
│  └─ Apply: Serverless Review Checklist + Backend Checklist
│
└─ Multiple scopes?
   └─ Apply all relevant checklists, then Full-Stack Checks
```

## Step 1: Gather Context

### 1A: Remote PR

```bash
gh pr view <number>               # PR description, labels, reviewers
gh pr diff <number>               # Full diff
gh pr checks <number>             # CI status
git log --oneline -10             # Recent commits for context
```

**Never comment or commit to GitHub.** All feedback is presented in-IDE only.

### 1B: Local Changes

```bash
git status                        # What files changed?
git diff --stat                   # Change scope
git diff                          # Working tree changes
git diff --staged                 # Staged changes
git log --oneline -5              # Recent commits for context
```

### 1C: Specific Files

Read files directly using tools. Compare with `git diff HEAD -- <file>` if needed.

### Context Enrichment

- **Jira**: If PR references a ticket (e.g., `PROJ-123`), fetch it: `get-issues(jql: "key=PROJ-123")`
- **Slack**: Search for related discussions: `search-messages(searchText: "PROJ-123")`
- **Understand intent**: Read PR description, linked ticket, and commit messages before reviewing code

## Step 2: Understand Before Reviewing

Before line-by-line review, answer:

1. **What is the intent?** Read PR description and linked ticket
2. **What is the scope?** List changed files, identify frontend vs backend
3. **What is the change type?** New feature, bug fix, refactor, config, test
4. **Is the PR size reasonable?** >400 changed lines? Flag it — suggest splitting
5. **Are CI checks passing?** If not, note it upfront

## Step 3: Review Checklists

### Shared Checklist (All Code)

**Correctness**
- [ ] Logic handles expected inputs correctly
- [ ] Edge cases covered (null, empty, boundary values)
- [ ] Error handling is appropriate (not swallowed, not over-caught)
- [ ] Async operations handled correctly (await, error propagation)
- [ ] No off-by-one errors or incorrect comparisons

**Security**
- [ ] No secrets, credentials, or API keys in code
- [ ] User input validated and sanitized
- [ ] No injection vectors (SQL, XSS, SSRF, command injection)
- [ ] Auth checks present where needed
- [ ] Error messages don't leak sensitive information
- [ ] No `eval()` or dynamic code execution

**Maintainability**
- [ ] Code is readable without excessive comments
- [ ] Functions are focused (single responsibility)
- [ ] Naming is clear and consistent
- [ ] No dead code or commented-out blocks
- [ ] DRY — no unnecessary duplication
- [ ] No magic numbers — constants extracted

**Testing**
- [ ] New behavior has corresponding tests
- [ ] Tests cover happy path and error cases
- [ ] Test names describe the behavior being tested
- [ ] No flaky patterns (timing, shared state, order dependency)
- [ ] Tests test behavior, not implementation details

### Frontend Review Checklist

Apply when reviewing `.tsx`, `.scss`, components, pages, hooks, or UI logic.

**React Patterns**
- [ ] Components are focused and composable
- [ ] Props don't mutate — immutable data flow
- [ ] `useEffect` has correct dependency arrays
- [ ] No unnecessary re-renders (memoization where appropriate)
- [ ] Event handlers don't create closures over stale state
- [ ] Keys are stable and unique in lists (not array index for dynamic lists)

**Wix Design System (WDS)**
- [ ] WDS components used instead of custom equivalents
- [ ] Component props match WDS API (check with `/wds-docs` if unsure)
- [ ] Layout uses `<Box>`, `<Cell>`, `<Layout>` — not raw divs for structure
- [ ] Icons from `@wix/wix-ui-icons-common`
- [ ] Theme tokens used for colors/spacing — no hardcoded values

**Accessibility**
- [ ] Interactive elements have accessible labels
- [ ] Color contrast is sufficient
- [ ] Keyboard navigation works
- [ ] ARIA attributes used correctly (not overused)

**i18n**
- [ ] User-facing text uses translation keys, not hardcoded strings
- [ ] New strings added to translation files
- [ ] Pluralization and formatting handled correctly

**Performance (FE)**
- [ ] No large bundles imported unnecessarily (tree-shaking friendly)
- [ ] Images are optimized and lazy-loaded where appropriate
- [ ] Heavy computations memoized or debounced
- [ ] No blocking operations in render path

See `references/frontend-review.md` for detailed patterns and anti-patterns.

### Backend Review Checklist

Apply when reviewing server-side `.ts`, routes, services, DAL, or serverless functions.

**API Design**
- [ ] Endpoints follow REST conventions or match existing patterns
- [ ] Request/response schemas are typed and validated
- [ ] Error responses are consistent and informative
- [ ] Pagination implemented for list endpoints
- [ ] Idempotency considered for write operations

**Data & Queries**
- [ ] No N+1 query patterns
- [ ] Database queries use indexes (check schema if adding new queries)
- [ ] Transactions used where atomicity is required
- [ ] Large data sets paginated or streamed
- [ ] Connection pooling leveraged correctly

**Wix Backend Patterns**
- [ ] Ambassador service calls are properly typed
- [ ] Ambassador mocks follow project patterns (check with `/unit-testing`)
- [ ] Feature flags used for risky rollouts
- [ ] Proper error propagation through RPC boundaries
- [ ] Serverless function signatures match expected patterns

**Security (Backend)**
- [ ] Authentication middleware applied to protected routes
- [ ] Authorization checks before data access (not just route-level)
- [ ] Rate limiting on public endpoints
- [ ] Input validation at the boundary (controller/handler level)
- [ ] Secrets loaded from environment, not hardcoded

**Performance (BE)**
- [ ] No blocking operations in hot paths
- [ ] External calls have timeouts configured
- [ ] Caching used where appropriate (with invalidation strategy)
- [ ] Bulk operations preferred over loops of individual calls

See `references/backend-review.md` for detailed patterns and anti-patterns.

### Serverless Review Checklist

Apply when reviewing `@wix/serverless-api` functions (`app.ts`, `index.ts`, `serverless.ts`), Greyhound consumers, gRPC services, or cron jobs.

**FunctionsBuilder Setup**
- [ ] Entry point exports function receiving `FunctionsBuilder`
- [ ] `withBiInfo` configured for observability
- [ ] `withContextPath` set if custom URL path needed
- [ ] Experiments declared via `addExperiment` with proper `scopes` and `owner`
- [ ] Produced Kafka topics declared with `withKafkaTopic`

**Web Functions**
- [ ] HTTP method matches semantics (GET for reads, POST for writes)
- [ ] `timeoutMillis` explicitly set for long-running operations
- [ ] Input validated at handler boundary (don't trust `req.body` blindly)
- [ ] Errors caught and returned as structured `FullHttpResponse`
- [ ] MetaSiteId resolved securely via `ctx.apiGatewayClient.metaSiteId(ctx.aspects)` — not from user input
- [ ] Authentication/authorization checked where needed

**Greyhound Consumers (Kafka)**
- [ ] Retry policy configured with escalating intervals (e.g., `[5, 30, 300, 3600]`)
- [ ] `enableDlq: true` — dead letter queue for poison messages
- [ ] `timeoutInMillis` set appropriately
- [ ] Handler is **idempotent** (Kafka provides at-least-once delivery)
- [ ] Handler validates message payload (malformed messages happen)

**FunctionContext Usage**
- [ ] Structured logging via `ctx.logger` — not `console.log`
- [ ] Secrets from `ctx.config.get()` — never hardcoded
- [ ] Aspects propagated to downstream ambassador calls
- [ ] Ambassador calls use generated service types (typed, not raw HTTP)

**Testing**
- [ ] Tests use `@wix/serverless-testkit` (`ServerlessTestkit`)
- [ ] Ambassador calls stubbed via `testkit.ambassadorV2` or `testkit.ambassador`
- [ ] Greyhound tested via `testkit.greyhoundTestkit`
- [ ] Config/secrets set via `testkit.setConfig()`
- [ ] Datastore cleared between tests for isolation

See `references/serverless-review.md` for detailed patterns, anti-patterns, and testkit usage.

### Full-Stack Checks (When Both Sides Change)

- [ ] Frontend and backend schemas/types are in sync
- [ ] API contract changes are backward compatible (or versioned)
- [ ] Error states from backend are handled gracefully in UI
- [ ] Loading states shown during async operations
- [ ] Feature flag covers both frontend and backend changes

## Step 4: Review by Change Type

### Bug Fix
1. Does the fix address the **root cause**, not just symptoms?
2. Is there a test that would have caught this bug?
3. Could this fix break existing behavior? Check callers.
4. Are related areas affected by the same bug?

### New Feature
1. Does it match the design/requirements (Jira ticket)?
2. Is the architecture appropriate for the scope?
3. Is it feature-flagged for safe rollout?
4. Are integration points documented or obvious?

### Refactor
1. Is behavior preserved? (Tests still pass, no logic changes)
2. Is the refactor complete or does it leave inconsistencies?
3. Are the abstractions appropriate (not over-engineered)?
4. Does it improve readability and maintainability?

### Configuration / Infrastructure
1. Are changes backward compatible?
2. Are environment-specific values handled correctly?
3. Is documentation updated?

## Step 5: Provide Feedback

### Severity Labels

| Label | Meaning | Blocks merge? |
|-------|---------|---------------|
| **BLOCKER** | Bugs, security issues, data loss risks, breaking changes | Yes |
| **IMPORTANT** | Should fix — better patterns, correctness concerns | Discuss |
| **SUGGESTION** | Alternative approach, improvement opportunity | No |
| **NIT** | Minor style, naming, formatting (optional) | No |
| **PRAISE** | Good work — acknowledge quality, clever solutions, good patterns | No |

### Output Template

```markdown
## Code Review Summary

**Target**: PR #123 / local changes / files
**Change type**: feature / bugfix / refactor / config
**Scope**: frontend / backend / full-stack
**Risk level**: low / medium / high
**Verdict**: approve / request-changes / needs-discussion

---

## What Looks Good
- [Always include positive observations]
- [Acknowledge good patterns, test coverage, clean code]

## Findings

### BLOCKER: [Title]
**File**: `path/to/file.ts:42`
**Issue**: [What's wrong and why it matters]
**Suggestion**: [How to fix, with code example if helpful]

### IMPORTANT: [Title]
**File**: `path/to/file.ts:78`
**Issue**: [What could be better]
**Suggestion**: [Improved approach]

### SUGGESTION: [Title]
**File**: `path/to/file.ts:15`
**Idea**: [Alternative approach to consider]

### NIT: [Title]
**File**: `path/to/file.ts:90`
**Note**: [Minor observation]

### PRAISE: [Title]
**File**: `path/to/file.ts:55`
**Note**: [What was done well and why]

---

## Summary by Severity
- **BLOCKERS**: X findings
- **IMPORTANT**: X findings
- **SUGGESTIONS**: X findings
- **NITS**: X findings

## Questions for Author
- [Clarifications or design questions, if any]
```

### Feedback Tone

- Be constructive, specific, and actionable
- Explain **why** a change is needed, not just what
- Use the question approach for non-blocking items: "What happens if `items` is empty?" instead of "This will fail on empty arrays"
- Always include positive observations — every review should have PRAISE items
- For suggestions, show the better alternative with a code snippet

## Step 6: Integration Actions (Optional)

### Jira

When review reveals a confirmed bug or missing requirement:
1. `get-issues(jql: "key=PROJ-123")` — check existing ticket
2. `comment-on-issue` — add review findings to the ticket
3. `create-issue` — if a new bug is discovered during review

### Slack

- `search-messages` — search for related discussions or context
- Do **not** post review results to Slack automatically

## Tool Reference

**Code Analysis** (octocode):
- `localSearchCode` — find related code, patterns, usages
- `lspFindReferences` — check impact of changes
- `lspCallHierarchy` — trace execution flow

**GitHub** (read-only):
- `gh pr view` / `gh pr diff` — fetch PR details
- `githubSearchPullRequests` — find related PRs

**Jira**: `get-issues`, `comment-on-issue`, `create-issue`
**Slack**: `search-messages`

## Anti-Patterns

| Anti-Pattern | Better Approach |
|-------------|----------------|
| Reviewing without understanding intent | Read PR description and Jira ticket first |
| Line-by-line without big picture | Understand scope and architecture first |
| Only finding problems | Always include PRAISE items |
| Vague feedback ("this is wrong") | Specific: file, line, issue, suggestion, **why** |
| Bikeshedding on style | Focus on correctness, security, performance |
| Rubber-stamping | Every review adds value or explains why it's clean |
| Commenting/committing to GitHub | All feedback stays in IDE output |
| Reviewing >400 lines without flagging | Suggest splitting large PRs |

## References

- `references/frontend-review.md` — React, WDS, TypeScript FE patterns and anti-patterns
- `references/backend-review.md` — Node.js, Ambassador, data layer patterns and anti-patterns
- `references/serverless-review.md` — Wix Serverless: FunctionsBuilder, Greyhound, testkit patterns
