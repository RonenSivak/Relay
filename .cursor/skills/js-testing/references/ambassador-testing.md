# Ambassador Testing Patterns

Three mocking approaches for `@wix/ambassador` HTTP and RPC calls.

---

## 1. AmbassadorTestkit (Classic RPC)

For client-side RPC stubs with the full testkit.

### Setup

```typescript
import { AmbassadorTestkit } from '@wix/ambassador-testkit';

let ambassadorTestkit: AmbassadorTestkit;

beforeEach(() => {
  ambassadorTestkit = new AmbassadorTestkit();
  ambassadorTestkit.start();
});

afterEach(() => {
  ambassadorTestkit.reset();
});
```

### Stubbing an RPC Method

```typescript
import { PremiumPaymentRequests } from '@wix/ambassador-premium-payment-requests/rpc';
import {
  aGetPaymentRequestResponse,
  aCreateOrderSessionForPaymentRequestResponse,
} from '@wix/ambassador-premium-payment-requests/builders';

// Always resolve with builder
ambassadorTestkit
  .createStub(PremiumPaymentRequests)
  .PaymentRequestsService()
  .getPaymentRequest.always()
  .resolve(
    aGetPaymentRequestResponse()
      .withPaymentRequest({ id: 'req-1', amount: 100 })
      .build(),
  );

// Conditional: reject for specific args, resolve for others
ambassadorTestkit
  .createStub(PremiumPaymentRequests)
  .PaymentRequestsService()
  .getPaymentRequest
    .when({ id: 'invalid-id' })
    .reject({ message: 'Not Found', statusCode: 404 })
    .when(() => true)
    .resolve(aGetPaymentRequestResponse().build());
```

### Integration with Driver

```typescript
export class PaymentDriver {
  private ambassadorTestkit = new AmbassadorTestkit();

  given = {
    ambassadorStarted: () => {
      this.ambassadorTestkit.start();
      return this;
    },
    paymentRequestExists: (id: string) => {
      this.ambassadorTestkit
        .createStub(PremiumPaymentRequests)
        .PaymentRequestsService()
        .getPaymentRequest.when({ id })
        .resolve(aGetPaymentRequestResponse().withPaymentRequest({ id }).build());
      return this;
    },
    paymentRequestFails: (id: string) => {
      this.ambassadorTestkit
        .createStub(PremiumPaymentRequests)
        .PaymentRequestsService()
        .getPaymentRequest.when({ id })
        .reject({ message: 'Server error', statusCode: 500 });
      return this;
    },
  };

  cleanup() {
    this.ambassadorTestkit.reset();
  }
}
```

---

## 2. when() from gRPC Testkit (Serverless)

For serverless functions using gRPC-style ambassador calls.

### Setup

```typescript
import { when } from '@wix/ambassador-grpc-testkit';
```

### Stubbing

```typescript
import { getDataCollection } from '@wix/ambassador-data-v2-data-collection/rpc';
import { Segment } from '@wix/ambassador-data-v2-data-collection/types';

// Resolve with specific args
when(getDataCollection)
  .withArg({
    dataCollectionId: 'my-collection',
    consistentRead: false,
  })
  .thenResolveWith({
    collection: { id: 'my-collection', displayName: 'My Collection' },
  });

// Reject with gRPC error
import { GrpcStatus, GrpcStatusError } from '@wix/serverless-api';

when(getCollectionMetadata)
  .withArg({ dataCollectionId: 'missing-id' })
  .thenRejectOnce(
    GrpcStatusError.applicationError({
      code: GrpcStatus.NOT_FOUND,
      message: 'Item not found',
    }),
  );
```

### Organizing Mocks

```typescript
// mock-ambassador-requests.ts
export function mockGetCollectionPayload(): void {
  when(getDataCollection)
    .withArg({ dataCollectionId: DATA_COLLECTION_ID })
    .thenResolveWith(GET_DATA_COLLECTION_STUB);

  when(getCollectionRules)
    .withArg({ dataCollectionId: DATA_COLLECTION_ID })
    .thenResolveWith(GET_COLLECTION_RULES_STUB);
}

export function mockCreateDataCollection(): void {
  when(createDataCollection)
    .withArg({ collection: CREATE_STUB.collection })
    .thenResolveWith({ collection: CREATE_STUB.collection });
}
```

---

## 3. whenAmbassadorCalled (Yoshi BM / Serverless)

For Yoshi Business Manager apps and serverless flows.

### Import

```typescript
// Yoshi BM apps
import { whenAmbassadorCalled } from '@wix/yoshi-flow-bm/test/serverless';

// OR serverless testkit
import { whenAmbassadorCalled } from '@wix/serverless-testkit';
```

### Stubbing

```typescript
import { listEventsSummary } from '@wix/ambassador-dealer-v1-offer-event/rpc';

// Resolve with any args
whenAmbassadorCalled(listEventsSummary)
  .withAny()
  .thenResolveBy(() => ({
    eventsSummary: [{ offerId: 'offer-1', count: 5 }],
  }));

// Reject
whenAmbassadorCalled(listEventsSummary)
  .withAny()
  .thenReject(new Error('Server error'));
```

### Driver Pattern with whenAmbassadorCalled

```typescript
export class DealerServiceMock {
  private eventsSummary: EventsSummary[] = [];
  private isError = false;

  given = {
    eventsSummary: (data: EventsSummary[]) => {
      this.eventsSummary = data;
    },
    isError: () => {
      this.isError = true;
    },
  };

  mock = () => {
    this.isError
      ? whenAmbassadorCalled(listEventsSummary)
          .withAny()
          .thenReject(new Error('Server error'))
      : whenAmbassadorCalled(listEventsSummary)
          .withAny()
          .thenResolveBy(() => ({
            eventsSummary: this.eventsSummary,
          }));
  };
}
```

---

## 4. http-client-testkit (HTTP Ambassador Calls)

For ambassador HTTP calls made via `httpClient.request()`. Two modes: mock client (unit) or mock server (integration).

### Mock Client Mode (unit tests, no outbound requests)

```typescript
import { createHttpClientMock, whenRequest } from '@wix/http-client-testkit';
import { createProduct } from '@wix/ambassador-stores-v1-product/http';

const scenario = whenRequest(createProduct)
  .withData({ title: 'my product' })
  .reply(200, { id: 'product-1' });

const httpClient = createHttpClientMock([scenario]);
// Inject httpClient into your component/service
```

### Mock Server Mode (integration tests)

```typescript
import { HttpMockServer, whenRequest } from '@wix/http-client-testkit';
import { createProduct } from '@wix/ambassador-stores-v1-product/http';

const scenario = whenRequest(createProduct)
  .withData({ title: 'my product' })
  .reply(200, { id: 'product-1' })
  .persist(); // Reuse for multiple calls

const server = new HttpMockServer([scenario]);
server.beforeAndAfter();
```

### Key: Scenarios are single-use by default

Scenarios match **once** then are removed. Use `.persist()` to keep them.

### Error replies

```typescript
whenRequest(createProduct)
  .withData({ title: 'bad' })
  .reply(500, { error: 'Server error' });
```

### Direct httpClient mock (fallback)

```typescript
const httpRequestMock = jest.fn();

jest.doMock('../services/engine', () => ({
  engine: () => ({
    httpClient: () => ({ request: httpRequestMock }),
  }),
}));

httpRequestMock.mockResolvedValue({ data: { items: [{ id: '1' }] } });
```

---

## Ambassador Builder Patterns

Ambassador packages auto-generate builders following the `a{ResponseName}()` convention.

### Imports

```typescript
// Builders come from the ambassador package's /builders path
import { aGetProductResponse } from '@wix/ambassador-premium-product-catalog/builders';
import { aGetPaymentRequestResponse } from '@wix/ambassador-premium-payment-requests/builders';
```

### Usage

```typescript
// Simple build
const response = aGetProductResponse().build();

// With overrides (chainable .with* methods)
const response = aGetProductResponse()
  .withProduct({ name: 'Premium Plan', price: 29.99 })
  .build();

// Nested overrides
const response = aGetPaymentRequestResponse()
  .withPaymentRequest({
    id: 'req-1',
    amount: 100,
    currency: 'USD',
    status: 'PENDING',
  })
  .build();
```

### Custom Builders (when generated ones aren't enough)

```typescript
// Follow the a/an naming convention
export const aPaymentRequest = (overrides?: Partial<PaymentRequest>): PaymentRequest => ({
  id: 'req-123',
  amount: 50,
  currency: 'USD',
  status: 'PENDING',
  createdAt: new Date('2024-01-01'),
  ...overrides,
});

// Usage in driver
given = {
  paymentRequestExists: () => {
    whenAmbassadorCalled(getPaymentRequest)
      .withAny()
      .thenResolveBy(() => ({
        paymentRequest: aPaymentRequest({ status: 'COMPLETED' }),
      }));
    return this;
  },
};
```

---

## Verifying Ambassador Was Called

Use `jest.fn()` with `thenResolveBy()` to verify ambassador received correct args:

```typescript
const jestCb = jest.fn().mockReturnValue(chatMessagesResponse);

whenAmbassadorCalled(listChatMessages).withAny().thenResolveBy(jestCb);

// ... trigger the code that calls ambassador ...

expect(jestCb).toHaveBeenCalledWith({ sessionId: '42' });
```

More specific matchers:
```typescript
// Match specific args
whenAmbassadorCalled(listChatMessages).withArg({ sessionId: '42' }).thenResolveWith(response);

// Match with predicate
whenAmbassadorCalled(listChatMessages)
  .withArgThat(arg => arg.sessionId.startsWith('test-'))
  .thenResolveWith(response);
```

---

## Using wix-test-env (Parallel Jest)

For Jest parallel testing, use `wix-test-env`:

```typescript
// environment.ts
import { AmbassadorTestkit } from '@wix/ambassador-testkit';

export const env = TestEnv.builder()
  .withCollaborators({
    ambassadorTestkit: new AmbassadorTestkit(),
  })
  .build();

// in test
import { env } from '../environment';

describe('tests', () => {
  const { ambassadorTestkit } = env.beforeAndAfter();
  // ambassadorTestkit ready to use
});
```

---

## Choosing the Right Approach

| Your Setup | Use | Import From |
|------------|-----|-------------|
| Client-side app (React BM) | `AmbassadorTestkit` | `@wix/ambassador-testkit` |
| Serverless functions (gRPC V2) | `when()` | `@wix/ambassador-grpc-testkit` |
| Yoshi BM app | `whenAmbassadorCalled()` | `@wix/yoshi-flow-bm/test/serverless` |
| Serverless testkit | `whenAmbassadorCalled()` | `@wix/serverless-testkit` |
| HTTP ambassador calls | `createHttpClientMock` / `whenRequest` | `@wix/http-client-testkit` |
| Direct HTTP (fallback) | Mock `httpClient.request` | Manual jest mock |

> **Note:** Ambassador V1 is deprecated. Prefer V2 patterns with `when()` from `@wix/ambassador-grpc-testkit`.
