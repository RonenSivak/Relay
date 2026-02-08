# Rule-to-Skill Conversion Guide

Detailed mapping rules for converting source material into skill components.

## Source → Skill Mapping

### Frontmatter

| Source element | Maps to |
|---------------|---------|
| Rule `description` | Skill `description` — expand with WHEN triggers and third-person voice |
| Rule `globs` | Mention applicable file types in SKILL.md instructions |
| Rule `alwaysApply: true` | Skill with broad trigger terms in description |
| Command name | Skill `name` — lowercase, hyphens only |

### Content Mapping

| Source content | Skill structure |
|---------------|----------------|
| Bullet-point guidelines | **Instructions section** in SKILL.md |
| Code examples (good/bad) | **Examples section** — use ✅/❌ pattern |
| Step-by-step commands | **Workflow section** with checklist + optional `scripts/` |
| Conditional logic ("if X, do Y") | **Conditional workflow pattern** with decision tree |
| Reference links/docs | **Progressive disclosure** — `references/` directory |
| Error handling instructions | **Feedback loop pattern** with validation steps |

## Description Formula

```
[What it does] + [specific capabilities]. Use when [trigger scenario 1], 
[trigger scenario 2], or when the user says "[keyword 1]", "[keyword 2]".
```

**Rules:**
- Third person ("Generates..." not "I generate..." or "You can...")
- Max 1024 chars
- Include 3-5 trigger terms that match natural user language
- Cover both WHAT (capabilities) and WHEN (activation scenarios)

## Deciding: Rule vs Skill

Not everything should be a skill. Use this decision tree:

```
Is it < 10 lines of simple guidance?
  → YES: Keep as a rule (.mdc)
  → NO: Continue ↓

Does it need scripts, references, or examples?
  → YES: Convert to skill
  → NO: Continue ↓

Is it a multi-step workflow?
  → YES: Convert to skill
  → NO: Continue ↓

Is it triggered by specific user requests (not always-on)?
  → YES: Convert to skill
  → NO: Keep as a rule (.mdc)
```

## Freedom Levels

Match the conversion specificity to the content:

| Original content | Freedom level | Skill approach |
|-----------------|---------------|----------------|
| Strict formatting rules | **Low** — exact templates | Provide exact output templates |
| Coding conventions | **Medium** — pseudocode/guidelines | Provide patterns with examples |
| Architectural guidance | **High** — text instructions | Describe principles with rationale |
| CLI workflows | **Low** — exact scripts | Provide scripts in `scripts/` |

## Common Conversions

### "Always do X" Rule → Skill

```
# Rule: "Always use TypeScript strict mode"
# ↓ converts to:

## Instructions
Enable `strict: true` in tsconfig.json for all new projects.
When reviewing existing projects, check tsconfig and flag if strict is disabled.
```

### "When Y, do Z" Rule → Conditional Workflow

```
# Rule: "When adding API endpoint, add tests + docs"
# ↓ converts to:

## Workflow
1. Implement the endpoint
2. Write unit tests covering: happy path, error cases, edge cases
3. Update API docs with: endpoint, params, response format, examples
4. Run validation: `npm test && npm run docs:validate`
```

### Repeated Commands → Script Skill

```
# Commands: "docker build → docker tag → docker push → deploy"
# ↓ converts to:

## Quick Start
Run: `./scripts/deploy.sh <env> <tag>`

## Manual Steps (if script unavailable)
1. Build: `docker build -t app .`
2. Tag: `docker tag app registry/app:<tag>`
3. Push: `docker push registry/app:<tag>`
4. Deploy: `kubectl apply -f k8s/<env>/`
```
