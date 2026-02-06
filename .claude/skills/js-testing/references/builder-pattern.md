# Builder Pattern

Builders create test data with sensible defaults and easy overrides.

## Basic Factory Function

```typescript
// user.builder.ts
import { User } from '../types';

export const aUser = (overrides?: Partial<User>): User => ({
  id: 'user-123',
  name: 'Test User',
  email: 'test@example.com',
  role: 'member',
  createdAt: new Date('2024-01-01'),
  ...overrides,
});

// Usage
const admin = aUser({ role: 'admin' });
const newUser = aUser({ id: 'user-456', name: 'Another User' });
```

## Naming Convention

Prefix with `a` or `an` for readability:

```typescript
export const aUser = (overrides?: Partial<User>): User => ({ ... });
export const anOrder = (overrides?: Partial<Order>): Order => ({ ... });
export const aProduct = (overrides?: Partial<Product>): Product => ({ ... });
```

## Nested Objects

```typescript
interface Order {
  id: string;
  user: User;
  items: OrderItem[];
  status: OrderStatus;
  total: number;
}

export const anOrderItem = (overrides?: Partial<OrderItem>): OrderItem => ({
  productId: 'prod-123',
  quantity: 1,
  price: 9.99,
  ...overrides,
});

export const anOrder = (overrides?: Partial<Order>): Order => ({
  id: 'order-123',
  user: aUser(),
  items: [anOrderItem()],
  status: 'pending',
  total: 9.99,
  ...overrides,
});

// Usage - override nested
const orderWithAdmin = anOrder({
  user: aUser({ role: 'admin' }),
  items: [
    anOrderItem({ quantity: 2 }),
    anOrderItem({ productId: 'prod-456', price: 19.99 }),
  ],
});
```

## Array Builders

```typescript
export const manyUsers = (count: number, overrides?: Partial<User>): User[] =>
  Array.from({ length: count }, (_, i) =>
    aUser({
      id: `user-${i + 1}`,
      email: `user${i + 1}@example.com`,
      ...overrides,
    })
  );

// Usage
const fiveAdmins = manyUsers(5, { role: 'admin' });
```

## Stateful Builder (for complex scenarios)

```typescript
class UserBuilder {
  private user: User = {
    id: 'user-123',
    name: 'Test User',
    email: 'test@example.com',
    role: 'member',
    createdAt: new Date('2024-01-01'),
  };

  withId(id: string) {
    this.user.id = id;
    return this;
  }

  withName(name: string) {
    this.user.name = name;
    return this;
  }

  asAdmin() {
    this.user.role = 'admin';
    return this;
  }

  build(): User {
    return { ...this.user };
  }
}

// Usage
const admin = new UserBuilder().withName('Admin User').asAdmin().build();
```

## API Response Builders

```typescript
interface ApiResponse<T> {
  data: T;
  meta: { page: number; total: number };
}

export const anApiResponse = <T>(
  data: T,
  meta?: Partial<ApiResponse<T>['meta']>
): ApiResponse<T> => ({
  data,
  meta: {
    page: 1,
    total: 1,
    ...meta,
  },
});

// Usage
const usersResponse = anApiResponse(manyUsers(10), { total: 100 });
```

## Error Builders

```typescript
export const anApiError = (overrides?: Partial<ApiError>): ApiError => ({
  code: 'UNKNOWN_ERROR',
  message: 'Something went wrong',
  status: 500,
  ...overrides,
});

export const aValidationError = (field: string, message: string): ApiError =>
  anApiError({
    code: 'VALIDATION_ERROR',
    message,
    status: 400,
    details: { field },
  });

// Usage
const emailError = aValidationError('email', 'Invalid email format');
```

## File Organization

```
__builders__/
├── user.builder.ts
├── order.builder.ts
├── product.builder.ts
└── index.ts          # Re-export all builders

// Or colocate with component
component/
├── component.tsx
├── component.driver.ts
├── component.builder.ts   # Component-specific builders
└── component.spec.ts
```
