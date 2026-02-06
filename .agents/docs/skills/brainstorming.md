# Brainstorming

## Purpose
Collaborative design exploration before implementation. Turns ideas into fully formed designs through natural dialogue, exploring user intent, requirements, and approaches before any code is written.

## When to Use
- **ALWAYS use FIRST** in the Clarify step of every workflow
- User wants to create features, build components, add functionality
- User wants to modify behavior or refactor
- Before any creative or design work
- When requirements are unclear or need exploration

## Inputs
- User's initial idea or request
- Current project context (files, docs, recent commits)
- Design constraints or preferences

## Outputs
- Validated design document
- Clear requirements and success criteria
- Chosen approach with trade-offs explained
- Design document saved to `docs/plans/YYYY-MM-DD-<topic>-design.md`

## Workflow Integration
- **Typically preceded by**: User request
- **Typically followed by**: Planning step (create implementation plan)
- **Chains output to**: Design becomes input for plan.md creation

## Example Usage
```
User: "Add a logout button to the user profile"
Agent: Uses /brainstorming skill
Process:
  - Asks about placement, styling, behavior
  - Explores alternatives (icon only vs text+icon)
  - Validates design with user
Output: Validated design ready for implementation planning
```

## Key Features
- **One question at a time** - Doesn't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended
- **Incremental validation** - Presents design in sections, validates each
- **YAGNI ruthless** - Removes unnecessary features from designs

## Complete Documentation
- Full SKILL.md: `skills/brainstorming/SKILL.md`
- Skill best practices: [Anthropic guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
