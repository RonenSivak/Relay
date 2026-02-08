# Replacement Patterns

Context-specific rules for replacing hard-coded strings with `t()` calls.

---

## JSX Text

```tsx
// Before
<div>Hello World</div>
// After
<div>{t('greeting.hello')}</div>

// With surrounding whitespace — trim it
<Text>  Submit  </Text>
// After
<Text>{t('button.submit')}</Text>
```

## JSX Attributes

```tsx
// String attribute
<Input placeholder="Enter your name" />
// After
<Input placeholder={t('form.name.placeholder')} />

// Already a JSX expression with string
<Button label={"Cancel"} />
// After
<Button label={t('button.cancel')} />
```

## Object Properties

```tsx
// Before
const config = { label: "Submit", description: "Send the form" };
// After
const config = { label: t('button.submit'), description: t('form.description') };
```

## String Constants

**Simple case** — variable used only as plain JSX value:

```tsx
// Before
const TITLE = "Dashboard";
return <Heading>{TITLE}</Heading>;

// After (inline the t() call, remove const if no other references)
return <Heading>{t('page.dashboard.title')}</Heading>;
```

**Complex case** — variable used in logic, concatenation, or outside JSX:

```tsx
// Before
const LABEL = "Items";
const display = showCount ? `${count} ${LABEL}` : LABEL;

// After (replace initializer only)
const LABEL = t('list.items.label');
```

## Parameterized Strings (ICU)

```tsx
// Template literal with single param
<Text>{`Hello ${user.name}`}</Text>
// After
<Text>{t('greeting.hello', { name: user.name })}</Text>

// Multiple positional params
<Text>{`${selected}/${total} items`}</Text>
// After
<Text>{t('list.count', { selectedNum: selected, totalNum: total })}</Text>

// Attribute with template literal
<Input placeholder={`Search in ${projectName}`} />
// After
<Input placeholder={t('search.placeholder', { projectName })} />
```

## Composite Strings (Multi-Key)

When a single string maps to multiple existing keys:

```tsx
// Before
subtitle={`Manage your keys. Hello, ${name}`}
// After
subtitle={`${t('keys.manage')} ${t('greeting.hello', { name })}`}
```

Only skip as `too_complex` when segments can't be individually mapped to existing keys.

## Trans Component (Rich-Text with Embedded JSX)

When a key's value contains numbered tags like `<0>text</0>`, use `Trans` instead of `t()`:

```tsx
// Key value: "Read our <0>terms of service</0>"
// Before
<Text>Read our <a href="/terms">terms of service</a></Text>
// After
<Trans i18nKey="legal.readTerms" components={[<a href="/terms" />]} />

// Key value: "Click <0>here</0> to <1>learn more</1>"
// Before
<Text>Click <TextButton onClick={onClick}>here</TextButton> to <a href="/docs">learn more</a></Text>
// After
<Trans i18nKey="action.clickLearnMore" components={[<TextButton onClick={onClick} />, <a href="/docs" />]} />
```

Import `Trans` from the same package as `useTranslation` (typically `@wix/wix-i18n-config`).

Only use `Trans` when the key contains `<0>...</0>` markup. For plain text, always use `t()`.

## Class Components (withTranslation HOC)

For class components that can't use hooks:

```tsx
// Before
class MyPage extends React.Component<Props> {
  render() {
    return <Heading>Dashboard</Heading>;
  }
}
export default MyPage;

// After
import { withTranslation, WithTranslation } from '@wix/wix-i18n-config';

class MyPage extends React.Component<Props & WithTranslation> {
  render() {
    const { t } = this.props;
    return <Heading>{t('page.dashboard.title')}</Heading>;
  }
}
export default withTranslation()(MyPage);
```

Add `WithTranslation` to the props type, destructure `t` from `this.props`, wrap export with `withTranslation()`.

## Style Rules

- Match existing code style (single vs double quotes, semicolons, indentation)
- `attr="string"` → `attr={t('key')}` (replace quotes with JSX expression)
- `attr={"string"}` → `attr={t('key')}` (replace string inside expression)
- Don't add unnecessary whitespace around `t()` calls
- Preserve existing JSX formatting patterns
