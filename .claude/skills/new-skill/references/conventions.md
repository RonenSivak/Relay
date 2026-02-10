# Skill Conventions

Distilled from [Anthropic's Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf), the [Wix coding-agents-handbook](https://github.com/wix-private/coding-agents-handbook), and [Anthropic skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

---

## File Structure

```
your-skill-name/
  SKILL.md            # Required — main instructions
  scripts/            # Optional — executable code (Python, Bash)
  references/         # Optional — detailed docs loaded on-demand
  assets/             # Optional — templates, fonts, icons
```

**Critical rules:**
- File must be exactly `SKILL.md` (case-sensitive). Not `SKILL.MD`, `skill.md`, or `Skill.md`.
- Folder must use kebab-case: `notion-project-setup` (not `Notion Project Setup`, `notion_project_setup`, `NotionProjectSetup`)
- No `README.md` inside the skill folder. All documentation goes in SKILL.md or references/
- Folder name must match the `name` field in frontmatter

---

## YAML Frontmatter

The frontmatter is how Claude decides whether to load the skill. This is the most important part.

### Required Fields

```yaml
---
name: skill-name-in-kebab-case
description: What it does and when to use it. Include specific trigger phrases.
---
```

**`name`:**
- kebab-case only, no spaces or capitals
- Must match the folder name
- Never use "claude" or "anthropic" (reserved)

**`description`:**
- Must include BOTH what the skill does AND when to use it
- Under 1024 characters
- No XML angle brackets (`<` or `>`)
- Include specific trigger phrases users would say
- Mention file types if relevant

### Optional Fields

```yaml
license: MIT                    # Open-source license
compatibility: "Requires Node 18+"  # 1-500 chars, environment requirements
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"  # Restrict tool access
metadata:
  author: Team Name
  version: 1.0.0
  mcp-server: server-name
  category: productivity
  tags: [project-management, automation]
```

### Forbidden

- XML angle brackets (`<` or `>`) anywhere in frontmatter
- Names containing "claude" or "anthropic" (reserved)
- Unclosed quotes in description
- Missing `---` delimiters

---

## Description Formula

Structure: `[What it does] + [When to use it] + [Key capabilities]`

### Good Descriptions

```yaml
# Specific and actionable
description: Analyzes Figma design files and generates developer handoff
  documentation. Use when user uploads .fig files, asks for "design specs",
  "component documentation", or "design-to-code handoff".

# Includes trigger phrases
description: Manages Linear project workflows including sprint planning,
  task creation, and status tracking. Use when user mentions "sprint",
  "Linear tasks", "project planning", or asks to "create tickets".

# Clear value proposition with negative triggers
description: Advanced data analysis for CSV files. Use for statistical
  modeling, regression, clustering. Do NOT use for simple data exploration
  (use data-viz skill instead).
```

### Bad Descriptions

```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated multi-page documentation systems.

# Too technical, no user triggers
description: Implements the Project entity model with hierarchical relationships.
```

### Trigger Tuning

- **Under-triggering** (skill doesn't load when it should): Add more keywords, trigger phrases, file type mentions
- **Over-triggering** (skill loads for unrelated queries): Add negative triggers, narrow scope, clarify boundaries
- **Debug technique**: Ask Claude "When would you use the [skill name] skill?" — it will quote the description back. Adjust based on what's missing.

---

## Progressive Disclosure (3 Levels)

Skills use a three-level system to minimize token usage:

| Level | What | When Loaded | Content |
|-------|------|-------------|---------|
| 1 | YAML frontmatter | Always (system prompt) | Just enough to know when to use the skill |
| 2 | SKILL.md body | When skill is relevant | Full instructions and guidance |
| 3 | Linked files | On demand | Reference docs, examples, detailed guides |

**Key principle**: Keep SKILL.md focused on core instructions. Move detailed documentation to `references/` and link to it. References should be one level deep — don't nest references that link to other references.

**Size target**: SKILL.md under 500 lines / 5,000 words.

---

## Instruction Quality

### Be Specific and Actionable

```markdown
# Good
CRITICAL: Before calling create_project, verify:
- Project name is non-empty
- At least one team member assigned
- Start date is not in the past

# Bad
Make sure to validate things properly.
```

### Structure

Recommended SKILL.md sections:
1. **Overview** — what the skill does
2. **Instructions** — step-by-step workflow with clear steps
3. **Examples** — concrete scenarios with expected output
4. **Troubleshooting** — common errors and fixes
5. **Error Handling** — what to do when things fail

### Writing Tips

- Put critical instructions at the top
- Use `## Important` or `## Critical` headers for key points
- Use bullet points and numbered lists (not long paragraphs)
- Reference bundled resources clearly with relative paths
- Include expected output for scripts and commands
- For critical validations, bundle a script rather than relying on language instructions — code is deterministic, language interpretation isn't

---

## 5 Skill Patterns

From Anthropic's guide — choose the pattern that best fits the workflow:

### Pattern 1: Sequential Workflow Orchestration

**Use when**: Multi-step processes in a specific order.

Key techniques: explicit step ordering, dependencies between steps, validation at each stage, rollback instructions for failures.

### Pattern 2: Multi-MCP Coordination

**Use when**: Workflows span multiple services (Figma + Linear + Slack).

Key techniques: clear phase separation, data passing between MCPs, validation before moving to next phase, centralized error handling.

### Pattern 3: Iterative Refinement

**Use when**: Output quality improves with iteration.

Key techniques: explicit quality criteria, validation scripts, refinement loop, know when to stop iterating.

### Pattern 4: Context-Aware Tool Selection

**Use when**: Same outcome requires different tools depending on context.

Key techniques: clear decision criteria with decision tree, fallback options, transparency about choices.

### Pattern 5: Domain-Specific Intelligence

**Use when**: Skill adds specialized knowledge beyond tool access.

Key techniques: domain expertise embedded in logic, compliance/validation before action, comprehensive documentation, clear governance.

---

## Composability & Portability

- Skills should work well alongside other skills — don't assume exclusive capability
- Skills work across Claude.ai, Claude Code, Cursor, and API (provided environment supports dependencies)
- Note environment requirements in `compatibility` field

---

## AGENTS.md Integration

From the coding-agents-handbook:

- **Skills work best for action-specific workflows** that users explicitly trigger
- **AGENTS.md is better for broad conventions** (coding style, architecture decisions) — passive context is more reliable than on-demand retrieval
- Mentioning a skill in AGENTS.md increases the likelihood the agent will invoke it
- Register new skills in the AGENTS.md that corresponds to the target location

### Registration Format

```markdown
| **skill-name** | Brief description of when to use | [SKILL.md](.claude/skills/skill-name/SKILL.md) |
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vague description | Add trigger phrases and specific capabilities |
| SKILL.md too large (>500 lines) | Move detailed content to references/ |
| Missing error handling | Add troubleshooting section |
| No examples | Add 2-3 concrete usage examples |
| Nested references (refs linking to other refs) | Keep references one level deep |
| Inconsistent terminology | Pick one term and use it throughout |
| Time-sensitive information | Use "current method" vs "old patterns" sections |
| Too many options without default | Provide a default with escape hatch |
