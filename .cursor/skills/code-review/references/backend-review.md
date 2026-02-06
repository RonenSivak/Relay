# Backend Review Reference

Detailed patterns and anti-patterns for reviewing Node.js/TypeScript backend code in Wix projects.

## API Design Anti-Patterns

### Missing Input Validation

```typescript
// BLOCKER: No input validation at boundary
app.post('/users', async (req, res) => {
  const user = await db.createUser(req.body); // Trusting raw input
  res.json(user);
});

// Better: Validate at the boundary
app.post('/users', async (req, res) => {
  const parsed = CreateUserSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ errors: parsed.error.issues });
  }
  const user = await db.createUser(parsed.data);
  res.json(user);
});
```

### Inconsistent Error Responses

```typescript
// IMPORTANT: Inconsistent error formats
app.get('/users/:id', async (req, res) => {
  try {
    const user = await db.findUser(req.params.id);
    if (!user) {
      return res.status(404).send('not found'); // String
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message }); // Object
  }
});

// Better: Consistent error format
app.get('/users/:id', async (req, res) => {
  try {
    const user = await db.findUser(req.params.id);
    if (!user) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An error occurred' });
  }
});
```

### Missing Pagination

```typescript
// BLOCKER: Returning unbounded results
app.get('/users', async (req, res) => {
  const users = await db.findAll(); // Could be millions
  res.json(users);
});

// Better: Always paginate list endpoints
app.get('/users', async (req, res) => {
  const { offset = 0, limit = 50 } = req.query;
  const capped = Math.min(Number(limit), 100);
  const users = await db.findAll({ offset: Number(offset), limit: capped });
  res.json({ items: users, offset, limit: capped });
});
```

## Data Layer Anti-Patterns

### N+1 Queries

```typescript
// BLOCKER: N+1 query pattern
async function getUsersWithPosts(userIds: string[]) {
  const users = await db.findUsers(userIds);
  for (const user of users) {
    user.posts = await db.findPostsByUser(user.id); // N extra queries!
  }
  return users;
}

// Better: Batch query
async function getUsersWithPosts(userIds: string[]) {
  const [users, posts] = await Promise.all([
    db.findUsers(userIds),
    db.findPostsByUserIds(userIds), // Single query for all posts
  ]);
  return users.map(u => ({
    ...u,
    posts: posts.filter(p => p.userId === u.id),
  }));
}
```

### Missing Transactions

```typescript
// BLOCKER: Non-atomic multi-step write
async function transferFunds(from: string, to: string, amount: number) {
  await db.debit(from, amount);  // If next line fails, money disappears
  await db.credit(to, amount);
}

// Better: Use transaction
async function transferFunds(from: string, to: string, amount: number) {
  await db.transaction(async (tx) => {
    await tx.debit(from, amount);
    await tx.credit(to, amount);
  });
}
```

### Unbounded Queries

```typescript
// IMPORTANT: No LIMIT on query
const results = await db.query('SELECT * FROM logs WHERE level = ?', ['error']);

// Better: Always limit
const results = await db.query(
  'SELECT * FROM logs WHERE level = ? ORDER BY created_at DESC LIMIT ?',
  ['error', 1000]
);
```

## Wix Ambassador Patterns

### Proper Ambassador Usage

```typescript
// IMPORTANT: Untyped ambassador call
const response = await httpClient.request(someRpcCall({ id }));

// Better: Typed with proper error handling
import { SomeServiceV1 } from '@wix/ambassador-some-service/http';

try {
  const response = await httpClient.request(
    SomeServiceV1().SomeMethod()({ id })
  );
  return response.data;
} catch (err) {
  if (err.response?.status === 404) {
    return null;
  }
  throw err;
}
```

### Ambassador Test Mocking

```typescript
// IMPORTANT: Check mocking follows project patterns
// Common patterns to look for:

// 1. @wix/ambassador-testkit (RPC stubs)
ambassadorServer
  .createStub(SomeServiceV1)
  .SomeMethod.returns(mockResponse);

// 2. @wix/http-client-testkit (HTTP)
httpClientTestkit
  .when(SomeServiceV1().SomeMethod())
  .resolve(mockResponse);

// Verify: Does the test use the same pattern as other tests in the project?
// If unsure, invoke /unit-testing to check patterns
```

## Security Patterns

### Authentication

```typescript
// BLOCKER: Missing auth on sensitive endpoint
app.delete('/users/:id', async (req, res) => {
  await db.deleteUser(req.params.id); // Anyone can delete!
  res.sendStatus(204);
});

// Better: Auth middleware + authorization check
app.delete('/users/:id', requireAuth, async (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ code: 'FORBIDDEN', message: 'Not authorized' });
  }
  await db.deleteUser(req.params.id);
  res.sendStatus(204);
});
```

### Secret Handling

```typescript
// BLOCKER: Hardcoded secrets
const API_KEY = 'sk-abc123def456';
const DB_PASSWORD = 'mypassword';

// Better: Environment variables
const API_KEY = process.env.API_KEY;
const DB_PASSWORD = process.env.DB_PASSWORD;
```

### SQL Injection

```typescript
// BLOCKER: String interpolation in SQL
const user = await db.query(`SELECT * FROM users WHERE id = '${userId}'`);

// Better: Parameterized queries
const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
```

## Error Handling Anti-Patterns

### Swallowing Errors

```typescript
// BLOCKER: Silent error swallowing
try {
  await riskyOperation();
} catch (err) {
  // Nothing here — error disappears silently
}

// Better: Log and re-throw or handle explicitly
try {
  await riskyOperation();
} catch (err) {
  logger.error('riskyOperation failed', { error: err, context });
  throw err; // Or handle with fallback
}
```

### Catching Too Broad

```typescript
// IMPORTANT: Catching everything
try {
  const data = JSON.parse(input);
  await processData(data);
  await saveResults(data);
} catch (err) {
  res.status(400).json({ error: 'Bad request' }); // Could be a DB error
}

// Better: Catch specific errors or handle at proper scope
try {
  const data = JSON.parse(input);
} catch (err) {
  return res.status(400).json({ code: 'INVALID_JSON', message: 'Invalid JSON input' });
}
try {
  await processData(data);
  await saveResults(data);
} catch (err) {
  logger.error('Processing failed', { error: err });
  return res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Processing failed' });
}
```

### Missing Timeouts on External Calls

```typescript
// IMPORTANT: No timeout — could hang forever
const response = await fetch('https://external-service.com/api/data');

// Better: Always set timeouts
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000);
try {
  const response = await fetch('https://external-service.com/api/data', {
    signal: controller.signal,
  });
  return await response.json();
} finally {
  clearTimeout(timeout);
}
```

## Serverless / Wix-Specific Patterns

### Feature Flags

```typescript
// SUGGESTION: Risky change without feature flag
// New behavior that changes existing functionality should be behind a flag

// Pattern:
if (experiments.enabled('specs.my-project.newFeature')) {
  return newImplementation();
}
return existingImplementation();
```

### Proper Logging

```typescript
// IMPORTANT: Unstructured logging
console.log('User created: ' + userId);

// Better: Structured logging with context
logger.info('User created', { userId, email: user.email, source: 'registration' });
```

## Performance Red Flags

| Pattern | Issue | Fix |
|---------|-------|-----|
| `await` in a loop | Sequential external calls | `Promise.all()` or batch API |
| No caching for repeated lookups | Redundant DB/API hits | Cache with TTL + invalidation |
| Synchronous heavy computation | Blocks event loop | Worker thread or async processing |
| Large response without pagination | Memory spikes, slow response | Paginate or stream |
| Missing DB indexes for query patterns | Full table scans | Add index for WHERE/JOIN columns |
| No connection pooling | Connection overhead | Use pool (built into most ORMs) |
