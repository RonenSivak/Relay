# Search Strategies

Exhaustive forensic search patterns for finding hard evidence. Never stop at "likely" or "probably" - continue until verifiable proof is found or deterministically conclude none exists.

## Core Search Algorithms

### DFS (Depth-First Search)
Follow one path completely before backtracking. Use when:
- Tracing a single definition through layers of imports
- Following a call chain to its source
- Investigating a specific bug's root cause

**Example**: "How is AuthToken defined?"
```
AuthToken reference → import statement → @company/auth → package source → original implementation
```

### BFS (Breadth-First Search)
Explore all paths at the current level before going deeper. Use when:
- Finding all usages of a function
- Discovering all places a pattern is used
- Mapping all implementations of an interface

**Example**: "Show me all places where user.email is accessed"
```
Level 1: Direct references in current repo
Level 2: Indirect references through getters/helpers
Level 3: References in related services
```

### A* (Heuristic Search)
Prioritize promising paths using heuristics. Use when:
- Searching across large codebases
- Time-constrained investigations
- Finding the "best" example among many

**Heuristics** (in order):
1. Recent activity (commits in last 30 days)
2. High-traffic files (many imports/references)
3. Documented files (has comments/docs)
4. Main/master branch over feature branches

## Search Patterns by Use Case

### Pattern 1: Definition Hunting

**Goal**: Find where and how something is defined

**Search sequence**:
1. **Code search** - Find all references to the symbol
   - Use octocode-mcp: `localSearchCode` or `githubSearchCode`
   - Look for: class definitions, function declarations, type definitions

2. **LSP navigation** - Jump to actual definition
   - Use octocode-mcp: `lspGotoDefinition`
   - Follow imports if defined externally

3. **Git history** - Understand why it was created
   - Search commits mentioning the symbol
   - Find the PR that introduced it

4. **Context mining** - Find decision rationale
   - Use mcps-mcp: Search Jira for related tickets
   - Use mcps-mcp: Search Slack for design discussions

5. **Dependency trace** - If imported from external package
   - Find package version in package.json
   - Search package's GitHub repo for source

**Evidence required**:
- Primary: File path + line number of definition
- Secondary: Commit SHA introducing it
- Tertiary: Ticket/discussion explaining why

### Pattern 2: Pattern Discovery

**Goal**: Understand how to implement something by finding existing patterns

**Search sequence**:
1. **Find examples** - Locate similar implementations
   - Search for files with similar names
   - Search for similar code patterns
   - Look in tests for usage examples

2. **Extract conventions** - Identify common patterns
   - Compare 3-5 examples
   - Note: naming conventions, file structure, dependencies

3. **Trace implementation** - Understand the pattern deeply
   - For each example: use LSP to trace through call hierarchy
   - Find shared utilities or base classes

4. **Find documentation** - Locate guides or ADRs
   - Search for ADRs (docs/decisions/, docs/architecture/)
   - Check README files in relevant directories
   - Search Confluence/wiki links in code comments

5. **Historical context** - Understand evolution
   - When was this pattern introduced?
   - Has it changed? Why?
   - Are there deprecated old patterns?

**Evidence required**:
- Primary: 2-3 concrete examples (file:line)
- Secondary: Shared utility/base class if exists
- Tertiary: Documentation or ADR explaining pattern

### Pattern 3: Cross-Repo Analogy

**Goal**: Implement X based on how Y was done in another codebase

**Search sequence**:
1. **Locate analogous implementation** - Find Y in the other repo
   - Use githubSearchCode across multiple repos
   - Search for similar class/function names

2. **Deep dive into Y** - Understand it completely
   - Use lspGotoDefinition and lspCallHierarchy
   - Map out: entry points, core logic, dependencies, tests

3. **Extract portable patterns** - What can transfer?
   - Architecture decisions (not repo-specific)
   - Algorithm implementations
   - Test strategies
   - NOT: Specific imports, file paths, or repo structure

4. **Find adapter points** - How to integrate in current repo
   - What are the equivalent concepts here?
   - What dependencies need mapping?
   - What needs to be created vs adapted?

5. **Validate approach** - Check for past attempts
   - Search current repo for similar implementations
   - Check if this was already tried and abandoned
   - Look for tickets/discussions about it

**Evidence required**:
- Primary: Full implementation in other repo (file paths)
- Secondary: Key architectural decisions that transfer
- Tertiary: Differences between repos that affect adaptation

### Pattern 4: Bug Hunting

**Goal**: Find the root cause of a bug or unexpected behavior

**Search sequence**:
1. **Identify symptom location** - Where does it manifest?
   - Stack traces (if available)
   - User-reported behavior
   - Failing tests

2. **Recent changes** - What changed recently?
   - Git log for affected files (last 30 days)
   - Recent PRs touching this area
   - Recent deployments or releases

3. **Trace backwards** - Follow the execution path
   - Use lspCallHierarchy (incoming) to find callers
   - Follow the data flow backwards
   - Check middleware, hooks, interceptors

4. **Similar issues** - Has this happened before?
   - Search Jira for similar bug reports
   - Search Slack for user reports
   - Check closed tickets for patterns

5. **Test coverage** - Are we missing tests?
   - Find tests for the affected code
   - Look for gaps in coverage
   - Check if bug reproduces in tests

6. **Configuration/environment** - Is it environment-specific?
   - Check config files
   - Look for environment variables
   - Compare staging vs production settings

**Evidence required**:
- Primary: Root cause location (file:line) and explanation
- Secondary: Commit/PR that introduced the bug (if found)
- Tertiary: Related issues or discussions

## Search Termination Conditions

### When to stop searching

**Success**: Hard evidence found
- Can point to specific code locations
- Can cite commits, tickets, or messages
- Can demonstrate with executable examples

**Deterministic failure**: Evidence provably doesn't exist
- Exhaustively searched all relevant locations
- Checked historical records (git, Jira, Slack)
- Confirmed with architectural patterns that it shouldn't exist
- Example: "Feature X was never implemented. No code, tickets, or discussions found."

### What NOT to stop at

❌ "It's probably in..." - Keep searching
❌ "This looks like..." - Verify with actual code
❌ "Based on the pattern..." - Find the actual pattern
❌ "It's likely handled by..." - Trace to the handler
❌ "I think it's..." - Don't think, find proof

## Multi-Source Search Strategy

Always search in parallel across:

1. **Code** (octocode-mcp)
   - Local codebase
   - Related repositories
   - Dependencies

2. **History** (octocode-mcp)
   - Git commits
   - Pull requests
   - Blame annotations

3. **Tickets** (mcps-mcp)
   - Open and closed Jira tickets
   - Related epics
   - Linked tickets

4. **Discussions** (mcps-mcp)
   - Slack channels (engineering, team-specific)
   - Slack threads on the topic
   - Design docs shared in Slack

5. **Documentation**
   - READMEs
   - ADRs (Architecture Decision Records)
   - Wiki pages
   - Code comments

## Search Optimization

### Parallelization
When searching multiple independent sources, search in parallel:
- Code search + Jira search + Slack search simultaneously
- Multiple repo searches at once
- Don't wait for one to finish before starting another

### Caching
Remember what you've already searched to avoid duplication:
- Track searched file paths
- Note checked commit ranges
- Record queried Jira projects
- Log Slack channels searched

### Progressive Deepening
Start shallow, go deeper as needed:
1. Quick search: obvious locations, recent changes
2. Medium search: related files, similar patterns
3. Deep search: full repo, historical records, external dependencies
4. Exhaustive: cross-repo, archived channels, deleted code
