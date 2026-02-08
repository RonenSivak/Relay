---
name: rule-to-skill
description: Convert existing Cursor rules (.mdc files), commands, or ad-hoc instructions into properly structured Agent Skills. Use when the user wants to promote a rule to a skill, convert instructions into a reusable skill, or says "make this a skill", "convert rule", "rule to skill", or "promote to skill".
---

# Rule-to-Skill Converter

Convert rules, commands, or instructions into structured, reusable Agent Skills following create-skill best practices.

## When to Use

- **Rule promotion**: A `.mdc` rule has grown too complex or needs scripts/references
- **Command capture**: Turn a repeated command/workflow into a persistent skill
- **Instruction formalization**: Convert ad-hoc agent instructions into a reusable skill

## Conversion Process

### Step 0: Brainstorm First

**ALWAYS** invoke the [brainstorming skill](../brainstorming/SKILL.md) before starting conversion. Use it to:
- Clarify what the user actually wants converted (the source material may be ambiguous)
- Explore whether a skill is the right format (vs keeping it as a rule)
- Validate the scope — should it cover more or less than the literal input?
- Surface design decisions early (scripts? references? split into multiple skills?)

### Step 1: Identify the Source

Determine what you're converting:

| Source | How to gather |
|--------|--------------|
| `.mdc` rule file | Read the file from `.cursor/rules/` |
| Pasted content | Use the text provided by the user |
| Command/workflow | Extract from conversation context or user description |
| Agent transcript | Parse the workflow from a previous conversation |

### Step 2: Analyze the Content

Extract these elements from the source material:

1. **Core purpose** — What task or behavior does this enforce/enable?
2. **Domain knowledge** — What specialized info does the agent need?
3. **Trigger scenarios** — When should this skill activate?
4. **Workflow steps** — Is there a sequence of actions?
5. **Scripts needed** — Are there commands or automations worth scripting?
6. **Examples** — Are there concrete examples or patterns?

### Step 3: Ask Clarifying Questions

Use AskQuestion to resolve unknowns:

- **Skill name**: Suggest a name based on the content; confirm with the user
- **Storage location**: Personal (`~/.cursor/skills/`) vs Project (`.cursor/skills/`)
- **Scope expansion**: "Should this skill also cover [related concern]?"
- **Script needs**: "This workflow has repeatable commands. Should I create utility scripts?"

Skip questions you can confidently infer from context.

### Step 4: Map to Skill Structure

Follow the mapping in [references/conversion-guide.md](references/conversion-guide.md).

**Key structural decisions:**

| Source characteristic | Skill structure |
|----------------------|-----------------|
| < 20 lines of guidance | Single `SKILL.md`, no references |
| 20-100 lines with sections | `SKILL.md` + 1-2 reference files |
| Complex workflow with commands | `SKILL.md` + references + `scripts/` |
| Multiple distinct concerns | Split into separate skills |

### Step 5: Write the Skill

Follow these rules strictly:

1. **Frontmatter** — `name` (lowercase, hyphens, max 64 chars) + `description` (third-person, includes WHAT + WHEN + trigger terms)
2. **SKILL.md body** — Under 500 lines, concise, progressive disclosure
3. **References** — One level deep only; detailed docs go in `references/`
4. **Scripts** — Pre-made scripts in `scripts/`; document usage in SKILL.md
5. **Consistent terminology** — Pick one term per concept throughout
6. **No time-sensitive info** — Use "current/deprecated" sections instead of dates
7. **YAGNI** — Only include what's needed; don't over-engineer

### Step 6: Register the Skill

After creating the skill files:

1. **Update `AGENTS.md`** — Add the skill to the Available Skills table
2. **Remove the source rule** — If converting from `.mdc`, remove the original rule file (after user confirmation)
3. **Verify** — Check the skill can be discovered by its description triggers

## Quality Checklist

```
- [ ] Description includes WHAT, WHEN, and trigger terms (third-person)
- [ ] SKILL.md under 500 lines
- [ ] References one level deep
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] Scripts have usage docs and error handling
- [ ] No Windows-style paths
- [ ] Registered in AGENTS.md
```

## Examples

### Simple Rule → Skill (no scripts)

**Input** (`.mdc` rule):
```
---
alwaysApply: true
---
Always end responses with a <tldr> section containing concise bullet points.
```

**Output** (`SKILL.md`):
```markdown
---
name: tldr-summary
description: Append a <tldr> section with concise bullet points to every response. Use when formatting final output or when the user asks for summaries.
---
# TLDR Summary
## Instructions
End every response with a `<tldr></tldr>` section containing:
- Bottom-line answer in 1-2 bullets
- Key changes, decisions, or conclusions
- Points the user may want to review or question
```

### Complex Rule → Skill (with references)

**Input**: A verbose debugging workflow described across multiple messages.

**Output structure**:
```
debugging/
├── SKILL.md              # Core workflow steps
├── references/
│   ├── frontend.md       # Browser-specific debugging
│   └── backend.md        # Server-specific debugging
```

### Command → Skill (with scripts)

**Input**: "Every time I deploy, I run these 5 commands in sequence..."

**Output structure**:
```
deploy-workflow/
├── SKILL.md              # Workflow steps + script usage
└── scripts/
    └── deploy.sh         # Automated deployment script
```
