# Common Testing Scenarios

## Table of Contents

1. [Testing Custom Hooks](#testing-custom-hooks)
2. [Async Operations](#async-operations)
3. [Mocking Modules](#mocking-modules)
4. [Mocking APIs](#mocking-apis)
5. [Timer Mocking](#timer-mocking)
6. [Context Providers](#context-providers)
7. [Form Testing](#form-testing)
8. [Event Testing](#event-testing)

---

## Testing Custom Hooks

Use `@testing-library/react` `renderHook`:

```typescript
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should increment counter', () => {
    const { result } = renderHook(() => useCounter(0));

    expect(result.current.count).toBe(0);

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('should handle async operations', async () => {
    const { result } = renderHook(() => useAsyncData());

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toBeDefined();
  });
});
```

---

## Async Operations

### Waiting for Elements

```typescript
// Wait for element to appear
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});

// Wait for element to disappear
await waitFor(() => {
  expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
});

// findBy* methods have built-in waiting
const button = await screen.findByRole('button', { name: 'Submit' });
```

### Waiting for Async State Updates

```typescript
it('should load data on mount', async () => {
  const driver = new ComponentDriver();

  driver.given.rendered().given.apiReturnsData({ items: [1, 2, 3] });

  // Wait for loading to complete
  await waitFor(() => {
    expect(driver.get.isLoading()).toBe(false);
  });

  expect(driver.get.allListItems()).toHaveLength(3);
});
```

---

## Mocking Modules

### Mock Entire Module

```typescript
// At top of test file
jest.mock('./api', () => ({
  fetchUsers: jest.fn(),
  createUser: jest.fn(),
}));

import { fetchUsers, createUser } from './api';

beforeEach(() => {
  jest.clearAllMocks();
});

it('should fetch users', async () => {
  (fetchUsers as jest.Mock).mockResolvedValue([aUser()]);
  // ...
});
```

### Partial Mock

```typescript
jest.mock('./utils', () => ({
  ...jest.requireActual('./utils'),
  formatDate: jest.fn(() => '2024-01-01'),
}));
```

### Mock with Vitest

```typescript
import { vi } from 'vitest';

vi.mock('./api', () => ({
  fetchUsers: vi.fn(),
}));

// Or inline
const mockFetch = vi.fn();
vi.stubGlobal('fetch', mockFetch);
```

---

## Mocking APIs

### Using MSW (Mock Service Worker)

```typescript
import { setupServer } from 'msw/node';
import { rest } from 'msw';

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json([aUser()]));
  }),
  rest.post('/api/users', (req, res, ctx) => {
    return res(ctx.status(201), ctx.json(aUser()));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('should handle API error', async () => {
  server.use(
    rest.get('/api/users', (req, res, ctx) => {
      return res(ctx.status(500), ctx.json({ error: 'Server error' }));
    })
  );

  // Test error handling...
});
```

### Simple Fetch Mock

```typescript
beforeEach(() => {
  global.fetch = jest.fn();
});

it('should fetch data', async () => {
  (global.fetch as jest.Mock).mockResolvedValue({
    ok: true,
    json: async () => ({ data: [aUser()] }),
  });

  // ...
});
```

---

## Timer Mocking

### Jest Fake Timers

```typescript
beforeEach(() => {
  jest.useFakeTimers();
});

afterEach(() => {
  jest.useRealTimers();
});

it('should debounce input', async () => {
  const driver = new SearchDriver();
  driver.given.rendered();

  driver.when.enterSearchText('hello');

  // API not called yet (debounced)
  expect(api.search).not.toHaveBeenCalled();

  // Advance timers past debounce delay
  jest.advanceTimersByTime(300);

  expect(api.search).toHaveBeenCalledWith('hello');
});

it('should show timeout message', () => {
  driver.given.rendered();

  jest.advanceTimersByTime(30000); // 30 seconds

  expect(driver.get.timeoutMessage()).toBe('Session expired');
});
```

### Vitest Fake Timers

```typescript
import { vi } from 'vitest';

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

it('should work with timers', () => {
  vi.advanceTimersByTime(1000);
});
```

---

## Context Providers

### Wrapper for Tests

```typescript
const AllProviders = ({ children }: { children: React.ReactNode }) => (
  <ThemeProvider theme={defaultTheme}>
    <AuthProvider>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </AuthProvider>
  </ThemeProvider>
);

// In driver
given = {
  rendered: (props = {}) => {
    this.wrapper = render(<Component {...props} />, {
      wrapper: AllProviders,
    });
    return this;
  },
};
```

### Override Context Values

```typescript
const MockAuthProvider = ({ children, value }) => (
  <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
);

given = {
  renderedWithAuth: (user: User) => {
    this.wrapper = render(<Component />, {
      wrapper: ({ children }) => (
        <MockAuthProvider value={{ user, isLoggedIn: true }}>
          {children}
        </MockAuthProvider>
      ),
    });
    return this;
  },
};
```

---

## Form Testing

```typescript
it('should validate required fields', async () => {
  const driver = new FormDriver();

  driver.given.rendered().when.clickSubmitButton();

  expect(driver.get.errorForField('email')).toBe('Email is required');
  expect(driver.get.errorForField('password')).toBe('Password is required');
});

it('should submit valid form', async () => {
  const onSubmit = jest.fn();
  const driver = new FormDriver();

  driver
    .given.rendered({ onSubmit })
    .when.enterText('user@example.com', 'Email')
    .when.enterText('password123', 'Password')
    .when.clickSubmitButton();

  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'user@example.com',
      password: 'password123',
    });
  });
});
```

---

## Event Testing

### Keyboard Events

```typescript
when = {
  pressKey: (key: string) => {
    fireEvent.keyDown(document.activeElement!, { key });
    return this;
  },

  pressEnter: () => this.when.pressKey('Enter'),
  pressEscape: () => this.when.pressKey('Escape'),
  pressTab: () => this.when.pressKey('Tab'),
};
```

### User Event (More Realistic)

```typescript
import userEvent from '@testing-library/user-event';

when = {
  typeText: async (text: string) => {
    const user = userEvent.setup();
    await user.type(screen.getByRole('textbox'), text);
    return this;
  },

  clickButton: async (name: string) => {
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name }));
    return this;
  },
};
```
