---
name: deep-search
description: Forensic code investigation that exhaustively hunts for verifiable evidence using octocode-mcp and mcps-mcp. Never stops at "probably" or "likely" - continues until hard evidence is found or deterministically concludes none exists. Use for: (1) Definition hunting - "how is X defined?", (2) Pattern discovery - "how do I add a new component type?", (3) Cross-repo analogy - "implement X like Y in another codebase", (4) Bug hunting - root cause analysis with evidence chain.
---

# Deep Search

## Overview

Deep Search is a forensic investigation skill that exhaustively searches codebases to find verifiable evidence. Unlike standard search, it never stops at guesses like "probably in the auth module" or "likely handled by middleware." Instead, it continues searching until it finds hard evidence (file paths, line numbers, commit SHAs) or deterministically concludes that the evidence doesn't exist.

This skill leverages two MCP servers:
- **octocode-mcp**: Code search, LSP navigation, git history, GitHub integration
- **mcps-mcp**: Jira tickets and Slack discussions for organizational context

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before executing deep-search, ALWAYS invoke `/brainstorming` first to:

1. **Clarify the investigation goal** - What exactly are we looking for?
2. **Identify search scope** - Which repos, timeframes, or areas to focus on?
3. **Define success criteria** - What evidence would answer the question?
4. **Choose investigation type** - Definition hunting, pattern discovery, cross-repo, or bug hunting?

Example flow:
```
User: "How is authentication handled?"

Step 1: /brainstorming
- Clarify: Are we looking for implementation details, design decisions, or both?
- Scope: Just this repo or also shared libraries?
- Success: Need code locations + rationale for design choices

Step 2: /deep-search
- Execute investigation with clear parameters from brainstorming
```

This ensures focused investigation rather than unfocused searching.

## When to Use This Skill

Invoke `/deep-search` when you need forensic-level investigation:

### Scenario 1: Definition Hunting
**User asks**: "How is AuthToken defined?" or "Where does validateUser come from?"

**What Deep Search does**:
- Searches for all references to the symbol
- Uses LSP to jump to actual definition (not just string matches)
- Traces through imports if defined externally
- Finds the commit/PR that introduced it
- Searches Jira/Slack for design decisions

**Output**: File path + line number, commit SHA, optional context from tickets/discussions

### Scenario 2: Pattern Discovery
**User asks**: "How do I add a new component type?" or "What's the pattern for creating endpoints?"

**What Deep Search does**:
- Finds 2-3 existing examples of similar implementations
- Extracts common conventions (naming, structure, dependencies)
- Traces shared utilities or base classes
- Locates documentation (ADRs, READMEs)
- Understands evolution of the pattern

**Output**: Multiple concrete examples with file paths, shared utilities, documentation links

### Scenario 3: Cross-Repo Analogy
**User asks**: "Implement X like we implemented Y in the other codebase"

**What Deep Search does**:
- Locates analogous implementation in other repo using GitHub search
- Deep dives into the implementation (entry points, core logic, dependencies, tests)
- Extracts portable patterns that can transfer
- Identifies adapter points for current repo
- Checks if this was already attempted and abandoned

**Output**: Full implementation with file paths, architectural decisions, differences between repos

### Scenario 4: Bug Hunting
**User asks**: "Why is this failing?" or "What's causing this behavior?"

**What Deep Search does**:
- Identifies symptom location (stack traces, failing tests)
- Checks recent changes (git log, recent PRs)
- Traces execution path backwards using call hierarchy
- Searches for similar issues in Jira/Slack
- Checks test coverage and configuration

**Output**: Root cause location, commit that introduced bug (if found), related issues

## Core Workflow

Deep Search follows this investigative process:

### Step 1: Initial Code Search (Octocode)
Use octocode-mcp tools to locate relevant code:
- `localSearchCode` - Full-text search in current workspace
- `localFindFiles` - Find files by name/metadata
- `lspGotoDefinition` - Jump to symbol definitions
- `lspFindReferences` - Find all usages
- `lspCallHierarchy` - Trace call graphs

### Step 2: Context Mining (MCPS)
Use mcps-mcp tools to understand "why":
- `jira.search` - Find related tickets by keyword
- `jira.getTicket` - Get ticket details with comments
- `slack.search` - Search engineering discussions
- `slack.getThread` - Get full conversation context

### Step 3: Cross-Reference
Link code to organizational context:
- Extract PR numbers from Jira tickets
- Find commit SHAs from Slack discussions
- Trace tickets to code changes
- Build complete evidence chain

### Step 4: Evidence Assembly
Organize findings by hierarchy (see references/evidence-hierarchy.md):
- **Primary Evidence**: Code with file:line, diffs with commit SHA
- **Secondary Evidence**: Tickets, PRs, discussions with links and quotes
- **Tertiary Evidence**: Comments, READMEs, type definitions

### Step 5: Verification
Before presenting findings, verify:
- [ ] Can point to specific locations (file:line)
- [ ] Can provide clickable links
- [ ] Can quote actual code, not summaries
- [ ] Evidence is current (not outdated)
- [ ] Found the source of truth (not a wrapper)

## Search Strategies

Deep Search uses different algorithms based on the investigation type:

**DFS (Depth-First Search)**: Follow one path completely before backtracking
- Best for: Tracing a single definition through layers of imports
- Example: AuthToken reference → import → @company/auth → source

**BFS (Breadth-First Search)**: Explore all paths at current level before going deeper
- Best for: Finding all usages of a function across the codebase
- Example: Find all places where user.email is accessed

**A* (Heuristic Search)**: Prioritize promising paths
- Best for: Large codebases, time-constrained investigations
- Heuristics: Recent commits > high-traffic files > documented files

See `references/search-strategies.md` for detailed patterns.

## Evidence Standards

Never present findings without verifiable evidence:

❌ **Forbidden**: "It's probably in the auth module"
✅ **Required**: "src/auth/token.ts:42-67"

❌ **Forbidden**: "This looks like it uses JWT"
✅ **Required**: Code snippet with file path showing JWT usage

❌ **Forbidden**: "Based on the pattern, it likely..."
✅ **Required**: Actual pattern with 2-3 examples (file:line)

See `references/evidence-hierarchy.md` for complete standards.

## MCP Tool Reference

This skill uses octocode-mcp and mcps-mcp extensively. Key tools:

**Octocode - Local Search**:
- `localSearchCode(pattern, path, filesOnly)` - Full-text search
- `localGetFileContent(path, matchString)` - Read files with optional filtering
- `localFindFiles(namePattern)` - Find files by name

**Octocode - LSP Navigation**:
- `lspGotoDefinition(uri, symbolName, lineHint)` - Jump to definition
- `lspFindReferences(uri, symbolName, lineHint)` - Find all usages
- `lspCallHierarchy(uri, symbolName, lineHint, direction)` - Trace calls

**Octocode - GitHub**:
- `githubSearchCode(keywordsToSearch, owner, repo)` - Search other repos
- `githubGetFileContent(owner, repo, path)` - Read remote files
- `githubSearchPullRequests(query, owner, repo)` - Find PRs

**MCPS - Jira**:
- `jira.search(query, project, status)` - Search tickets
- `jira.getTicket(ticketKey)` - Get full ticket details

**MCPS - Slack**:
- `slack.search(query, channels, dateRange)` - Search messages
- `slack.getThread(messageLink)` - Get thread context

See `references/mcp-tools-reference.md` for detailed usage patterns and examples.

## Output Format

Present findings using the standard template:

```markdown
# Investigation: [User's Question]

## Primary Evidence
[Code locations with file:line and snippets]

## Secondary Evidence
[Commits, PRs, tickets with links and quotes]

## Tertiary Evidence
[Comments, docs, supporting material]

## Verification Performed
[List of searches and checks performed]

## Conclusion
[Direct answer with citations]
```

See `references/output-format.md` for detailed examples by investigation type.

## Search Termination

**Stop when you have**: Hard evidence with file paths, line numbers, and citations

**Stop when you've proven**: Evidence doesn't exist after exhaustive search of all relevant locations

**Never stop at**: "probably", "likely", "looks like", "I think", "based on the pattern"

## Progressive Disclosure

This skill uses progressive disclosure to manage context:

- **Always loaded**: This SKILL.md file (core workflow)
- **Load on demand**: Reference files when needed for specific investigation types
  - `references/search-strategies.md` - When choosing search algorithm
  - `references/evidence-hierarchy.md` - When assembling findings
  - `references/mcp-tools-reference.md` - When using specific MCP tools
  - `references/output-format.md` - Before presenting final results

## Integration with Workflows

Deep Search follows the mandatory workflow pattern. **Never skip the Clarify step.**

1. **Clarify (MANDATORY)**: Invoke `/brainstorming` FIRST
   - What are we investigating?
   - What would "success" look like?
   - What scope and constraints apply?

2. **Plan**: Based on brainstorming output, choose:
   - Search strategy (DFS/BFS/A*)
   - Investigation type (definition/pattern/cross-repo/bug)
   - Which MCP tools to use

3. **Execute**: Run `/deep-search` with MCP tools
   - Follow the Core Workflow steps
   - Use progressive disclosure for reference docs

4. **VERIFY**: Check evidence against standards
   - All findings have file:line citations
   - Primary evidence is verifiable
   - No "probably" or "likely" statements

5. **Publish**: Format findings using output-format.md template

## Examples

**Example 1 - Definition Hunting**:
```
User: "How is SessionStore defined?"

Deep Search Process:
1. localSearchCode("SessionStore") → Found in src/session/store.ts
2. lspGotoDefinition → Line 42, uses Redis
3. Git history → Added in commit abc123, PR #567
4. jira.search("session storage Redis") → JIRA-1234
5. jira.getTicket("JIRA-1234") → Decision: Redis for persistence

Output:
- Primary: src/session/store.ts:42-67 (code snippet)
- Secondary: Commit abc123, PR #567, JIRA-1234 (with quotes)
- Conclusion: SessionStore uses Redis, chosen for horizontal scaling
```

**Example 2 - Pattern Discovery**:
```
User: "How do I add a new API endpoint?"

Deep Search Process:
1. localSearchCode("app.get") → Found 15 endpoint examples
2. Compare 3 recent examples → Extract pattern
3. lspFindReferences("validateRequest") → Shared middleware
4. localGetFileContent("docs/api/README.md") → Documentation
5. githubSearchPullRequests("add endpoint") → Recent PR #891

Output:
- Primary: 3 examples (file:line for each)
- Secondary: Shared middleware location, PR #891
- Tertiary: README documentation
- Conclusion: Pattern identified with step-by-step guide
```

## Troubleshooting

**If search returns too many results**: Use `filesOnly=true` first to narrow down, then read specific files

**If LSP tools fail**: Fall back to localSearchCode with regex patterns

**If external package**: Use `packageSearch` to find package, then `githubSearchCode` to find implementation

**If no evidence found**: Explicitly state what was searched and conclude "not implemented" rather than guessing
