# Relay - Workflow Orchestration Repository

Skills-based workflow orchestration where individual skills combine to create complete flows.

> For foundational concepts (planning, skills vs MCP, context management, model selection), see the [Coding Agents Handbook](.cursor/docs/HANDBOOK.md).

## Workflow Pattern

ALL workflows follow: **Clarify → Plan → Execute → VERIFY → Publish**

| Step | What to do |
|------|-----------|
| **Clarify** | ALWAYS invoke `/brainstorming` first — even when the user directly invokes another skill |
| **Plan** | Create structured plan with specific steps |
| **Execute** | Run the workflow using appropriate skills |
| **VERIFY** | Validate results per [VERIFICATION.md](.cursor/docs/VERIFICATION.md). If uncertain, consult user |
| **Publish** | Present findings + (if code changes) create plan.md → ask approval → implement |

## Available Skills

| Skill | When to use | Reference |
|-------|------------|-----------|
| **brainstorming** | ALWAYS first. Clarifies intent, explores approaches, validates design | [SKILL.md](.cursor/skills/brainstorming/SKILL.md) |
| **deep-search** | Forensic code investigation: definition hunting, pattern discovery, cross-repo analogy, bug hunting | [SKILL.md](.cursor/skills/deep-search/SKILL.md) |
| **debugging** | Systematic debugging: browser/server errors, performance issues, production incidents. Orchestrates Chrome DevTools, Grafana, Loki, Root Cause, Slack, Jira MCPs | [SKILL.md](.cursor/skills/debugging/SKILL.md) |
| **unit-testing** | Unit/integration tests: Jest, Vitest, RTL, Ambassador, WDS testkits. Adapts to existing patterns or introduces BDD architecture | [SKILL.md](.cursor/skills/unit-testing/SKILL.md) |
| **wds-docs** | Wix Design System component reference: props, examples, usage patterns | [SKILL.md](.cursor/skills/wds-docs/SKILL.md) |
| **chrome-devtools** | Browser automation, debugging, and performance analysis via Chrome DevTools MCP | [SKILL.md](.cursor/skills/chrome-devtools/SKILL.md) |
| **figma-to-code** | Convert Figma designs to React code using WDS. Orchestrates Figma MCP, WDS MCP, Context7, wix-internal-docs | [SKILL.md](.cursor/skills/figma-to-code/SKILL.md) |
| **adopt-subagent-flow** | Transform any skill to use adaptive parallel subagent architecture with plan.md, def-done.md, and automatic fallback | [SKILL.md](.claude/skills/adopt-subagent-flow/SKILL.md) |
| **convert-string-to-i18n** | Adaptive replacement of hard-coded UI text with Babel translation keys. Tries parallel subagents, falls back to single-agent if model can't support it. plan.md + def-done.md verification. Supports ICU, Trans, withTranslation, 5 Wix i18n frameworks | [SKILL.md](.claude/skills/convert-string-to-i18n/SKILL.md) |
| **new-skill** | Creates, updates, and converts agent skills following Anthropic's conventions and Wix coding-agents-handbook. Three modes: create (from scratch), update (audit + fix), convert (rule/command/file to skill). Optional brainstorming and subagent architecture | [SKILL.md](.claude/skills/new-skill/SKILL.md) |

## MCP Servers

Configured in `.cursor/mcp.json`. MCP provides tools; skills provide knowledge of how to use them.

| Server | Purpose |
|--------|---------|
| **octocode** | Code search, LSP navigation, git history, GitHub integration |
| **chrome-devtools** | Browser DevTools: DOM inspection, network, console, performance |
| **MCP-S** | Wix toolkit: Grafana, Loki, Jira, Slack, DevEx, DB, Figma, Root Cause |
| **wix-design-system-mcp** | WDS component documentation and examples |
| **wix-internal-docs** | Wix internal documentation access |
| **pdf-reader** | PDF document processing and extraction |
| **browsermcp** | Browser automation (Playwright-based) |

## Key Documentation

- [Coding Agents Handbook](.cursor/docs/HANDBOOK.md) — Planning, skills vs MCP, context management, model selection
- [Workflow Examples](.cursor/docs/WORKFLOWS.md) — End-to-end workflow examples
- [Verification Strategies](.cursor/docs/VERIFICATION.md) — Validation patterns
