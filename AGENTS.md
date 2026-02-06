# Relay - Workflow Orchestration Repository

Skills-based workflow orchestration where individual skills combine to create complete flows.

## Getting Started

New to AI coding agents? Read the [Coding Agents Handbook](docs/HANDBOOK.md) for foundational concepts including:
- Planning before coding (most impactful change you can make)
- Skills vs MCP vs Subagents
- Context management and token efficiency
- Model selection guidance

## Mandatory Workflow Pattern

ALL workflows follow this pattern:

**Clarify → Plan → Execute → VERIFY → Publish**

- **Clarify**: Use `/brainstorming` skill to understand user intent, explore approaches, and validate design before implementation
- **Plan**: Create structured plan with specific steps. See [Plan mode guide](https://www.aihero.dev/plan-mode-introduction) for effective planning
- **Execute**: Run the workflow using appropriate skills
- **VERIFY**: Validate results. See [docs/VERIFICATION.md](docs/VERIFICATION.md) for validation strategies. If uncertain about validation logic, consult user before proceeding
- **Publish**: Generate report.md + present to user + (if code changes needed) create plan.md → ask approval → implement

### Critical Rule: Brainstorming First

**EVEN IF the user directly invokes a skill (e.g., `/deep-search`, `/wds-docs`), you MUST run `/brainstorming` FIRST.**

When user says `/deep-search how is X defined?`:
1. **DO NOT** immediately execute deep-search
2. **DO** invoke `/brainstorming` first to clarify scope, success criteria, and approach
3. **THEN** proceed to Plan → Execute → Verify → Publish

The only exception is `/brainstorming` itself - that can be invoked directly.

This rule exists because:
- Jumping straight to execution often leads to wasted effort
- Clarification prevents searching in wrong places or for wrong things
- The workflow pattern is mandatory, not optional

## Orchestration Principles

You (the agent) orchestrate all workflows:
- Determine which skills to invoke and in what order
- Skills can chain: output from one skill becomes input for another
- Always verify "why we're doing what we're doing" before each major step

## Available Skills

- **brainstorming**: ALWAYS use first for Clarify step. See [docs/skills/brainstorming.md](docs/skills/brainstorming.md)
- **wds-docs**: Wix Design System component reference. See [docs/skills/wds-docs.md](docs/skills/wds-docs.md)
- **deep-search**: Forensic code investigation with octocode-mcp and mcps-mcp. Use for definition hunting, pattern discovery, cross-repo analogy, and bug hunting. See [skills/deep-search/SKILL.md](skills/deep-search/SKILL.md)

For skill authoring best practices, see [Anthropic's guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

## Available MCP Tools

MCP (Model Context Protocol) servers provide additional capabilities. Configured in `.cursor/mcp.json`:

- **review-gate-v2**: Code review automation and quality gates
- **wix-design-system-mcp**: WDS component documentation and examples
- **wix-internal-docs**: Wix internal documentation access
- **MCP-S**: Wix toolkit integration (lazy-dev)
- **chrome-devtools**: Browser DevTools integration for debugging
- **octocode**: Advanced code research and exploration
- **pdf-reader**: PDF document processing and extraction
- **browsermcp**: Browser automation capabilities

See [docs/HANDBOOK.md](docs/HANDBOOK.md) for MCP vs Skills comparison.

## Key Documentation

- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - End-to-end workflow examples showing skills in action
- [docs/VERIFICATION.md](docs/VERIFICATION.md) - Validation strategies and patterns
- [docs/HANDBOOK.md](docs/HANDBOOK.md) - Complete coding agents handbook (Wix-specific guidance)
- [docs/skills/](docs/skills/) - Individual skill documentation
