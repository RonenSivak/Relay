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

## Orchestration Principles

You (the agent) orchestrate all workflows:
- Determine which skills to invoke and in what order
- Skills can chain: output from one skill becomes input for another
- Always verify "why we're doing what we're doing" before each major step

## Available Skills

- **brainstorming**: ALWAYS use first for Clarify step. See [docs/skills/brainstorming.md](docs/skills/brainstorming.md)
- **wds-docs**: Wix Design System component reference. See [docs/skills/wds-docs.md](docs/skills/wds-docs.md)

For skill authoring best practices, see [Anthropic's guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

## Key Documentation

- [docs/WORKFLOWS.md](docs/WORKFLOWS.md) - End-to-end workflow examples showing skills in action
- [docs/VERIFICATION.md](docs/VERIFICATION.md) - Validation strategies and patterns
- [docs/HANDBOOK.md](docs/HANDBOOK.md) - Complete coding agents handbook (Wix-specific guidance)
- [docs/skills/](docs/skills/) - Individual skill documentation
