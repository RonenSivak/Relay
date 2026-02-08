# Serverless Review Reference

Detailed patterns and anti-patterns for reviewing Wix Serverless functions.

## Wix Serverless Overview

Wix Serverless is the internal Node.js service platform. Key libraries:
- `@wix/serverless-api` — `FunctionsBuilder`, `FunctionContext`, `WebRequest`, types
- `@wix/serverless-runtime` — Wix environment adaptation (monitoring, context injection, headers)
- `@wix/serverless-testkit` — Integration test harness (`ServerlessTestkit`)

Functions are defined via `FunctionsBuilder` and support:
- **Web functions** — HTTP endpoints (`addWebFunction`)
- **Greyhound consumers** — Kafka message consumers (`addGreyhoundConsumer`)
- **gRPC services** — Exposed via `@wix/ambassador-serverless-*` packages
- **Cron jobs** — Scheduled tasks via TimeCapsule
- **Kafka producers** — Topic declaration (`withKafkaTopic`)

## FunctionsBuilder Patterns

### Canonical App Entry Point

```typescript
// app.ts — the serverless entry point
import { FunctionsBuilder } from '@wix/serverless-api';

module.exports = (functionsBuilder: FunctionsBuilder) =>
  functionsBuilder
    .withBiInfo({ src: 10 })
    .addWebFunction('GET', '/', async (ctx) => {
      return 'Service is running';
    })
    .addWebFunction('POST', '/action', { timeoutMillis: 120_000 }, handler)
    .addExperiment(PetriSpecs.SomeExperiment, {
      scopes: ['my-scope'],
      owner: 'my-team',
      onlyForLoggedInUsers: true,
      controlGroup: 'false',
      variants: ['true'],
    });
```

### Review Checklist for FunctionsBuilder

```
- [ ] Entry point exports a function that receives FunctionsBuilder
- [ ] module.exports or named export — consistent with project pattern
- [ ] withContextPath set if needed (custom URL path prefix)
- [ ] withBiInfo configured for BI reporting
- [ ] Each web function has correct HTTP method (GET/POST/PUT/DELETE)
- [ ] Timeout configured for long-running operations (default is low)
- [ ] Experiments declared with proper scopes and owner
```

## Web Functions

### Proper Web Function Handler

```typescript
// GOOD: Typed handler with proper error handling
import { FunctionContext, WebRequest, FullHttpResponse } from '@wix/serverless-api';

async function handleExport(
  ctx: FunctionContext,
  req: WebRequest,
): Promise<FullHttpResponse> {
  try {
    const { metaSiteId } = req.body;

    if (!metaSiteId) {
      return new FullHttpResponse({
        status: 400,
        body: { error: 'metaSiteId is required' },
      });
    }

    const result = await ctx.ambassador.SomeService().doWork({ metaSiteId });

    return new FullHttpResponse({
      status: 200,
      body: result,
    });
  } catch (error) {
    ctx.logger.error('Export failed', { error });
    return new FullHttpResponse({
      status: 500,
      body: { error: 'Internal server error' },
    });
  }
}
```

### Anti-Patterns

```typescript
// BLOCKER: No error handling in web function
async function handleAction(ctx: FunctionContext, req: WebRequest) {
  const result = await ctx.ambassador.SomeService().doWork(req.body);
  return result; // If doWork throws, 500 with stack trace leaks
}

// BLOCKER: No input validation
async function handleCreate(ctx: FunctionContext, req: WebRequest) {
  await ctx.datastore.set(req.body.key, req.body); // Trusting raw input
  return 'ok';
}

// IMPORTANT: Missing timeout for long operation
functionsBuilder
  .addWebFunction('POST', '/export', handleExport);
  // Should be: .addWebFunction('POST', '/export', { timeoutMillis: 120_000 }, handleExport)

// IMPORTANT: Returning raw objects instead of FullHttpResponse
async function handler(ctx: FunctionContext) {
  return { data: 'result' }; // No status code control, no error handling
}
```

## Greyhound Consumers (Kafka)

### Proper Consumer Pattern

```typescript
import { FunctionsBuilder, GreyhoundConsumerOptions } from '@wix/serverless-api';

const retryPolicy: GreyhoundConsumerOptions = {
  retries: {
    intervalsInSeconds: [5, 30, 300, 3600],  // Escalating: 5s, 30s, 5m, 1h
  },
  timeoutInMillis: 30_000,
  enableDlq: true,  // Dead letter queue for unprocessable messages
};

module.exports = (functionsBuilder: FunctionsBuilder) =>
  functionsBuilder
    .withKafkaTopic(ProducedTopics.MY_OUTPUT_TOPIC)
    .addGreyhoundConsumer(
      ConsumedTopics.INPUT_EVENTS,
      handleInputEvent,
      retryPolicy,
    );
```

### Review Checklist for Consumers

```
- [ ] Retry policy configured with escalating intervals
- [ ] DLQ (enableDlq: true) for unrecoverable message failures
- [ ] Timeout set (timeoutInMillis) — default may be too low
- [ ] Handler is idempotent (message may be delivered more than once)
- [ ] Handler handles partial failures gracefully
- [ ] Consumed topics declared and match expected Kafka cluster
- [ ] Produced topics declared with withKafkaTopic before use
```

### Anti-Patterns

```typescript
// BLOCKER: No retry policy on consumer
functionsBuilder.addGreyhoundConsumer(
  'my-topic',
  handleMessage,
  // Missing retry config — single failure = message lost
);

// BLOCKER: Non-idempotent consumer handler
async function handleMessage(ctx: FunctionContext, message: any) {
  await ctx.ambassador.PaymentService().charge({
    userId: message.userId,
    amount: message.amount,
  });
  // If Kafka redelivers this message, user gets charged twice!
}

// IMPORTANT: No DLQ — poison messages block the consumer forever
const retryPolicy: GreyhoundConsumerOptions = {
  retries: { intervalsInSeconds: [5, 10, 60] },
  // Missing: enableDlq: true
};

// IMPORTANT: Flat retry intervals (no backoff)
const retryPolicy: GreyhoundConsumerOptions = {
  retries: { intervalsInSeconds: [5, 5, 5, 5] },  // No escalation
  // Better: [5, 30, 300, 3600] — exponential-ish backoff
};
```

## FunctionContext Usage

### What FunctionContext Provides

```typescript
interface FunctionContext {
  ambassador: AmbassadorClient;     // RPC calls to other services
  apiGatewayClient: ApiGatewayClient; // MetaSiteId resolution, auth
  aspects: AspectStore;             // Request aspects (headers, auth)
  datastore: Datastore;            // Key-value store (per-app)
  cloudStore: CloudStore;          // Cloud storage (S3-like)
  logger: Logger;                  // Structured logging
  config: ConfigStore;             // App configuration / secrets
  petri: PetriClient;             // Experiments
}
```

### Review Checklist for Context Usage

```
- [ ] Ambassador calls are typed (using generated service types)
- [ ] Aspects propagated correctly when making downstream calls
- [ ] Secrets accessed via ctx.config, never hardcoded
- [ ] Logger used for structured logging (not console.log)
- [ ] Datastore keys are namespaced to avoid collisions
- [ ] Error responses from ambassador calls handled properly
```

### Anti-Patterns

```typescript
// BLOCKER: Using console.log instead of ctx.logger
async function handler(ctx: FunctionContext) {
  console.log('Processing request');  // Lost in production, not structured
  // Better: ctx.logger.info('Processing request', { requestId });
}

// BLOCKER: Hardcoded secrets
const API_KEY = 'sk-abc123';
// Better: const apiKey = ctx.config.get('API_KEY');

// IMPORTANT: Not propagating aspects to downstream calls
async function handler(ctx: FunctionContext, req: WebRequest) {
  // Missing aspect propagation — loses auth context, tracing, etc.
  const result = await someExternalCall();
}
```

## Experiments (Petri)

### Proper Experiment Declaration

```typescript
functionsBuilder
  .addExperiment(PetriSpecs.MyExperiment, {
    scopes: ['my-product'],
    owner: 'my-team',
    onlyForLoggedInUsers: true,
    controlGroup: 'false',
    variants: ['true'],
  });
```

### Review Checklist

```
- [ ] Experiments declared via addExperiment on FunctionsBuilder
- [ ] PetriSpecs are defined in a separate specs file (not inline strings)
- [ ] Experiment has an owner (team name)
- [ ] Scopes are correct for the experiment
- [ ] Experiment is checked before using new behavior
```

## Testing Serverless Functions

### Integration Test Pattern with ServerlessTestkit

```typescript
import { ServerlessTestkit, app } from '@wix/serverless-testkit';

describe('My Serverless Function', () => {
  const testkit: ServerlessTestkit = app({
    scopeName: 'my-service',
    consumesTopics: ['input-events'],
  });

  beforeAll(() => testkit.start());
  afterAll(() => testkit.stop());

  it('should handle GET request', async () => {
    const response = await testkit.httpClient.get(testkit.getUrl('/'));
    expect(response.status).toBe(200);
  });

  it('should process POST with valid payload', async () => {
    const response = await testkit.httpClient.post(
      testkit.getUrl('/action'),
      { data: { key: 'value' } },
    );
    expect(response.status).toBe(200);
    expect(response.data).toMatchObject({ success: true });
  });
});
```

### Review Checklist for Tests

```
- [ ] Uses @wix/serverless-testkit (not manual HTTP server setup)
- [ ] testkit.start() in beforeAll, testkit.stop() in afterAll
- [ ] Ambassador stubs configured via testkit.ambassadorV2 or testkit.ambassador
- [ ] Greyhound messages published via testkit.greyhoundTestkit
- [ ] Config/secrets set via testkit.setConfig()
- [ ] Tests are isolated (datastore/cloudStore cleared between tests if needed)
- [ ] Tests cover error cases (invalid input, downstream failures)
```

### Anti-Patterns in Tests

```typescript
// IMPORTANT: Not using ServerlessTestkit
// Rolling your own HTTP server setup misses Wix context (aspects, auth, etc.)

// IMPORTANT: Not stubbing ambassador calls
// Tests that hit real services are flaky and slow

// IMPORTANT: Shared state between tests
// Not clearing datastore between tests causes ordering dependencies
beforeEach(() => {
  testkit.clearDatastore();  // Important for isolation
});
```

## Configuration and Deployment

### Review Checklist

```
- [ ] Service mapping configured in Dev Portal (not hardcoded URLs)
- [ ] Memory allocation appropriate for the workload
- [ ] Secrets stored in Dev Portal, not in code or config files
- [ ] Health endpoint exists (default '/' or explicit health check)
- [ ] Rollout uses feature flags for risky changes
- [ ] Monitoring: BI events configured (withBiInfo)
```

## Security Specific to Serverless

### Review Checklist

```
- [ ] Web functions validate authentication via ctx.apiGatewayClient
- [ ] MetaSiteId resolved securely (not from user input alone)
- [ ] Sensitive operations check authorization (not just authentication)
- [ ] No secrets in code, environment files, or logs
- [ ] Input from Greyhound messages validated (messages can be malformed)
- [ ] Rate limiting considered for public-facing web functions
```

### Anti-Patterns

```typescript
// BLOCKER: Trusting metaSiteId from request body
async function handler(ctx: FunctionContext, req: WebRequest) {
  const { metaSiteId } = req.body;  // User-controlled!
  // Better: const metaSiteId = await ctx.apiGatewayClient.metaSiteId(ctx.aspects);
}

// BLOCKER: Logging sensitive data
ctx.logger.info('User data', { user: { ...userData, password } });
// Better: Exclude sensitive fields from logs

// IMPORTANT: No auth check on mutation endpoint
functionsBuilder.addWebFunction('POST', '/delete-data', handleDelete);
// Should verify caller has permission before deleting
```

## Common Serverless Pitfalls

| Pitfall | Impact | Fix |
|---------|--------|-----|
| No timeout on web functions | Request hangs, pod killed | Set `timeoutMillis` explicitly |
| No retry policy on consumers | Message lost on first failure | Configure `retries` with escalating intervals |
| No DLQ on consumers | Poison message blocks queue | Set `enableDlq: true` |
| Non-idempotent consumer | Duplicate processing on retry | Design for at-least-once delivery |
| console.log in production | Logs lost, not structured | Use `ctx.logger` |
| Hardcoded secrets | Security risk in source control | Use `ctx.config.get()` |
| Missing aspect propagation | Broken tracing, auth | Pass `ctx.aspects` to downstream calls |
| No input validation | Injection, crashes | Validate at handler boundary |
| Trusting metaSiteId from body | Authorization bypass | Resolve from `ctx.apiGatewayClient` |
| No health endpoint | Deployment health checks fail | Keep default `/` or add explicit check |
| Missing BI configuration | No observability | Add `withBiInfo({ src: N })` |
| Large payload without streaming | Memory spikes, timeouts | Use streaming or pagination |
