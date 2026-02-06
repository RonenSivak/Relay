# Driver Pattern

The driver encapsulates all test logic, making specs readable and maintainable.

## Structure

```typescript
import { render, screen, fireEvent, waitFor, RenderResult } from '@testing-library/react';
import { ComponentUnderTest, Props } from './component';

export class ComponentDriver {
  private wrapper: RenderResult | null = null;

  // ============================================
  // GIVEN - Setup and preconditions
  // All methods return `this` for chaining
  // ============================================
  given = {
    rendered: (props: Partial<Props> = {}) => {
      const defaultProps: Props = {
        // sensible defaults
      };
      this.wrapper = render(
        <ComponentUnderTest {...defaultProps} {...props} />
      );
      return this;
    },

    userIsLoggedIn: () => {
      // Mock auth context or state
      jest.spyOn(authService, 'isLoggedIn').mockReturnValue(true);
      return this;
    },

    apiReturnsData: (data: any) => {
      jest.spyOn(api, 'fetchData').mockResolvedValue(data);
      return this;
    },

    apiReturnsError: (error = new Error('API Error')) => {
      jest.spyOn(api, 'fetchData').mockRejectedValue(error);
      return this;
    },

    timerAdvanced: (ms: number) => {
      jest.advanceTimersByTime(ms);
      return this;
    },
  };

  // ============================================
  // WHEN - Actions and interactions
  // All methods return `this` for chaining
  // ============================================
  when = {
    clickSubmitButton: () => {
      fireEvent.click(this.get.submitButton());
      return this;
    },

    enterText: (text: string, placeholder = 'Enter text') => {
      fireEvent.change(screen.getByPlaceholderText(placeholder), {
        target: { value: text },
      });
      return this;
    },

    pressEnter: () => {
      fireEvent.keyDown(document.activeElement!, { key: 'Enter' });
      return this;
    },

    blur: () => {
      fireEvent.blur(document.activeElement!);
      return this;
    },

    waitForLoading: async () => {
      await waitFor(() => {
        expect(this.get.isLoading()).toBe(false);
      });
      return this;
    },

    waitForElement: async (testId: string) => {
      await waitFor(() => {
        expect(screen.getByTestId(testId)).toBeInTheDocument();
      });
      return this;
    },
  };

  // ============================================
  // GET - Queries and assertions helpers
  // Return actual values (not `this`)
  // ============================================
  get = {
    submitButton: () => screen.getByRole('button', { name: /submit/i }),

    errorMessage: () => screen.queryByTestId('error-message')?.textContent,

    isLoading: () => screen.queryByTestId('loading') !== null,

    inputValue: (placeholder: string) =>
      (screen.getByPlaceholderText(placeholder) as HTMLInputElement).value,

    allListItems: () => screen.getAllByRole('listitem'),

    isDisabled: (element: HTMLElement) => element.hasAttribute('disabled'),
  };

  // ============================================
  // Cleanup
  // ============================================
  cleanup() {
    this.wrapper?.unmount();
    jest.restoreAllMocks();
  }
}
```

## Usage Example

```typescript
describe('LoginForm', () => {
  let driver: LoginFormDriver;

  beforeEach(() => {
    driver = new LoginFormDriver();
  });

  afterEach(() => {
    driver.cleanup();
  });

  it('should submit form with valid credentials', async () => {
    driver
      .given.rendered()
      .given.apiReturnsData({ token: 'abc123' })
      .when.enterText('user@example.com', 'Email')
      .when.enterText('password123', 'Password')
      .when.clickSubmitButton();

    await driver.when.waitForLoading();

    expect(driver.get.errorMessage()).toBeUndefined();
  });

  it('should show error on API failure', async () => {
    driver
      .given.rendered()
      .given.apiReturnsError()
      .when.enterText('user@example.com', 'Email')
      .when.enterText('password123', 'Password')
      .when.clickSubmitButton();

    await driver.when.waitForLoading();

    expect(driver.get.errorMessage()).toBe('Login failed');
  });
});
```

## Chaining Tips

- `given` and `when` methods return `this` for chaining
- `get` methods return values for assertions
- Break chain before `get` calls:

```typescript
// Good
driver.given.rendered().when.clickSubmitButton();
expect(driver.get.errorMessage()).toBe('Required');

// Also good - async chain
await driver
  .given.rendered()
  .when.clickSubmitButton()
  .when.waitForLoading();

expect(driver.get.isLoading()).toBe(false);
```

## Extending for Specific Components

Create component-specific drivers by extending or composing:

```typescript
export class UserProfileDriver extends ComponentDriver {
  given = {
    ...super.given,
    withUserData: (user: User) => {
      // component-specific setup
      return this;
    },
  };
}
```
