# ICU Parameter Guide

How to detect, match, and generate `t()` calls for ICU parameterized strings.

---

## Detecting ICU Parameters in Babel Keys

When reading `messages_en.json`, scan each value for ICU placeholders:

- `{name}` → simple parameter
- `{count, plural, one {# item} other {# items}}` → plural parameter
- `{gender, select, male {He} female {She} other {They}}` → select parameter

Wix also uses **date, time, and number formatting**:

- `{num, number}` → formatted number (e.g., 23,544,556)
- `{date, date, short}` → short date format
- `{date, date, medium}` → medium date (short month name)
- `{date, date, long}` → long date (full month name)
- `{date, date, full}` → full date with day of week
- `{time, time, short}` → hours and minutes
- `{time, time, medium}` → hours, minutes, seconds
- `{time, time, long}` → with timezone

### Brace Convention

Projects use one of two conventions depending on their i18n backend:

- **ICU (single-brace)**: `{name}` = parameter — used by `@wix/wix-i18n-config`, Babel 3
- **i18next (double-brace)**: `{{name}}` = parameter — used by some `@wix/fed-cli-i18next` projects

Check the existing `messages_en.json` to determine which convention the project uses. In ICU mode, double-brace `{{name}}` is literal text (not a parameter).

---

## Matching Code Strings to ICU Keys

### Simple Interpolation (no plural/select)

Match by structure:
1. **Static text** must match (case-insensitive)
2. **Parameter count** must match: number of `${...}` == number of `{...}` ICU args
3. **Positional alignment**: Map expressions to ICU params left-to-right

```
Code:   `${counter}/${total} Instances`
Key:    "{selectedNum}/{totalNum} instances"
Result: ACCEPT → { selectedNum: counter, totalNum: total }
```

Names don't need to match — positions do. Only reject if types clearly conflict.

### Full ICU (plural/select)

Stricter rules:
- Parameter **names** must match exactly
- ICU structure must be safe (single plural, no deep nesting)
- Complex code expressions are fine — infer name from last property segment

### Skip Reasons

| Reason | When |
|--------|------|
| `param_mismatch` | Parameter counts don't align |
| `cannot_infer_params` | Can't determine parameter names from code |
| `complex_icu_format` | Multiple plurals, deep nesting |

**Never** mark simple parameterized strings as "too complex".

---

## Parameter Name Inference

From code expressions, infer ICU parameter names:

| Expression pattern | Inferred name |
|-------------------|--------------|
| `.length`, `.size`, `.count` | `count` |
| `.name`, `.title`, `.label` | `name` |
| `.date`, `.time`, `.timestamp` | `date` |
| `.price`, `.cost`, `.amount` | `price` |
| `.id`, `.key`, `.uuid` | `id` |
| Known names (`count`, `name`, `id`) | keep as-is |
| Fallback | last property segment (`user.profile.displayName` → `displayName`) |

---

## Generating t() Calls

```typescript
// Simple parameter
t('greeting.hello', { name: user.name })

// Multiple parameters
t('list.count', { selectedNum: selected, totalNum: total })

// Plural
t('cart.items', { count: items.length })
```

Rules:
- Use ICU parameter names from the babel key (not the code variable name)
- Keep expressions as-is — don't simplify `user.profile.displayName`
- Always pass a flat object: `{ name, count }`, never nested

---

## Date/Time/Number Formatting

For keys with date/time/number ICU formats, pass the raw value — the i18n library handles formatting:

```typescript
// Number formatting: key = "Total: {amount, number}"
t('order.total', { amount: order.totalPrice })

// Date formatting: key = "Created on {date, date, medium}"
t('item.created', { date: item.createdAt })

// Time formatting: key = "Last seen {time, time, short}"
t('user.lastSeen', { time: user.lastSeenAt })
```

Pass `Date` objects or timestamps — don't pre-format them.
