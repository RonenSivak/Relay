# AGENTS.md Design for Relay Repository

**Date**: 2026-02-05
**Purpose**: Define the AGENTS.md structure and supporting documentation for the Relay workflow orchestration repository

## Overview

This repository is a skills-based workflow orchestration hub where individual skills combine to create complete flows. Each flow follows a mandatory pattern: **Clarify → Plan → Execute → VERIFY → Publish**.

The AGENTS.md file and supporting documentation guide AI coding agents (Claude Code and Cursor) to work effectively within this workflow framework.

## Design Goals

1. **Enforce mandatory workflow pattern** across all tasks
2. **Progressive disclosure** - Keep always-available context lean (~400-500 words), detailed docs on-demand
3. **Cross-agent compatibility** - Works with both Claude Code and Cursor
4. **Environment-agnostic** - Don't assume specific tooling (npm, etc.)
5. **Complete duplication** - Separate flows for `.claude/` and `.cursor/` directories

## File Structure

```
Relay/
├── .claude/
│   ├── AGENTS.md                       # Claude Code's entry point (~400-500 words)
│   ├── docs/
│   │   ├── HANDBOOK.md                 # ~3000-4000 words
│   │   ├── VERIFICATION.md             # ~500-800 words
│   │   ├── WORKFLOWS.md                # ~800-1200 words
│   │   └── skills/
│   │       ├── brainstorming.md        # ~300-400 words
│   │       └── wds-docs.md             # ~300-400 words
│   └── skills/
│       ├── brainstorming/
│       │   └── SKILL.md                # Full skill instructions (already exists)
│       └── wds-docs/
│           └── SKILL.md                # Full skill instructions (already exists)
└── .cursor/
    ├── AGENTS.md                       # Cursor's entry point (identical)
    ├── docs/
    │   ├── HANDBOOK.md                 # Identical to Claude's
    │   ├── VERIFICATION.md             # Identical to Claude's
    │   ├── WORKFLOWS.md                # Identical to Claude's
    │   └── skills/
    │       ├── brainstorming.md        # Identical to Claude's
    │       └── wds-docs.md             # Identical to Claude's
    └── skills/
        ├── brainstorming/
        │   └── SKILL.md                # Identical to Claude's
        └── wds-docs/
            └── SKILL.md                # Identical to Claude's
```

## AGENTS.md Content Structure

**Location**: `.claude/AGENTS.md` and `.cursor/AGENTS.md` (identical)

**Size**: ~400-500 words (always-available context)

**Sections**:

1. **Repository Overview** - One sentence describing the purpose
2. **Getting Started** - Link to Coding Agents Handbook
3. **Mandatory Workflow Pattern** - Explicit 5-stage pattern with brief descriptions
4. **Orchestration Principles** - How agent coordinates skills
5. **Available Skills** - Catalog with one-line descriptions and links to detailed docs
6. **Key Documentation** - Links to supporting docs

**Key Content**:

```markdown
# Relay - Workflow Orchestration Repository

Skills-based workflow orchestration where individual skills combine to create complete flows.

## Getting Started

New to AI coding agents? Read the [Coding Agents Handbook](docs/HANDBOOK.md)

## Mandatory Workflow Pattern

ALL workflows follow this pattern:

**Clarify → Plan → Execute → VERIFY → Publish**

- **Clarify**: Use `/brainstorming` skill to understand user intent, explore approaches, validate design
- **Plan**: Create structured plan with specific steps
- **Execute**: Run the workflow using appropriate skills
- **VERIFY**: Validate results. See [docs/VERIFICATION.md](docs/VERIFICATION.md). If uncertain about validation logic, consult user
- **Publish**: Generate report.md + present to user + (if code changes needed) create plan.md → ask approval → implement

## Orchestration Principles

You (the agent) orchestrate all workflows:
- Determine which skills to invoke and in what order
- Skills can chain: output from one skill becomes input for another
- Always verify "why we're doing what we're doing" before each major step

## Available Skills

- **brainstorming**: ALWAYS use first for Clarify step. See [docs/skills/brainstorming.md](docs/skills/brainstorming.md)
- **wds-docs**: Wix Design System component reference. See [docs/skills/wds-docs.md](docs/skills/wds-docs.md)

## Key Documentation

- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - End-to-end workflow examples
- [docs/VERIFICATION.md](docs/VERIFICATION.md) - Validation strategies
- [docs/HANDBOOK.md](docs/HANDBOOK.md) - Complete coding agents handbook
- [docs/skills/](docs/skills/) - Individual skill documentation
```

## Supporting Documentation

### docs/VERIFICATION.md

**Purpose**: Automated validation strategies and the "uncertainty escape hatch" pattern

**Size**: ~500-800 words

**Key Sections**:
1. **Core Principle** - Attempt automated validation first, consult user if uncertain
2. **Discover Project Commands First** - How to read package.json, Cargo.toml, pom.xml, etc.
3. **Automated Validation Strategies** - Tests, linters, type checks, builds (environment-agnostic)
4. **The Uncertainty Escape Hatch** - When and how to ask user for clarification
5. **Plan-Validate-Execute Pattern** - For high-risk operations (batch changes, destructive operations)
6. **Feedback Loop Pattern** - Iterate until validation passes
7. **Verification Decision Tree** - Quick reference flowchart

**Key Design Decisions**:
- **Environment-agnostic**: Agents discover commands (npm, cargo, maven, etc.) rather than assuming
- **Specific uncertainty questions**: Examples show how to ask specific vs. vague questions
- **Verification checklist**: Template agents can copy and check off

### docs/WORKFLOWS.md

**Purpose**: Concrete end-to-end workflow examples showing skills in action

**Size**: ~800-1200 words

**Key Sections**:
1. **Introduction** - Explains that all workflows follow the 5-stage pattern
2. **Workflow 1: Design and Implement New Component** - Uses brainstorming → wds-docs
3. **Workflow 2: Refactor Existing Code** - Uses brainstorming
4. **Workflow 3: Document Technical Decision** - Uses brainstorming
5. **Shared Context Pattern** - How workflows maintain continuity (placeholder for future)

**Key Design Decisions**:
- Each workflow explicitly shows all 5 stages
- Demonstrates different verification strategies per workflow type
- Shows how skills chain together
- Includes "if uncertain, ask user" examples in VERIFY stage

### docs/HANDBOOK.md

**Purpose**: Complete Coding Agents Handbook (Wix-specific guidance)

**Size**: ~3000-4000 words

**Content**: Direct copy of the provided Coding Agents Handbook with:
- Table of contents added
- All external links preserved
- Wix-specific sections kept (Cursor quotas, Slack channels)
- Note at bottom linking to AGENTS.md, VERIFICATION.md, WORKFLOWS.md

### docs/skills/{skill-name}.md

**Purpose**: Quick reference for each skill without reading full SKILL.md

**Size**: ~300-400 words per skill

**Template Structure**:
1. **Purpose** - What this skill does
2. **When to Use** - Trigger scenarios
3. **Inputs** - What the skill expects
4. **Outputs** - What the skill produces
5. **Workflow Integration** - How it chains with other skills
6. **Example Usage** - Concrete example
7. **Complete Documentation** - Link to full SKILL.md

## Path References Strategy

Since AGENTS.md lives inside `.claude/` and `.cursor/`, all paths are relative:

```markdown
[docs/WORKFLOWS.md](docs/WORKFLOWS.md)
[docs/skills/brainstorming.md](docs/skills/brainstorming.md)
```

## Files to Create

**Total: 16 files (8 files × 2 directories)**

**Priority 1 (Core workflow)**:
1. `.claude/AGENTS.md` + `.cursor/AGENTS.md`
2. `.claude/docs/VERIFICATION.md` + `.cursor/docs/VERIFICATION.md`
3. `.claude/docs/WORKFLOWS.md` + `.cursor/docs/WORKFLOWS.md`

**Priority 2 (Reference)**:
4. `.claude/docs/HANDBOOK.md` + `.cursor/docs/HANDBOOK.md`
5. `.claude/docs/skills/brainstorming.md` + `.cursor/docs/skills/brainstorming.md`
6. `.claude/docs/skills/wds-docs.md` + `.cursor/docs/skills/wds-docs.md`

**Priority 3 (Skill mirroring)**:
7. Copy `.claude/skills/brainstorming/SKILL.md` → `.cursor/skills/brainstorming/SKILL.md`
8. Copy `.claude/skills/wds-docs/SKILL.md` → `.cursor/skills/wds-docs/SKILL.md`

## Best Practices Applied

Based on:
- [Coding Agents Handbook](https://github.com/wix-incubator/coding-agents-handbook)
- [Anthropic Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [AGENTS.md Standard](https://agents.md/)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)

**Key principles**:
1. **Keep AGENTS.md small and focused** - Every token loads on every request (~400-500 words)
2. **Progressive disclosure** - Move detailed content to separate files agents load on-demand
3. **Passive context is reliable** - Workflow pattern always available vs. on-demand retrieval
4. **Concise is key** - Assume Claude is smart, only add context it doesn't have
5. **Environment-agnostic** - Discover commands rather than assume tooling
6. **Complete duplication** - Separate flows for Claude and Cursor

## Why Duplicate Everything

**Purpose**: Create separate, isolated flows for each agent type

- **Claude Code** reads `.claude/AGENTS.md` and follows `.claude/` structure
- **Cursor** reads `.cursor/AGENTS.md` and follows `.cursor/` structure
- Both flows are identical but completely independent
- Enables future customization (Claude-specific vs Cursor-specific workflows)

## Maintenance Strategy

When updating any doc or skill:
1. Update in `.claude/`
2. Mirror to `.cursor/`
3. Keep both directories in sync
4. Consider automation (symlinks won't work, so manual copy or script)

## Key Design Decisions Summary

| Decision | Rationale |
|----------|-----------|
| AGENTS.md in both `.claude/` and `.cursor/` | Each agent reads its own entry point |
| ~400-500 word AGENTS.md | Keeps always-available context lean |
| Progressive disclosure via docs/ | Detailed content loaded only when needed |
| Mandatory 5-stage workflow | Enforces quality gates (especially VERIFY) |
| Environment-agnostic verification | Works across npm, cargo, maven, make, etc. |
| Uncertainty escape hatch | Agent asks user when validation logic unclear |
| Complete duplication | Independent flows, enables future customization |
| Relative paths in AGENTS.md | Works regardless of directory structure |
| Skills catalog in AGENTS.md | Quick discovery with links to details |

## Implementation Notes

1. **Content Sources**:
   - HANDBOOK.md: Copy from provided Coding Agents Handbook
   - VERIFICATION.md: Create from Design Section 5 (environment-agnostic)
   - WORKFLOWS.md: Create from Design Section 4 (3 workflows)
   - Skill docs: Create from Design Section 3 (template pattern)

2. **File Operations**:
   - Create new: AGENTS.md, all docs/*.md
   - Copy existing: skills/*/SKILL.md from .claude/ to .cursor/

3. **Validation**:
   - Check all relative links work
   - Verify word counts
   - Ensure identical content in .claude/ and .cursor/

## Next Steps

After design approval:
1. Generate all 16 files
2. Commit to repository
3. Test with actual workflows
4. Iterate based on usage
