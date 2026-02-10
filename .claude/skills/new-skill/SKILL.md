---
name: new-skill
description: Creates and updates agent skills following Anthropic's official conventions and Wix coding-agents-handbook best practices. Supports both create (new skill from scratch) and update (audit + fix existing skill) modes. Optional brainstorming and subagent architecture integration. Use when the user says "create skill", "new skill", "update skill", "audit skill", "fix skill conventions", "make a skill", or wants to build or improve an agent skill.
---

# New Skill

Create or update agent skills following best practices from Anthropic's skill guide, the Wix coding-agents-handbook, and proven Relay patterns.

## Modes

- **Create**: Build a new skill from scratch with proper structure, frontmatter, and conventions
- **Update**: Audit an existing skill against conventions, report issues, apply fixes

Detect mode from user intent. If ambiguous, ask.

---

## Create Mode

### Step 1 — Brainstorm (optional)

Ask the user whether they'd like to brainstorm the skill design first. Use `AskQuestion`:

| Option | Action |
|--------|--------|
| **Yes, brainstorm first** | Read and follow the [brainstorming skill](.claude/skills/brainstorming/SKILL.md). Complete brainstorming, then return here for Step 2 |
| **No, I know what I want** | Proceed directly to Step 2 |

### Step 2 — Gather Requirements

Collect the following (via questions + codebase exploration):

1. **Purpose**: What specific task or workflow does this skill handle?
2. **Trigger scenarios**: When should the agent use it? What would the user say?
3. **Domain knowledge**: What does the agent need to know that it wouldn't already?
4. **Tools needed**: Built-in capabilities, MCP servers, or scripts?
5. **Output format**: Templates, checklists, code patterns?
6. **Existing patterns**: Are there similar skills or conventions to follow?

Use `AskQuestion` for structured choices when possible. One question at a time.

### Step 3 — Choose Target Location

Ask the user where to place the skill. Use `AskQuestion`:

| Option | Path | Scope |
|--------|------|-------|
| **Local Claude Code** | `.claude/skills/<name>/` in current project | Project-scoped, Claude Code |
| **Local Cursor** | `.cursor/skills/<name>/` in current project | Project-scoped, Cursor |
| **Global Claude Code** | `~/.claude/skills/<name>/` | All projects, Claude Code |
| **Global Cursor** | `~/.cursor/skills/<name>/` | All projects, Cursor |
| **Custom path** | User specifies | User-defined |

Write only to the chosen location.

### Step 4 — Design

Before writing any files, design the skill:

1. **Name**: kebab-case, matches folder name (e.g., `api-discovery`, `code-review`)
2. **Description**: Follow the formula: `[What it does] + [When to use it] + [Trigger phrases]`
   - Under 1024 characters
   - Include specific phrases users would say
   - Add negative triggers if scope needs clarity
3. **Section outline**: Plan which sections SKILL.md needs
4. **Complexity decision**: Does this need `references/`, `scripts/`, or `assets/`?

Read [references/conventions.md](references/conventions.md) for the full rules on frontmatter, descriptions, and structure.

Present the design to the user for approval before implementing.

### Step 5 — Subagent Architecture (optional)

Ask the user whether the skill should use subagent architecture. Use `AskQuestion`:

| Option | Action |
|--------|--------|
| **Yes, add subagents** | Read and follow the [adopt-subagent-flow skill](.claude/skills/adopt-subagent-flow/SKILL.md). Apply the 4-step restructure (Setup, Plan, Execute, Verify) with plan.md + def-done.md |
| **No, single-agent** | Standard skill without parallel subagent dispatch |

Only offer subagents when the skill has repeatable, parallelizable units of work. If the skill is simple (single workflow, no parallelism), recommend "No" and explain why.

### Step 6 — Implement

Create the skill files in the chosen location:

```
<name>/
  SKILL.md           # Required
  references/        # If needed
    <topic>.md
  scripts/           # If needed
    <script>.sh
  assets/            # If needed
    <template>.md
```

**SKILL.md structure** (adapt as needed):

```markdown
---
name: <kebab-case-name>
description: <WHAT + WHEN + triggers, under 1024 chars>
---

# <Skill Name>

## Overview
Brief description of what this skill does.

## Instructions
Step-by-step workflow.

### Step 1: <First Step>
Clear, actionable explanation.

### Step 2: <Next Step>
...

## Examples
Concrete usage examples with expected output.

## Troubleshooting
Common errors and fixes.

## Error Handling
What to do when things fail.
```

**Key rules while writing**:
- SKILL.md must be under 500 lines / 5000 words
- Move detailed docs to `references/` and link to them
- Be specific and actionable (not "validate properly" but "verify X, Y, Z")
- Put critical instructions at the top
- No README.md inside the skill folder
- No XML angle brackets in frontmatter

### Step 7 — Verify

Validate the created skill against the full checklist. Read [references/checklist.md](references/checklist.md) and check every item.

If any check fails: fix the issue, re-verify. Loop until all checks pass.

Present the final result to the user with:
- Skill location
- Name and description
- File structure created
- Any notable design decisions

---

## Update Mode

### Step 1 — Read

Read the existing SKILL.md the user wants to update. Identify:
- Current frontmatter fields
- Description quality
- Overall structure
- Line count
- Reference file organization

### Step 2 — Audit

Read [references/conventions.md](references/conventions.md) and compare the existing skill against every rule. Categorize findings:

| Severity | Meaning | Action |
|----------|---------|--------|
| **Critical** | Breaks functionality or violates hard rules (missing frontmatter, wrong casing, XML tags) | Must fix |
| **Suggestion** | Improves quality (vague description, missing triggers, no error handling) | Should fix |
| **Nice-to-have** | Polish (could add examples, move content to references) | Optional |

### Step 3 — Report

Present findings to the user as a table:

```markdown
| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| 1 | Critical | Missing `---` delimiters in frontmatter | Add YAML delimiters |
| 2 | Suggestion | Description missing trigger phrases | Add "Use when..." with specific phrases |
| 3 | Nice-to-have | SKILL.md is 620 lines | Move troubleshooting to references/ |
```

### Step 4 — Apply Fixes

Apply all Critical and Suggestion fixes. For Nice-to-have items, ask the user.

If the skill would benefit from subagent architecture, ask using `AskQuestion` (same as Create Step 5).

### Step 5 — Verify

Run the full checklist from [references/checklist.md](references/checklist.md). Fix any remaining issues. Present the updated skill summary.

---

## Conventions Reference

For the full set of rules, read [references/conventions.md](references/conventions.md) on demand. Key points:

- **Frontmatter**: `name` (kebab-case) + `description` (WHAT + WHEN + triggers) are required
- **Progressive disclosure**: 3 levels — frontmatter (always loaded), SKILL.md body (on relevance), linked files (on demand)
- **Size limit**: SKILL.md under 500 lines. Move details to `references/`
- **Description formula**: `[What it does] + [When to use it] + [Key capabilities]`
- **5 Anthropic patterns**: Sequential workflow, Multi-MCP coordination, Iterative refinement, Context-aware tool selection, Domain-specific intelligence

## Red Flags

**Never:**
- Create a skill without proper YAML frontmatter (`---` delimiters, `name`, `description`)
- Use XML angle brackets in frontmatter
- Use "claude" or "anthropic" in the skill name
- Include README.md inside the skill folder
- Write a vague description ("Helps with projects")
- Skip the target location question — always ask the user
- Skip verification against the checklist
- Exceed 500 lines in SKILL.md without moving content to references

## Error Handling

- **User unsure about requirements**: Recommend brainstorming (Step 1)
- **Skill too large**: Split into SKILL.md + references, suggest which sections to extract
- **Subagent architecture unclear**: Explain when subagents help (parallelizable, repeatable units) vs. when they don't (simple linear workflows)
- **Existing skill has no frontmatter**: Add it — this is Critical severity
