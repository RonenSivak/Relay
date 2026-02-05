# Coding Agents Handbook

A practical guide to using AI coding agents at Wix. Covers workflows and tools that make agents more effective and efficient. Since best practices evolve rapidly, we'll do our best to keep this document up to date with proven approaches while researching and incorporating new concepts as they emerge.

## Table of Contents

- [Get the Basics](#get-the-basics)
- [Planning](#planning)
- [Debugging](#debugging)
- [AGENTS.md](#agentsmd)
- [Skills](#skills)
- [Subagents](#subagents)
- [MCP](#mcp)
- [Legacy Concepts](#legacy-concepts)
- [Managing Context & Token Efficiency](#managing-context--token-efficiency)
- [Model Selection and Best Practices](#model-selection-and-best-practices)
- [Developing Your Workflow](#developing-your-workflow)
- [Usage at Wix](#usage-at-wix)

---

## Get the Basics

**[Cursor AI Foundations Course](https://cursor.com/learn)** - Understand the fundamentals of how AI models work and how to interact with them effectively, we recommend taking this short course. *[~30 minutes]*

**[Cursor Features Overview](https://www.youtube.com/watch?v=L_p5GxGSB_I)** - a quick overview that clarifies the differences between Rules, Commands, Skills, and other features *[~5 minutes]*

## Planning

[The most impactful change you can make is planning before coding.](https://cursor.com/blog/agent-best-practices#start-with-plans)

Planning forces clear thinking about what you're building and gives the agent concrete goals to work toward. Plan mode is a collaborative mode for designing implementation approaches before coding, helping align human intent with agent execution.

**Cursor:** [Plan mode](https://cursor.com/docs/agent/modes#plan) - Switch with `Shift+Tab` from the chat input to rotate to Plan Mode. Cursor also suggests it automatically when you type keywords that indicate complex tasks.

**Claude Code:** [Plan mode](https://code.claude.com/docs/en/common-workflows#use-plan-mode-for-safe-code-analysis) - Toggle with `Shift+Tab` during a session, or start with `claude --permission-mode plan`

A short guide that explains how plan mode works and how to use it effectively: [Plan mode guide](https://www.aihero.dev/plan-mode-introduction)

## Debugging

[Debug mode](https://cursor.com/docs/agent/modes#debug) is an interactive agent loop built around runtime data and human verification. It forms multiple hypotheses, instruments the code with logs, and iterates with you until the bug is genuinely fixed. Currently only a Cursor feature, but can be used in Claude Code [as a skill](https://github.com/vltansky/debug-skill).

## AGENTS.md

[`AGENTS.md`](../AGENTS.md) file is a markdown file you check into your repository that customizes how AI coding agents behave. It sits at the top of the conversation history, right below the system prompt, and can contain project-specific guidance like coding conventions, architecture decisions, and other project-specific preferences.

**Keep it small and focused** - every token loads on every request.

**Use Progressive Disclosure:** Move domain-specific rules to separate files (e.g., `docs/TESTING.md`) and reference them. Agents navigate documentation hierarchies efficiently, pulling in knowledge only when needed.

**Passive context is more reliable than on-demand retrieval** - AGENTS.md content is always available to the agent, eliminating the decision point of whether to look something up. For broad knowledge (framework patterns, conventions), this [outperforms skills which agents may not reliably invoke](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals).

**Balance availability vs. relevance:** Always-available context is more reliable but risks bloating the context when irrelevant. On-demand retrieval keeps context lean but may fail when agents don't retrieve it. Find the right balance for your project, and remember that you can always bring in context on demand via the prompt (e.g., "look at @docs/TESTING.md").

For detailed guidance on writing effective `AGENTS.md` files, read this excellent guide: [A Complete Guide To AGENTS.md](https://www.aihero.dev/a-complete-guide-to-agents-md)

## Skills

[Agent skills](https://agentskills.io) is an open format for giving agents new capabilities and expertise. While can be picked up by the agent autonomously, skills work best for action-specific workflows that users explicitly trigger. Mentioning a skill in AGENTS.md increases the likelihood the agent will invoke it.

[Skill authoring best practices from anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) - Covers how to write effective skills including structuring content for progressive disclosure, writing descriptions that enable discovery and more.

## Subagents

> **Note:** Cursor Subagents in Wix are currently supported only via `composer-1` model.

[Subagents](https://cursor.com/docs/agent/subagents) are short-lived, specialized agents spawned by the main agent to handle a single, well-scoped task. They run independently, return structured results, and help reduce context bloat while enabling parallel execution.

## MCP

[MCP](https://modelcontextprotocol.io/docs/getting-started/intro) is an open standard for connecting AI agents to external tools and data sources. It's particularly useful for OAuth-protected services like Slack, Google Drive, or Figma. It lets agents access your data without manual copy-pasting.

MCP provides tools and data access while skills provide knowledge of how to use them effectively. For example, MCP connects to Slack, while a skill knows which channels to post to and your team's message formatting conventions. [MCP vs Skills comparison](https://code.claude.com/docs/en/features-overview#mcp-vs-skill)

## Legacy Concepts

### Rules

[Cursor rules](https://cursor.com/docs/context/rules) (`.cursor/rules/`) should generally be avoided. Prefer AGENTS.md or skills instead, as they follow an open standard that is compatible with multiple coding agents. Additionally, consolidating persistent context in AGENTS.md makes it easier to visualize and manage, preventing context bloat from scattered rule files.

### Commands

[Cursor commands](https://cursor.com/docs/context/commands) (`.cursor/commands/`) are reusable prompt templates that can be invoked with a slash command. However, prefer using skills over commands since skills can be invoked the same way (via `/` or by asking the agent to use them) while following an open standard that works across multiple coding agents.

## Managing Context & Token Efficiency

Let the agent find context, if you know the exact file, tag it (using `@` symbols). If not, the agent will find it. Including irrelevant files can confuse the agent about what's important.

Start a new conversation when switching tasks, the agent seems confused, or you've finished a logical unit of work.

In Cursor you can reference past work by writing `@Past Chats` which allows the agent to selectively read from the chat history to pull in only the context it needs.

Efficient prompts save costs and improve precision.
*   **Inefficient**: Reading entire modules, pulling irrelevant directories, using expensive models for simple tasks.
*   **Efficient**: Surgical context (only relevant files), clear instructions, no repository scanning, using cheaper models for simpler tasks.

## Model Selection and Best Practices

Understanding which model to use and how to maximize token efficiency is important for getting the best results while managing costs.

* **Standard**: Optimized for token efficiency and routine development tasks.
* **Thinking**: Focuses on structured reasoning—analyze, plan, and reflect before acting. Some models offer reasoning levels (low/medium/high, e.g., `gpt-5.2-codex-high`). Higher levels improve accuracy but increase cost and latency.
* **Cursor Auto**: Chooses the model with the highest reliability based on demand.

**Use Standard/Low Reasoning for:** requirements are clear, writing unit tests, documentation.

**Use Thinking/High Reasoning for:** architecture, complex problem-solving, planning.

## Developing Your Workflow

**Write specific prompts.** The agent's success rate improves significantly with specific instructions. Compare "add tests for auth.ts" with "Write a test case for auth.ts covering the logout edge case, using the patterns in __tests__/ and avoiding mocks."

**Iterate on your setup.** Start simple. Add rules only when you notice the agent making the same mistake repeatedly. Add commands only after you've figured out a workflow you want to repeat. Don't over-optimize before you understand your patterns.

**Review carefully.** AI-generated code can look right while being subtly wrong. Read the diffs and carefully review. The faster the agent works, the more important your review process becomes.

**Provide verifiable goals.** Agents can't fix what they don't know about. Use typed languages, configure linters, and write tests. Give the agent clear signals for whether changes are correct.

**Treat agents as capable collaborators.** Ask for plans. Request explanations. Push back on approaches you don't like.

## Usage at Wix

### Cursor

At Wix, we have specific quotas and configurations for Cursor usage.

#### Quotas and Costs
* **Premium Requests**: You are allocated **500 premium requests per month**.
* **On-demand Usage**: You are allocated **300$ per month**.

Model prices change over time, some models are more expensive than others, usually marked with 2X in the model selection context menu.

For example, gpt "fast" models cost 2 requests while the regular models cost 1 request.
claude sonnet thinking cost 2 requests while the standard sonnet cost 1 request.

*Note: Cursor may change these costs or add promotions for specific models from time to time.*

#### Monitoring Your Usage
You can track your usage at the [Cursor Dashboard](https://cursor.com/dashboard?tab=usage).
*   The dashboard shows how many included requests you've used.
*   It indicates when your plan resets (usually the 1st of each month).
*   You can view usage history to see which models were used and token consumption.

#### Overage
If you reach your included premium requests, you will be moved to **on-demand usage**, which incurs costs according to [Cursor's API pricing](https://cursor.com/docs/models#model-pricing). Currently has a limit of 300$ per month.

#### Channels
- [#cursor-support](https://wix.slack.com/archives/C08G9DMFGPM) - For support and questions.
- [#cursor-updates](https://wix.slack.com/archives/C08SYA4M5Q9) - For updates and announcements.

### Claude Code

At the moment, Claude Code is being tested by individual accounts, we'll update this section when it's more widely available.

---

## Related Files

- [../AGENTS.md](../AGENTS.md) - This repository's workflow patterns
- [VERIFICATION.md](VERIFICATION.md) - Verification strategies
- [WORKFLOWS.md](WORKFLOWS.md) - Workflow examples
