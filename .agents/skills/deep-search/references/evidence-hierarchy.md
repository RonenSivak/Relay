# Evidence Hierarchy

What counts as "proof" in forensic search. Evidence must be verifiable, citable, and traceable.

## Evidence Tiers

### Tier 1: Primary Evidence (Executable Truth)

**Definition**: Evidence that can be directly executed, inspected, or verified in the current state of the system.

**Examples**:
- **Source code** with file path and line numbers
  ```
  src/auth/token.ts:42-67
  ```
- **Git diffs** with commit SHA
  ```
  commit abc123: Added JWT validation
  + function validateToken(token: string) { ... }
  ```
- **Test files** that demonstrate behavior
  ```
  tests/auth.test.ts:15-30
  it('should validate JWT tokens', () => { ... })
  ```
- **Configuration files** with actual values
  ```
  config/database.yml:8
  timeout: 30000
  ```

**Why primary**: Can be verified RIGHT NOW. No interpretation needed. Point to it and it's there.

**Required format**:
- File path (absolute or relative from repo root)
- Line numbers (single line or range)
- Snippet showing the actual code/config
- Link if in GitHub (full URL with line anchors)

### Tier 2: Secondary Evidence (Historical Truth)

**Definition**: Evidence that explains how/why the current state came to be. Verifiable through historical records.

**Examples**:
- **Jira tickets** with quote and link
  ```
  JIRA-1234: "Migrate to JWT for stateless auth"
  Quote: "We need to support horizontal scaling..."
  Link: https://company.atlassian.net/browse/JIRA-1234
  ```
- **Pull requests** with context
  ```
  PR #567: Add JWT authentication
  Author: @engineer
  Merged: 2024-01-15
  Link: https://github.com/company/repo/pull/567
  ```
- **Slack messages** with thread link
  ```
  #engineering-auth channel
  @engineer: "We decided on RS256 over HS256 because..."
  Thread: https://company.slack.com/archives/C123/p456789
  ```
- **Git commit messages** with SHA
  ```
  commit abc123
  "Add JWT validation

  We chose RS256 for public key verification.
  See JIRA-1234 for full context."
  ```

**Why secondary**: Provides context and rationale. Can be verified through audit trail. Explains "why" not just "what".

**Required format**:
- Link to original source (Jira, PR, Slack, commit)
- Relevant quote or excerpt
- Date/timestamp
- Author (when relevant)

### Tier 3: Tertiary Evidence (Soft Documentation)

**Definition**: Supporting evidence that aids understanding but isn't authoritative on its own.

**Examples**:
- **Code comments** explaining intent
  ```
  // TODO: Migrate to async validation
  // This is synchronous for backward compatibility
  ```
- **README files** with guidance
  ```
  ## Authentication
  We use JWT tokens. See src/auth/token.ts for implementation.
  ```
- **Test names** indicating expected behavior
  ```
  test('should throw error for expired tokens')
  ```
- **Function/variable names** showing purpose
  ```
  validateAndRefreshToken()  // implies validation + refresh logic
  ```
- **Type definitions** constraining behavior
  ```
  type TokenPayload = { userId: string; exp: number }
  ```

**Why tertiary**: Useful for understanding but can be outdated or incomplete. Must be corroborated with Tier 1 evidence.

**Required format**:
- File path + line number
- Actual comment/name/type text
- Note if potentially outdated

### Tier 0: NOT Evidence

**Definition**: Statements that cannot be verified and should never be presented as findings.

**Examples (FORBIDDEN)**:
- ❌ "It's probably in the auth module"
- ❌ "This looks like it uses JWT"
- ❌ "Based on the pattern, it likely..."
- ❌ "I think it's handled by..."
- ❌ "It's possible that..."
- ❌ "Typically this would be..."
- ❌ "The code suggests..."
- ❌ Summaries without citations
- ❌ Paraphrased descriptions
- ❌ Inferred behavior
- ❌ Assumptions based on patterns

**Why forbidden**: Cannot be verified. Introduces uncertainty. Not forensic.

## Evidence Sufficiency Rules

### Minimum Evidence Requirements

**For "How is X defined?"**
- MUST: Tier 1 (source code location)
- SHOULD: Tier 2 (commit/PR that added it)
- NICE: Tier 3 (comments explaining why)

**For "How do I add a new component type?"**
- MUST: Tier 1 (2-3 existing examples with file paths)
- SHOULD: Tier 3 (README or docs explaining pattern)
- NICE: Tier 2 (PR that added a recent example)

**For "Implement X like Y in another repo"**
- MUST: Tier 1 (Y's implementation with file paths)
- MUST: Tier 1 (Architectural comparison showing differences)
- SHOULD: Tier 2 (Discussion or ADR explaining Y's design)

**For "Why is this bug happening?"**
- MUST: Tier 1 (root cause code location)
- SHOULD: Tier 2 (commit that introduced it OR ticket describing it)
- NICE: Tier 2 (related bug reports showing pattern)

### Evidence Combination Rules

**Tier 1 + Tier 1 = Strong**
- Example: Code location + test demonstrating behavior
- Conclusion: Definitive answer

**Tier 1 + Tier 2 = Complete**
- Example: Code location + PR explaining why
- Conclusion: What + Why answered

**Tier 2 + Tier 3 = Weak**
- Example: Jira ticket + code comment
- Conclusion: Need Tier 1 to confirm

**Tier 3 only = Insufficient**
- Example: Just a README mention
- Conclusion: Must find actual code

**Tier 0 = Invalid**
- Example: "Probably handled elsewhere"
- Conclusion: Keep searching

## Verification Checklist

Before presenting findings, verify:

- [ ] **Can I point to it?** (File path + line number)
- [ ] **Can user click to it?** (GitHub link or local path)
- [ ] **Can I quote it?** (Actual code snippet, not summary)
- [ ] **Is it current?** (Check commit date, ensure not deleted)
- [ ] **Is it the SOURCE?** (Not a re-export or wrapper)

If ANY checkbox is unchecked, the evidence is incomplete.

## Evidence Presentation Order

Always present evidence in this order:

1. **Primary (Tier 1)** - Show the code/file first
2. **Secondary (Tier 2)** - Add historical context
3. **Tertiary (Tier 3)** - Include supporting documentation

**Example structure**:
```
DEFINITION FOUND:

Primary Evidence:
- Source: src/auth/token.ts:42-67
  ```typescript
  export function validateToken(token: string): TokenPayload {
    // implementation
  }
  ```

Secondary Evidence:
- Introduced in: PR #567 (2024-01-15)
  Quote: "Add JWT validation with RS256"
  Link: https://github.com/company/repo/pull/567

- Design decision: JIRA-1234
  Quote: "We need stateless auth for horizontal scaling"
  Link: https://company.atlassian.net/browse/JIRA-1234

Tertiary Evidence:
- README mention: docs/auth/README.md:15
  "See validateToken() for JWT validation logic"
```

## When Evidence Doesn't Exist

If exhaustive search yields no evidence, explicitly state what was searched and conclude definitively:

**Example**:
```
NO EVIDENCE FOUND:

Searched:
- Local codebase: full-text search for "UserPreferences"
- GitHub repos: company/web-app, company/api, company/shared
- Git history: last 2 years of commits
- Jira: all projects, keyword "user preferences"
- Slack: #engineering, #product channels

Conclusion:
UserPreferences feature has not been implemented.
No code, tickets, or discussions found.
```

This is valid forensic output. Saying "not found after exhaustive search" is better than saying "probably somewhere."

## Evidence Quality Red Flags

Watch for these signs of weak evidence:

🚩 **Indirect references** - "Used by X which is called by Y"
- Fix: Trace to the actual source

🚩 **Outdated references** - Comment from 2020, code changed in 2024
- Fix: Verify with current code

🚩 **Generic patterns** - "Follows standard REST pattern"
- Fix: Show actual implementation, not assumed pattern

🚩 **Ambiguous locations** - "In the auth module somewhere"
- Fix: Get exact file path and line numbers

🚩 **Circular references** - A imports B, B imports A, both seem relevant
- Fix: Find the actual source of truth

🚩 **Missing context** - Code snippet with no file path
- Fix: Add file path and line numbers

## Evidence Anti-Patterns

### Anti-Pattern 1: Summary Instead of Citation

❌ **Wrong**:
"The authentication system validates JWT tokens using RS256 algorithm"

✅ **Right**:
```
Source: src/auth/token.ts:42
```typescript
const algorithm = 'RS256';
function validateToken(token: string) {
  return jwt.verify(token, publicKey, { algorithms: [algorithm] });
}
```
```

### Anti-Pattern 2: Probably/Likely Language

❌ **Wrong**:
"Token validation is probably handled in the middleware layer"

✅ **Right**:
```
Source: src/middleware/auth.ts:23
```typescript
app.use(async (req, res, next) => {
  const token = req.headers.authorization;
  const payload = validateToken(token);
  req.user = payload;
  next();
});
```
```

### Anti-Pattern 3: Incomplete History

❌ **Wrong**:
"This was added at some point for security reasons"

✅ **Right**:
```
Added in: commit abc123 (2024-01-15)
PR: #567
Author: @engineer
Reason (from commit message): "Add JWT validation for stateless auth"
Related ticket: JIRA-1234 "Support horizontal scaling"
```

### Anti-Pattern 4: Missing Source

❌ **Wrong**:
```typescript
function validateToken(token: string) { ... }
```

✅ **Right**:
```
src/auth/token.ts:42-58
```typescript
function validateToken(token: string) { ... }
```
GitHub: https://github.com/company/repo/blob/main/src/auth/token.ts#L42-L58
```
