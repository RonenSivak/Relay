---
name: figma-to-code
description: Convert Figma designs to React code using Wix Design System components. Orchestrates Figma MCP, WDS MCP, Context7, and wix-internal-docs. Use when the user shares a Figma URL, says "implement this design", "figma to code", "build from Figma", "convert design", or references a Figma file/frame.
---

# Figma to Code

Convert Figma designs into production-ready React components using @wix/design-system.

**Approach:** Structure first → pixel-perfect refinement → user feedback.

---

## Phase 1: Parse Figma URL & Fetch Design

### 1a. Extract fileKey and nodeId from URL

Figma URLs follow these patterns:
```
figma.com/design/{fileKey}/{name}?node-id={nodeId}
figma.com/file/{fileKey}/{name}?node-id={nodeId}
```

**Node ID conversion:** URL uses `-` separator, API uses `:` (e.g., URL `1-234` → API `1:234`).

If no node-id in URL, ask the user which frame/component to implement.

### 1b. Fetch design data + visual reference

Run these in parallel:

1. **Get node tree** — use `get-file-nodes(fileKey, ids=nodeId, depth=?)` for specific nodes, or `get-file(fileKey, depth=2)` for the full file
2. **Get screenshot** — use `get-image(fileKey, ids=nodeId, format="png", scale=2)` to get a visual reference

**CRITICAL**: Always fetch the image first. Display it to the user so you both have a shared visual reference throughout the process.

### 1c. If the design is complex (many nested frames)

Fetch deeper with `get-file-nodes(fileKey, ids=nodeId)` without depth limit to get the full subtree.

---

## Phase 2: Analyze Design Structure

Parse the Figma node tree to extract:

| Figma Property | What to Extract |
|----------------|-----------------|
| `type` | Node type: FRAME, TEXT, COMPONENT, INSTANCE, RECTANGLE, etc. |
| `layoutMode` | Auto-layout direction: `HORIZONTAL` → flex-row, `VERTICAL` → flex-col |
| `itemSpacing` | Gap between children |
| `paddingLeft/Right/Top/Bottom` | Container padding |
| `primaryAxisAlignItems` | Main axis alignment (justify-content) |
| `counterAxisAlignItems` | Cross axis alignment (align-items) |
| `characters` | Text content |
| `style` | Font family, size, weight, line height |
| `fills` | Background colors (use `color` object: r/g/b/a, 0-1 range → multiply by 255) |
| `strokes` | Border colors and weight |
| `cornerRadius` | Border radius |
| `effects` | Shadows (DROP_SHADOW), blur |
| `absoluteBoundingBox` | Position and dimensions (width, height) |
| `constraints` | How element resizes (STRETCH, SCALE, etc.) |

### Build a component hierarchy

```
Frame "Header" (HORIZONTAL, gap=12, padding=24)
├── Instance "Logo" → <Image> or custom
├── Frame "Nav" (HORIZONTAL, gap=8)
│   ├── Text "Home" → <TextButton>
│   └── Text "About" → <TextButton>
└── Instance "CTA" → <Button>
```

---

## Phase 3: Map to WDS Components

### 3a. Use WDS component lookup

For each design element, determine the best WDS component:

1. **Use the `wds-docs` skill** if available — follow its staged discovery (grep components.md → props → examples)
2. **Use `wix-design-system-mcp`** tools for component documentation
3. **Use Context7** as fallback for @wix/design-system docs:
   - `resolve-library-id(libraryName="@wix/design-system")` → get library ID
   - `query-docs(libraryId=..., query="how to use Card component")` → get usage examples

### 3b. Quick mapping reference

See [figma-wds-mapping.md](figma-wds-mapping.md) for the full mapping table.

Common patterns:

| Figma Element | WDS Component |
|---------------|---------------|
| Auto-layout frame (container) | `<Box>` with gap/padding SP tokens |
| Text node | `<Text>` or `<Heading>` |
| Filled button | `<Button>` |
| Text-only button | `<TextButton>` |
| Input field | `<FormField>` + `<Input>` |
| Toggle | `<ToggleSwitch>` |
| Card-like frame | `<Card>` |
| Image fill | `<Image>` |
| Modal/overlay | `<Modal>` + `<CustomModalLayout>` |
| Dropdown | `<Dropdown>` |
| Table | `<Table>` |
| Tabs | `<Tabs>` |
| Grid layout | `<Layout>` + `<Cell>` |

### 3c. Spacing: px → SP tokens

| Token | Classic | Studio |
|-------|---------|--------|
| `SP1` | 6px | 4px |
| `SP2` | 12px | 8px |
| `SP3` | 18px | 12px |
| `SP4` | 24px | 16px |
| `SP5` | 30px | 20px |
| `SP6` | 36px | 24px |

Map Figma spacing values to the nearest SP token. Only use SP tokens for `gap`, `padding`, `margin` — not for width/height.

### 3d. Colors

- Check if the Figma color matches a WDS theme color (use `wix-internal-docs` for theme reference)
- If not, use custom CSS with the exact hex value from Figma
- Convert Figma RGBA (0-1 range) → CSS: `rgb(r*255, g*255, b*255)` or hex

### 3e. Typography

Map Figma text styles to WDS `<Text>` and `<Heading>` props:
- `size`: tiny, small, medium, large
- `weight`: thin, normal, bold
- `skin`: standard, disabled, error, success, premium

If the exact style doesn't map to WDS, use custom CSS.

---

## Phase 4: Generate Code

### 4a. Build the component

```tsx
import { Box, Text, Button, Card } from '@wix/design-system';
import { Add } from '@wix/wix-ui-icons-common';

const MyComponent = () => {
  return (
    <Box direction="vertical" gap="SP4" padding="SP6">
      {/* Component tree based on Figma hierarchy */}
    </Box>
  );
};
```

### 4b. Rules

1. **WDS first** — use WDS components for everything that has a match
2. **Custom CSS only for gaps** — what WDS can't express (exact widths, non-standard colors, complex positioning)
3. **SP tokens for spacing** — never hardcode px for gap/padding/margin
4. **Correct imports** — `@wix/design-system` for components, `@wix/wix-ui-icons-common` for icons
5. **Responsive by default** — use `<Layout>` + `<Cell>` for grid layouts, `<Box>` with flex for everything else
6. **Match text content** — use exact text from the Figma `characters` property

### 4c. For non-WDS styling

Use CSS modules or styled-components depending on the project convention:

```tsx
// CSS Module approach
import styles from './MyComponent.module.css';

<div className={styles.customElement}>...</div>
```

---

## Phase 5: Pixel-Perfect Refinement

After generating the initial structure:

1. **Compare visually** — if Chrome DevTools MCP is available, render the component and take a screenshot to compare with the Figma image
2. **Check spacing** — verify gap, padding, margin values match the Figma design
3. **Check typography** — font size, weight, line height, letter spacing
4. **Check colors** — background, text, border colors
5. **Check dimensions** — width, height of key elements
6. **Check border radius** — round corners match

Present the code to the user with the Figma screenshot side-by-side for comparison.

---

## Phase 6: User Feedback Loop

After presenting the initial implementation:

1. Ask the user if the structure looks correct
2. Iterate on specific areas they flag
3. For pixel-perfect adjustments, focus on the exact properties they mention

---

## Error Handling

| Issue | Resolution |
|-------|------------|
| Figma URL has no node-id | Ask user which frame/component to implement |
| Node tree is too deep/complex | Break into sub-components, implement one at a time |
| No WDS match for element | Use custom HTML + CSS, document why |
| Figma uses components not in WDS | Check Context7/internal-docs for alternatives |
| Colors don't match theme | Use exact hex from Figma as custom CSS |

---

## MCP Tool Quick Reference

| Task | MCP Server | Tool |
|------|------------|------|
| Get file structure | Figma (MCP-S) | `get-file(fileKey)` |
| Get specific nodes | Figma (MCP-S) | `get-file-nodes(fileKey, ids)` |
| Get visual screenshot | Figma (MCP-S) | `get-image(fileKey, ids, format, scale)` |
| WDS component docs | wix-design-system-mcp | (server tools) |
| Library docs | Context7 | `resolve-library-id` → `query-docs` |
| Internal docs/theme | wix-internal-docs | (search tools) |
| Visual comparison | chrome-devtools | `take_screenshot` |
