# Output Format

How to present forensic search findings with verifiable sources.

## Core Principles

1. **Evidence first** - Show the code/file before explaining it
2. **Citations always** - Every claim needs a file:line or link
3. **Hierarchy clear** - Primary → Secondary → Tertiary evidence
4. **Verifiable** - User can click/navigate to every source
5. **No summaries without sources** - Never paraphrase without citing

## Standard Output Template

```markdown
# [SEARCH QUERY]

## Summary
[One-sentence answer if found, or "No evidence found" if exhaustive search yielded nothing]

## Primary Evidence

### [First Finding]
**Location**: [file:path:line-numbers]
```[language]
[actual code snippet]
```
**Link**: [GitHub URL with line anchors if available]

### [Second Finding] (if applicable)
[Same format as above]

## Secondary Evidence

### Historical Context
**Introduced in**: [Commit SHA] ([Date])
- **PR**: [#number] - "[PR title]"
  Link: [GitHub PR URL]
  Key change: [brief description]

**Related Ticket**: [TICKET-ID] - "[Ticket title]"
- Quote: "[relevant excerpt from ticket]"
- Link: [Jira URL]
- Decision: [key decision made]

**Discussion**: [Channel] ([Date])
- Quote: "[relevant excerpt from Slack]"
- Link: [Slack thread URL]
- Participants: [@user1, @user2]

## Tertiary Evidence

### Documentation
**README**: [file:path:line]
- "[excerpt from README]"

**Comments**: [file:path:line]
```[language]
// [actual comment]
```

## Timeline (if relevant)

[Date]: [Event] - [Source]
[Date]: [Event] - [Source]
[Date]: [Event] - [Source]

## Next Steps (if applicable)

[Suggested actions based on findings]
```

## Output Examples by Search Type

### Example 1: Definition Hunting

**Query**: "How is AuthToken defined?"

```markdown
# How is AuthToken defined?

## Summary
AuthToken is a TypeScript class exported from src/auth/token.ts that wraps JWT validation using RS256 algorithm.

## Primary Evidence

### Class Definition
**Location**: src/auth/token.ts:42-67
```typescript
export class AuthToken {
  constructor(private token: string) {}

  validate(): TokenPayload {
    return jwt.verify(this.token, publicKey, {
      algorithms: ['RS256']
    });
  }

  static create(payload: TokenPayload): string {
    return jwt.sign(payload, privateKey, {
      algorithm: 'RS256',
      expiresIn: '1h'
    });
  }
}
```
**Link**: https://github.com/company/repo/blob/main/src/auth/token.ts#L42-L67

### Usage Example
**Location**: src/middleware/auth.ts:15-20
```typescript
import { AuthToken } from './auth/token';

function authenticate(req, res, next) {
  const token = new AuthToken(req.headers.authorization);
  req.user = token.validate();
  next();
}
```
**Link**: https://github.com/company/repo/blob/main/src/middleware/auth.ts#L15-L20

## Secondary Evidence

### Historical Context
**Introduced in**: abc123 (2024-01-15)
- **PR**: #567 - "Add JWT authentication with RS256"
  Link: https://github.com/company/repo/pull/567
  Key change: Migrated from session-based to stateless JWT auth

**Related Ticket**: BACKEND-1234 - "Implement stateless authentication"
- Quote: "We need JWT tokens to support horizontal scaling. RS256 chosen for public key verification."
- Link: https://company.atlassian.net/browse/BACKEND-1234
- Decision: RS256 over HS256 for better key distribution

**Discussion**: #backend-team (2024-01-10)
- Quote: "@engineer: We're going with RS256 because we can distribute public keys to services without sharing the private key"
- Link: https://company.slack.com/archives/C123/p456789
- Participants: [@engineer, @architect, @security]

## Tertiary Evidence

### Documentation
**README**: docs/auth/README.md:23-25
- "AuthToken class handles JWT creation and validation. Uses RS256 algorithm for asymmetric signing."

**Comments**: src/auth/token.ts:40-41
```typescript
// Using RS256 (asymmetric) instead of HS256 (symmetric)
// See BACKEND-1234 for rationale
```

## Timeline

2024-01-10: Design discussion in Slack - RS256 chosen
2024-01-12: BACKEND-1234 created - Spec written
2024-01-15: PR #567 merged - AuthToken class added
2024-01-15: commit abc123 - First implementation
```

### Example 2: Pattern Discovery

**Query**: "How do I add a new component type?"

```markdown
# How do I add a new component type?

## Summary
New component types follow a 3-file pattern: interface definition, base implementation, and factory registration.

## Primary Evidence

### Example 1: Button Component
**Location**: src/components/button/button.ts:1-25
```typescript
// 1. Interface definition
export interface ButtonProps {
  label: string;
  onClick: () => void;
  variant: 'primary' | 'secondary';
}

// 2. Base implementation
export class Button extends Component<ButtonProps> {
  render() {
    return html`<button class="${this.props.variant}">${this.props.label}</button>`;
  }
}

// 3. Factory registration
ComponentFactory.register('button', Button);
```
**Link**: https://github.com/company/repo/blob/main/src/components/button/button.ts#L1-L25

### Example 2: Input Component
**Location**: src/components/input/input.ts:1-20
```typescript
export interface InputProps {
  value: string;
  onChange: (value: string) => void;
}

export class Input extends Component<InputProps> {
  render() {
    return html`<input value="${this.props.value}" />`;
  }
}

ComponentFactory.register('input', Input);
```
**Link**: https://github.com/company/repo/blob/main/src/components/input/input.ts#L1-L20

### Example 3: Card Component
**Location**: src/components/card/card.ts:1-15
```typescript
export interface CardProps {
  title: string;
  children: Component[];
}

export class Card extends Component<CardProps> {
  render() {
    return html`<div class="card"><h2>${this.props.title}</h2></div>`;
  }
}

ComponentFactory.register('card', Card);
```
**Link**: https://github.com/company/repo/blob/main/src/components/card/card.ts#L1-L15

## Secondary Evidence

### Pattern Documentation
**ADR**: docs/decisions/0003-component-architecture.md
- Quote: "All components must extend the base Component class and register with ComponentFactory for runtime instantiation"
- Link: https://github.com/company/repo/blob/main/docs/decisions/0003-component-architecture.md
- Date: 2023-11-20
- Decision: Factory pattern for dynamic component creation

**Related PR**: #234 - "Add component factory pattern"
- Link: https://github.com/company/repo/pull/234
- Key change: Introduced ComponentFactory.register() pattern
- Date: 2023-11-22

## Tertiary Evidence

### Naming Convention
**README**: src/components/README.md:10-15
- "Component files should be named [component-name].ts and placed in src/components/[component-name]/"

### Base Class
**Location**: src/core/component.ts:5-20
```typescript
export abstract class Component<Props> {
  constructor(protected props: Props) {}
  abstract render(): HTMLElement;
}
```

## Pattern Summary

To add a new component type:

1. **Create interface** - Define props shape
   ```typescript
   export interface YourComponentProps { ... }
   ```

2. **Implement class** - Extend Component base class
   ```typescript
   export class YourComponent extends Component<YourComponentProps> {
     render() { ... }
   }
   ```

3. **Register** - Add to factory
   ```typescript
   ComponentFactory.register('your-component', YourComponent);
   ```

4. **File location** - src/components/[name]/[name].ts

5. **Add tests** - src/components/[name]/[name].test.ts (see existing component tests for patterns)
```

### Example 3: Cross-Repo Analogy

**Query**: "Implement rate limiting like in the API service"

```markdown
# Implement rate limiting like in the API service

## Summary
API service uses token bucket algorithm with Redis backend. Can be adapted by replacing Redis with in-memory store for local services.

## Primary Evidence: API Service Implementation

### Rate Limiter Core
**Location**: company/api-service/src/middleware/rate-limit.ts:15-45
```typescript
export class RateLimiter {
  constructor(
    private redis: Redis,
    private maxTokens: number,
    private refillRate: number
  ) {}

  async checkLimit(userId: string): Promise<boolean> {
    const key = `rate:${userId}`;
    const tokens = await this.redis.get(key);

    if (!tokens || parseInt(tokens) < this.maxTokens) {
      await this.redis.incr(key);
      await this.redis.expire(key, 60); // 1 minute window
      return true;
    }

    return false;
  }
}
```
**Link**: https://github.com/company/api-service/blob/main/src/middleware/rate-limit.ts#L15-L45

### Middleware Integration
**Location**: company/api-service/src/server.ts:50-60
```typescript
const limiter = new RateLimiter(redis, 100, 1); // 100 requests per minute

app.use(async (req, res, next) => {
  const allowed = await limiter.checkLimit(req.user.id);
  if (!allowed) {
    res.status(429).json({ error: 'Rate limit exceeded' });
    return;
  }
  next();
});
```
**Link**: https://github.com/company/api-service/blob/main/src/server.ts#L50-L60

## Portable Pattern

### What Transfers
✅ **Algorithm**: Token bucket with refill
✅ **Configuration**: maxTokens, refillRate, window
✅ **Error handling**: 429 status on limit exceeded
✅ **Key structure**: `rate:${userId}` pattern

### What Needs Adaptation
❌ **Storage**: API uses Redis → We can use in-memory Map
❌ **Distribution**: API is distributed → We are single-instance
❌ **User ID**: API has req.user.id → We have different auth

## Adapted Implementation for Current Service

### In-Memory Rate Limiter
**Suggested implementation**: src/middleware/rate-limit.ts
```typescript
export class InMemoryRateLimiter {
  private buckets = new Map<string, { tokens: number; lastRefill: number }>();

  constructor(
    private maxTokens: number = 100,
    private refillRate: number = 1,
    private windowMs: number = 60000
  ) {}

  checkLimit(userId: string): boolean {
    const key = `rate:${userId}`;
    const now = Date.now();
    let bucket = this.buckets.get(key);

    if (!bucket) {
      bucket = { tokens: 1, lastRefill: now };
      this.buckets.set(key, bucket);
      return true;
    }

    // Refill tokens based on time elapsed
    const elapsed = now - bucket.lastRefill;
    const tokensToAdd = Math.floor(elapsed / this.windowMs * this.refillRate);
    bucket.tokens = Math.min(this.maxTokens, bucket.tokens + tokensToAdd);
    bucket.lastRefill = now;

    if (bucket.tokens > 0) {
      bucket.tokens--;
      return true;
    }

    return false;
  }
}
```

### Key Differences from API Service

1. **Storage**: In-memory Map vs Redis
   - Pro: No Redis dependency
   - Con: Not distributed (single instance only)

2. **Cleanup**: No automatic expiry
   - Need periodic cleanup or LRU eviction
   - API service gets this from Redis TTL

3. **Refill logic**: Time-based calculation
   - API service uses Redis INCR + EXPIRE
   - We calculate refill based on elapsed time

## Secondary Evidence

### Original Design
**Jira**: API-456 - "Add rate limiting to prevent abuse"
- Quote: "Token bucket algorithm chosen for smooth rate limiting without hard cutoffs"
- Link: https://company.atlassian.net/browse/API-456

**PR**: company/api-service#123 - "Implement token bucket rate limiting"
- Link: https://github.com/company/api-service/pull/123
- Date: 2023-09-15
- Discussion includes benchmark comparing algorithms

## Next Steps

1. Implement InMemoryRateLimiter class
2. Add periodic cleanup for old buckets (prevent memory leak)
3. Add tests (see api-service tests for patterns)
4. Consider upgrading to Redis if we need distribution later
```

### Example 4: Bug Hunting

**Query**: "Why are users getting logged out randomly?"

```markdown
# Why are users getting logged out randomly?

## Summary
Root cause: JWT tokens expire after 30 minutes but refresh logic fails silently when API returns 401.

## Primary Evidence

### Token Refresh Logic (BUGGY)
**Location**: src/auth/refresh.ts:25-40
```typescript
async function refreshToken(oldToken: string): Promise<string> {
  const response = await fetch('/api/auth/refresh', {
    headers: { 'Authorization': `Bearer ${oldToken}` }
  });

  // BUG: Returns undefined on 401, doesn't throw
  const data = await response.json();
  return data.token;
}
```
**Link**: https://github.com/company/repo/blob/main/src/auth/refresh.ts#L25-L40

**Issue**: When API returns 401 (expired token), `data.token` is undefined. The undefined token is then stored, causing logout.

### Token Expiration Config
**Location**: config/auth.ts:5-7
```typescript
export const TOKEN_CONFIG = {
  expiresIn: '30m'  // 30 minutes
};
```
**Link**: https://github.com/company/repo/blob/main/config/auth.ts#L5-L7

### Refresh Call Site
**Location**: src/app.ts:100-110
```typescript
setInterval(async () => {
  const currentToken = getToken();
  const newToken = await refreshToken(currentToken);

  // BUG: newToken can be undefined, still gets stored
  setToken(newToken);
}, 25 * 60 * 1000); // Every 25 minutes
```
**Link**: https://github.com/company/repo/blob/main/src/app.ts#L100-L110

## Secondary Evidence

### When Bug Was Introduced
**Commit**: def456 (2024-01-20)
- Message: "Add automatic token refresh"
- **Change**: Added setInterval logic
- **Problem**: Didn't handle 401 responses

**Link**: https://github.com/company/repo/commit/def456

### Related Issues
**Jira**: FRONT-789 - "Users report random logouts"
- Reported: 2024-02-01 (12 days after refresh added)
- Quote: "Happens around 30 minutes into session"
- Link: https://company.atlassian.net/browse/FRONT-789

**Slack**: #support-escalations (2024-02-03)
- Quote: "@support: Users saying they get logged out exactly 30 mins in"
- Thread: https://company.slack.com/archives/C999/p888888

### Test Gap
**Location**: src/auth/refresh.test.ts
- No test for 401 response handling
- Tests only cover successful refresh
- **Gap**: Should test expired token scenario

## Timeline

2024-01-20: Commit def456 adds token refresh
2024-02-01: First user reports (FRONT-789)
2024-02-03: Support escalates issue
2024-02-05: Bug identified (this investigation)

## Root Cause Analysis

1. **Token expires at 30min** (config/auth.ts)
2. **Refresh attempts at 25min** (src/app.ts)
3. **API returns 401** (token already expired or invalid)
4. **Refresh returns undefined** (src/auth/refresh.ts bug)
5. **Undefined stored as token** (src/app.ts doesn't validate)
6. **User appears logged out** (no valid token)

## Fix Required

**Location**: src/auth/refresh.ts:25-40

```typescript
async function refreshToken(oldToken: string): Promise<string> {
  const response = await fetch('/api/auth/refresh', {
    headers: { 'Authorization': `Bearer ${oldToken}` }
  });

  // FIX: Check response status
  if (!response.ok) {
    if (response.status === 401) {
      // Token expired, force re-login
      logout();
      throw new Error('Session expired');
    }
    throw new Error('Refresh failed');
  }

  const data = await response.json();

  // FIX: Validate token exists
  if (!data.token) {
    throw new Error('Invalid refresh response');
  }

  return data.token;
}
```

**Also update**: src/app.ts:100-110

```typescript
setInterval(async () => {
  try {
    const currentToken = getToken();
    const newToken = await refreshToken(currentToken);
    setToken(newToken);
  } catch (error) {
    console.error('Token refresh failed:', error);
    // Let refreshToken() handle logout if 401
  }
}, 25 * 60 * 1000);
```
```

## Output Quality Checklist

Before presenting findings, verify:

- [ ] **Every code snippet has file:line** - No orphan snippets
- [ ] **All links are clickable** - Full GitHub URLs with line anchors
- [ ] **Primary evidence comes first** - Code before context
- [ ] **Quotes are exact** - Not paraphrased
- [ ] **Dates included** - For commits, tickets, messages
- [ ] **Timeline makes sense** - Events in chronological order
- [ ] **No "probably" or "likely"** - Only verified facts
- [ ] **User can verify everything** - All sources linked

## Anti-Patterns to Avoid

❌ **Missing citations**:
```
The authentication system uses JWT tokens.
```

✅ **Proper citation**:
```
**Location**: src/auth/token.ts:42
The authentication system uses JWT tokens.
```

---

❌ **Paraphrasing**:
```
The ticket says we needed better scalability.
```

✅ **Direct quote**:
```
**Jira**: BACKEND-1234
Quote: "We need JWT tokens to support horizontal scaling"
Link: https://company.atlassian.net/browse/BACKEND-1234
```

---

❌ **No verification path**:
```
This was discussed in Slack.
```

✅ **Verifiable source**:
```
**Slack**: #backend-team (2024-01-10)
Quote: "@engineer: Redis gives us persistence unlike Memcached"
Link: https://company.slack.com/archives/C123/p456789
```

---

❌ **Summaries without sources**:
```
The code handles token expiration.
```

✅ **Source first, then summary**:
```
**Location**: src/auth/token.ts:55-60
```typescript
if (payload.exp < Date.now()) {
  throw new Error('Token expired');
}
```
The code handles token expiration by comparing the exp claim.
```
