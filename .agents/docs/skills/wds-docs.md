# WDS Docs

## Purpose
Wix Design System component reference. Provides access to WDS component documentation, props, examples, and usage patterns for building UI with @wix/design-system.

## When to Use
- Building UI components with Wix Design System
- Need to know which component to use for a specific UI pattern
- Checking component props, variants, or API
- Looking for usage examples or best practices
- Execute phase: when implementing UI following WDS patterns

## Inputs
- Component name or UI pattern query
- Specific questions about props or usage
- Design requirements (accessibility, responsive, etc.)

## Outputs
- Component documentation and API reference
- Props and variants available
- Usage examples and code snippets
- Best practices for the requested component

## Workflow Integration
- **Typically preceded by**: brainstorming (design validated)
- **Typically followed by**: Implementation and verification
- **Chains output to**: Component usage becomes part of implementation

## Example Usage
```
User: "Add a logout button to the user profile"
Agent (after brainstorming):
  - Uses /wds-docs to check Button component
  - Finds: Button props (skin, priority, size)
  - Chooses: <Button skin="inverted" priority="secondary">
Output: Correct WDS Button implementation with proper props
```

## Key Features
- **Component catalog** - Search by name or UI pattern
- **Props reference** - Complete API documentation
- **Examples** - Real-world usage patterns
- **Best practices** - Accessibility, responsive design, theming

## Complete Documentation
- Full SKILL.md: `skills/wds-docs/SKILL.md`
- Skill best practices: [Anthropic guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
