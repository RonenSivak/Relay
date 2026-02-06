# Figma → WDS Component Mapping Reference

## Layout Containers

| Figma Node | Detection | WDS Component | Props |
|------------|-----------|---------------|-------|
| Frame with `layoutMode: VERTICAL` | Auto-layout vertical | `<Box direction="vertical">` | `gap`, `padding`, `align` |
| Frame with `layoutMode: HORIZONTAL` | Auto-layout horizontal | `<Box direction="horizontal">` | `gap`, `padding`, `align`, `verticalAlign` |
| Frame without auto-layout | Fixed positioning | `<Box>` or raw `<div>` with CSS | Use absolute positioning if needed |
| Grid of equal items | Repeated children, wrap | `<Layout>` + `<Cell>` | `cols`, `gap`, `justifyItems` |
| Scrollable area | `overflowScrolling` set | `<Box>` with `overflow="auto"` CSS | — |

## Figma Auto-Layout → Box Props

| Figma Property | WDS Box Prop |
|----------------|-------------|
| `layoutMode: VERTICAL` | `direction="vertical"` |
| `layoutMode: HORIZONTAL` | `direction="horizontal"` |
| `itemSpacing: N` | `gap="SP?"` (map px to nearest SP token) |
| `paddingLeft/Right/Top/Bottom` | `padding="SP?"` (if uniform) or per-side CSS |
| `primaryAxisAlignItems: CENTER` | `align="center"` |
| `primaryAxisAlignItems: SPACE_BETWEEN` | `align="space-between"` |
| `counterAxisAlignItems: CENTER` | `verticalAlign="middle"` |
| `layoutGrow: 1` on child | `flexGrow={1}` or CSS `flex: 1` |
| `layoutAlign: STRETCH` on child | `width="100%"` or CSS `align-self: stretch` |

## Text

| Figma Node | Detection | WDS Component | Props |
|------------|-----------|---------------|-------|
| Text, large/bold | `fontSize >= 24` or heading role | `<Heading>` | `appearance="H1"` through `"H6"` |
| Text, body | Regular text | `<Text>` | `size`, `weight`, `skin`, `secondary` |
| Text, caption/small | `fontSize <= 12` | `<Text size="tiny">` | `secondary`, `skin` |
| Text, colored | Non-black fill | `<Text>` + custom `style={{ color }}` | Or `skin` if it matches |

### Heading Size Mapping

| Figma fontSize (approx) | WDS Heading |
|--------------------------|-------------|
| 36px+ | `appearance="H1"` |
| 28-35px | `appearance="H2"` |
| 24-27px | `appearance="H3"` |
| 20-23px | `appearance="H4"` |
| 16-19px | `appearance="H5"` |
| 14-15px | `appearance="H6"` |

### Text Size Mapping

| Figma fontSize (approx) | WDS Text |
|--------------------------|----------|
| 10-11px | `size="tiny"` |
| 12-13px | `size="small"` |
| 14-15px | `size="medium"` (default) |
| 16px+ | `size="large"` |

## Buttons

| Figma Node | Detection | WDS Component | Props |
|------------|-----------|---------------|-------|
| Filled rectangle + text | Solid fill, centered text | `<Button>` | `skin`, `size`, `priority` |
| Outlined rectangle + text | Stroke only, no fill | `<Button priority="secondary">` | — |
| Text-only clickable | No background | `<TextButton>` | `size`, `skin`, `underline` |
| Icon + text button | Icon instance + text | `<Button prefixIcon={<Icon/>}>` | — |
| Icon-only button | Single icon, clickable | `<IconButton>` | `skin`, `size` |
| Close button (X) | X icon in corner | `<CloseButton>` | `size`, `skin` |

### Button Skin Mapping

| Figma Fill Color | WDS Skin |
|------------------|----------|
| Blue (#3899EC) | `skin="standard"` (default) |
| Dark (#162D3D) | `skin="dark"` |
| Green (#60BC57) | `skin="premium"` |
| Red (#EE5951) | `skin="destructive"` |
| Transparent + blue text | `skin="inverted"` |
| Light background | `skin="light"` |

## Form Elements

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Input field | Rectangle + placeholder text | `<FormField><Input /></FormField>` |
| Text area | Tall input, multiline | `<FormField><InputArea /></FormField>` |
| Dropdown | Input + chevron icon | `<FormField><Dropdown /></FormField>` |
| Checkbox | Small square + text | `<Checkbox>` |
| Radio | Small circle + text | `<RadioGroup>` |
| Toggle | Pill-shaped switch | `<ToggleSwitch>` |
| Search | Input + search icon | `<Search>` |
| Date input | Input + calendar icon | `<DatePicker>` |
| Color input | Input + color swatch | `<ColorInput>` |

## Data Display

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Table rows | Repeated row frames | `<Table>` |
| Tags/chips | Small rounded rectangles + text | `<Tag>` |
| Badge/count | Small circle with number | `<Badge>` or `<CounterBadge>` |
| Avatar/circle image | Circle with image | `<Avatar>` |
| Progress bar | Thin horizontal filled bar | `<LinearProgressBar>` |
| Circular progress | Ring shape | `<CircularProgressBar>` |
| Tooltip | Small popup near element | `<Tooltip>` |
| Popover | Larger popup with content | `<Popover>` |

## Navigation & Structure

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Tab bar | Horizontal text items, one active | `<Tabs>` |
| Sidebar menu | Vertical list with icons | `<SidebarNext>` |
| Breadcrumbs | Text > Text > Text pattern | `<Breadcrumbs>` |
| Page header | Top frame with title + actions | `<Page.Header>` |
| Full page layout | Frame with header + content | `<Page>` + `<Page.Content>` |

## Feedback & Overlays

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Modal/dialog | Centered overlay with backdrop | `<Modal>` + `<CustomModalLayout>` |
| Toast/notification | Small floating rectangle | `<Notification>` |
| Alert banner | Full-width colored bar | `<SectionHelper>` |
| Loading spinner | Circular animation | `<Loader>` |
| Empty state | Centered text + illustration | `<EmptyState>` |
| Skeleton | Gray placeholder shapes | `<SkeletonGroup>` + `<SkeletonLine>` |

## Media

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Image | Image fill or image node | `<Image>` |
| Thumbnail | Small image in grid | `<Thumbnail>` |
| Carousel | Horizontal scrollable images | `<Carousel>` |

## Dividers & Decoration

| Figma Node | Detection | WDS Component |
|------------|-----------|---------------|
| Horizontal line | Line node or thin rectangle | `<Divider>` |
| Vertical line | Vertical thin element | `<Divider direction="vertical">` |
| Card container | Rounded rectangle with shadow | `<Card>` |
| Accordion | Collapsible sections | `<Accordion>` |

## Icons

All icons come from `@wix/wix-ui-icons-common`:

```tsx
import { Add, Edit, Delete, Search, ChevronDown } from '@wix/wix-ui-icons-common';
```

To find the right icon name, match the Figma icon visual to the icon name. Common ones:
- Plus/add → `Add`
- Pencil/edit → `Edit`
- Trash → `Delete`
- Magnifier → `Search`
- Arrow down → `ChevronDown`
- X/close → `Close`
- Check → `Confirm`
- Info circle → `InfoCircle`
- Warning → `StatusWarning`
- Drag handle → `DragAndDrop`

Use `wds-docs` skill Stage 4 (grep icons.md) to find specific icon names.
