---
name: code-review
description: Systematic code review for PRs and local changes. Analyzes diffs for correctness, security, performance, and maintainability. Uses octocode for code analysis and review-gate for interactive feedback. Triggers on "review", "PR", "pull request", "code review", "check my changes", or "review this diff".
---

# Code Review

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before reviewing, invoke `/brainstorming` to clarify:

1. **What's being reviewed?** - PR URL, local diff, specific files?
2. **Review focus?** - Full review, security-focused, performance-focused?
3. **Context?** - New feature, bug fix, refactor, config change?

## Core Workflow

### Step 1: Gather Context

```
# For local changes
git diff --stat                    → What files changed?
git diff                           → What are the actual changes?
git log --oneline -5               → Recent commits for context

# For PR (GitHub)
gh pr view <number>                → PR description, labels, reviewers
gh pr diff <number>                → Full diff
```

### Step 2: Understand the Change

Before reviewing line-by-line:

1. **Read the PR description** - What's the intent?
2. **Check the file list** - Which areas are affected?
3. **Identify the change type**: New feature, bug fix, refactor, config, test
4. **Understand scope**: Is this a surgical fix or a broad change?

### Step 3: Review with Checklist

Go through each category. Skip categories that don't apply.

**Correctness**
- [ ] Logic handles expected inputs correctly
- [ ] Edge cases covered (null, empty, boundary values)
- [ ] Error handling is appropriate (not swallowed, not over-caught)
- [ ] Async operations handled correctly (await, error propagation)

**Security**
- [ ] No secrets or credentials in code
- [ ] User input validated/sanitized
- [ ] No SQL injection, XSS, or SSRF vectors
- [ ] Auth checks present where needed

**Performance**
- [ ] No N+1 queries or unnecessary loops
- [ ] Large data sets paginated or streamed
- [ ] No blocking operations in hot paths
- [ ] Memoization used where appropriate

**Maintainability**
- [ ] Code is readable without excessive comments
- [ ] Functions are focused (single responsibility)
- [ ] Naming is clear and consistent
- [ ] No dead code or commented-out blocks
- [ ] DRY - no unnecessary duplication

**Testing**
- [ ] New behavior has corresponding tests
- [ ] Tests cover happy path and error cases
- [ ] Test names describe the behavior being tested
- [ ] No flaky patterns (timing, shared state, order dependency)

**Wix-Specific**
- [ ] WDS components used correctly (check with `/wds-docs` if unsure)
- [ ] Ambassador mocks follow project patterns (check with `/js-testing`)
- [ ] Translations/i18n handled if user-facing text changed
- [ ] Feature flags used for risky rollouts

### Step 4: Provide Feedback

Format findings by severity:

- **BLOCKER** - Must fix. Bugs, security issues, data loss risks
- **SUGGESTION** - Should consider. Better patterns, readability, performance
- **NIT** - Optional. Style, minor naming, formatting

**Template:**
```markdown
## Review Summary

**Change type**: [feature/bugfix/refactor/config]
**Risk level**: [low/medium/high]
**Verdict**: [approve/request-changes/needs-discussion]

## Findings

### BLOCKER: [Title]
**File**: `path/to/file.ts:42`
**Issue**: [What's wrong]
**Suggestion**: [How to fix]

### SUGGESTION: [Title]
**File**: `path/to/file.ts:78`
**Current**: [What it does now]
**Better**: [Improved approach]

### NIT: [Title]
**File**: `path/to/file.ts:15`
**Note**: [Minor observation]

## What Looks Good
- [Positive observations - always include some]
```

### Step 5: Interactive Review (Optional)

Use review-gate for back-and-forth discussion:

```
review_gate_chat(
  message: "Review complete. 1 blocker, 2 suggestions. See findings above. Questions?",
  context: "PR #123 review",
  title: "Code Review"
)
```

## Review by Change Type

### Bug Fix Review
Focus on:
1. Does the fix address the root cause (not just symptoms)?
2. Is there a test that would have caught this bug?
3. Could this fix break existing behavior?
4. Are related areas affected by the same bug?

### New Feature Review
Focus on:
1. Does it match the design/requirements?
2. Is the architecture appropriate for the scope?
3. Are there integration points that need attention?
4. Is it feature-flagged for safe rollout?

### Refactor Review
Focus on:
1. Is behavior preserved? (Check tests still pass)
2. Is the refactor complete or does it leave inconsistencies?
3. Are the abstractions appropriate (not over-engineered)?
4. Does it improve or maintain readability?

## Anti-Patterns

| Anti-Pattern | Better Approach |
|-------------|----------------|
| Reviewing without understanding intent | Read PR description first |
| Line-by-line without big picture | Understand scope and architecture first |
| Only finding problems | Always include positive observations |
| Vague feedback ("this is wrong") | Specific: file, line, issue, suggestion |
| Bikeshedding on style | Focus on correctness, security, performance |
| Rubber-stamping | Every review adds value or explains why it's clean |

## Tool Reference

**Octocode** (code analysis):
- `localSearchCode` - Find related code, patterns, usages
- `lspFindReferences` - Check impact of changes
- `lspCallHierarchy` - Trace execution flow

**GitHub** (PR context):
- `githubSearchPullRequests` - Find PR details
- `githubGetFileContent` - Read current file state

**Review Gate** (interaction):
- `review_gate_chat` - Interactive feedback with user
