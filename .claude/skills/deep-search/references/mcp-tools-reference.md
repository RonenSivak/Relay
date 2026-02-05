# MCP Tools Reference

How to use octocode-mcp and mcps-mcp for forensic search.

## Octocode MCP

Provides semantic code navigation, search, and git history tools.

### Tool Categories

**Local Tools** - Search current workspace:
- `localSearchCode` - Full-text search with ripgrep
- `localGetFileContent` - Read file contents
- `localFindFiles` - Find files by name/metadata
- `localViewStructure` - View directory tree

**LSP Tools** - Semantic navigation:
- `lspGotoDefinition` - Jump to symbol definition
- `lspFindReferences` - Find all usages
- `lspCallHierarchy` - Trace call graph (incoming/outgoing)

**GitHub Tools** - Search external repos:
- `githubSearchCode` - Search code in GitHub repos
- `githubGetFileContent` - Read files from GitHub
- `githubViewRepoStructure` - View repo directory tree
- `githubSearchRepositories` - Find repositories
- `githubSearchPullRequests` - Search PRs

**Package Tools** - External dependencies:
- `packageSearch` - Search npm/PyPI packages

### Essential Search Patterns

#### Pattern: Find Definition

**Use case**: "How is AuthToken defined?"

**Sequence**:
1. Search for references:
   ```
   localSearchCode(pattern="AuthToken", path="/workspace")
   ```

2. Jump to definition:
   ```
   lspGotoDefinition(
     uri="/workspace/src/auth/index.ts",
     symbolName="AuthToken",
     lineHint=15  // from search results
   )
   ```

3. If imported from external package:
   ```
   packageSearch(name="@company/auth", ecosystem="npm")
   githubSearchCode(
     keywordsToSearch=["AuthToken"],
     owner="company",
     repo="auth-lib"
   )
   ```

#### Pattern: Find All Usages

**Use case**: "Show me all places where user.email is accessed"

**Sequence**:
1. Find the property definition:
   ```
   localSearchCode(pattern="user.email", path="/workspace")
   ```

2. Get all references:
   ```
   lspFindReferences(
     uri="/workspace/src/models/user.ts",
     symbolName="email",
     lineHint=42
   )
   ```

3. For each reference, get context:
   ```
   localGetFileContent(
     path="/workspace/src/api/profile.ts",
     startLine=100,
     endLine=120
   )
   ```

#### Pattern: Trace Call Flow

**Use case**: "How does login() get called?"

**Sequence**:
1. Find login function:
   ```
   localSearchCode(pattern="function login", path="/workspace")
   ```

2. Find incoming calls:
   ```
   lspCallHierarchy(
     uri="/workspace/src/auth/login.ts",
     symbolName="login",
     lineHint=50,
     direction="incoming"
   )
   ```

3. For each caller, trace deeper:
   ```
   lspCallHierarchy(
     uri="/workspace/src/api/auth-routes.ts",
     symbolName="handleLogin",
     lineHint=25,
     direction="incoming"
   )
   ```

#### Pattern: Cross-Repo Search

**Use case**: "Find how this was implemented in another repo"

**Sequence**:
1. Search across repos:
   ```
   githubSearchCode(
     keywordsToSearch=["PaymentProcessor", "processPayment"],
     owner="company"
     // searches all company repos
   )
   ```

2. View repo structure:
   ```
   githubViewRepoStructure(
     owner="company",
     repo="payments-service",
     branch="main",
     path="src/processors"
   )
   ```

3. Read implementation:
   ```
   githubGetFileContent(
     owner="company",
     repo="payments-service",
     path="src/processors/stripe.ts"
   )
   ```

### Tool Selection Guide

| Goal | Primary Tool | Secondary Tools |
|------|-------------|-----------------|
| Find text in code | `localSearchCode` | `githubSearchCode` |
| Jump to definition | `lspGotoDefinition` | `packageSearch` (if external) |
| Find all usages | `lspFindReferences` | `localSearchCode` (as backup) |
| Trace callers | `lspCallHierarchy(incoming)` | Manual grep through results |
| Trace callees | `lspCallHierarchy(outgoing)` | Read function body |
| Search other repos | `githubSearchCode` | `githubSearchRepositories` first |
| Read file | `localGetFileContent` | `githubGetFileContent` (if remote) |
| Find files by name | `localFindFiles` | `localViewStructure` |

### Search Optimization Tips

**Use `filesOnly` for discovery**:
```
localSearchCode(
  pattern="AuthToken",
  path="/workspace",
  filesOnly=true  // faster, just lists files
)
```

**Use `matchString` for large files**:
```
localGetFileContent(
  path="/workspace/src/large-file.ts",
  matchString="validateToken",  // only shows relevant sections
  matchStringContextLines=10
)
```

**Use `limit` and `page` for large result sets**:
```
githubSearchCode(
  keywordsToSearch=["auth"],
  owner="company",
  repo="monorepo",
  limit=50,  // per page
  page=1     // fetch more as needed
)
```

### Common Pitfalls

❌ **Don't use `localSearchCode` for precise symbols**
- Use `lspGotoDefinition` instead
- Search is lexical, LSP is semantic

❌ **Don't skip `lineHint` for LSP tools**
- LSP tools require accurate line numbers
- Get from search results first

❌ **Don't read entire files unnecessarily**
- Use `matchString` to target sections
- Read full file only when needed

❌ **Don't assume package names**
- Use `packageSearch` to find actual package
- Then use GitHub tools with correct repo name

## MCPS MCP

Provides access to Jira tickets and Slack messages for organizational context.

### Tool Categories

**Jira Tools**:
- Search tickets by keyword, project, status
- Get ticket details with comments and history
- Find related tickets

**Slack Tools**:
- Search messages by keyword, channel, date
- Get message thread context
- Find discussions by participant

### Jira Search Patterns

#### Pattern: Find Related Tickets

**Use case**: "Why did we choose Redis?"

**Sequence**:
1. Search for tickets:
   ```
   jira.search(
     query="Redis",
     project="BACKEND",
     status=["Done", "Closed"]
   )
   ```

2. Get ticket details:
   ```
   jira.getTicket(
     ticketKey="BACKEND-1234"
   )
   ```
   - Read description
   - Check comments for discussion
   - Follow linked tickets

3. Extract evidence:
   - Decision rationale from description
   - Comments explaining alternatives
   - Links to architecture docs

#### Pattern: Bug History

**Use case**: "Has this bug happened before?"

**Sequence**:
1. Search by symptoms:
   ```
   jira.search(
     query="users logged out randomly",
     type="Bug",
     project=["BACKEND", "FRONTEND"]
   )
   ```

2. Check status:
   - Open bugs: ongoing issues
   - Closed bugs: solutions or workarounds
   - Duplicates: patterns

3. Extract patterns:
   - Common root causes
   - Effective solutions
   - Related areas of code

### Slack Search Patterns

#### Pattern: Design Discussions

**Use case**: "Why did we implement X this way?"

**Sequence**:
1. Search engineering channels:
   ```
   slack.search(
     query="JWT authentication design",
     channels=["engineering", "backend-team"],
     dateRange="last 6 months"
   )
   ```

2. Get thread context:
   ```
   slack.getThread(
     messageLink="https://company.slack.com/archives/C123/p456789"
   )
   ```

3. Extract decisions:
   - What alternatives were considered?
   - Why was this approach chosen?
   - Who made the decision?

#### Pattern: Incident Reports

**Use case**: "When did this break?"

**Sequence**:
1. Search incident channels:
   ```
   slack.search(
     query="login failing",
     channels=["incidents", "alerts"],
     dateRange="last 30 days"
   )
   ```

2. Find resolution threads:
   - What was the root cause?
   - How was it fixed?
   - What commit/PR resolved it?

3. Cross-reference with code:
   - Use commit SHAs from Slack
   - Find PRs mentioned in threads
   - Trace to code changes

### Evidence Extraction Rules

**From Jira tickets**:
```
JIRA-1234: "Migrate to JWT authentication"

Extract:
- Decision: Why this approach? (from description)
- Timeline: When was it done? (from created/resolved dates)
- Author: Who decided? (from reporter/assignee)
- Context: What problem did it solve? (from description)
- Links: Related tickets or docs (from links section)
```

**From Slack messages**:
```
#engineering thread on 2024-01-15

Extract:
- Discussion: What was debated? (from thread messages)
- Decision: What was chosen? (from final message or reactions)
- Participants: Who was involved? (from message authors)
- Context: What prompted this? (from thread starter)
- Links: Any code/docs shared? (from links in messages)
```

### MCPS Search Best Practices

**Be specific with keywords**:
```
❌ "auth"  // too broad
✅ "JWT RS256 authentication"  // specific
```

**Search multiple timeframes**:
```
Recent: last 30 days (current work)
Medium: last 6 months (recent decisions)
Historical: last 2 years (architectural choices)
```

**Cross-reference sources**:
```
Jira ticket → mentions PR #567
→ Search Slack for "PR 567"
→ Find design discussion
→ Complete context assembled
```

**Use project/channel filters**:
```
✅ project="BACKEND" channel="backend-team"
❌ Search all projects/channels (noise)
```

### Integration with Octocode

**Flow: Jira → Code**
1. Find ticket describing feature
2. Get PR number from ticket
3. Use `githubSearchPullRequests` to find PR
4. Extract file paths from PR
5. Use `lspGotoDefinition` on those files

**Flow: Slack → Jira → Code**
1. Find Slack discussion
2. Extract mentioned ticket numbers
3. Get tickets from Jira
4. Follow to PRs and code
5. Assemble complete evidence chain

**Flow: Code → Jira → Slack**
1. Find code with `localSearchCode`
2. Get commit SHA with git blame
3. Find PR from commit
4. Find Jira ticket from PR description
5. Search Slack for ticket discussions

## Combined Search Strategy

### Full Forensic Investigation Template

**Goal**: Find complete answer with full evidence chain

**Step 1: Code Search** (Octocode)
- Find definitions, implementations, usages
- Trace call hierarchies
- Check git history

**Step 2: Context Mining** (MCPS)
- Find related Jira tickets
- Search Slack discussions
- Extract decision rationale

**Step 3: Cross-Reference**
- Link code to tickets via commits
- Link tickets to Slack via mentions
- Build complete timeline

**Step 4: Verification**
- Ensure code evidence is current
- Verify tickets are relevant
- Confirm Slack discussions are authoritative

**Step 5: Assembly**
- Primary evidence: Code locations
- Secondary evidence: Tickets and PRs
- Tertiary evidence: Discussions and docs

### Example: Complete Investigation

**Query**: "How is user session stored and why?"

**Octocode search**:
```
1. localSearchCode(pattern="session", path="/workspace")
   → Found: src/session/store.ts

2. lspGotoDefinition(symbolName="SessionStore", lineHint=42)
   → Definition: Uses Redis

3. Git history check:
   → Added in commit abc123 (2024-01-15)
   → PR #567: "Add Redis session store"
```

**MCPS search**:
```
1. jira.search(query="session storage Redis")
   → Found: BACKEND-1234 "Evaluate session storage options"

2. jira.getTicket(ticketKey="BACKEND-1234")
   → Description: "Need horizontally scalable session storage"
   → Comments: Compared Redis, Memcached, database
   → Decision: Redis for persistence + speed

3. slack.search(query="BACKEND-1234 Redis session")
   → Found: Discussion in #backend-team
   → Key quote: "Redis gives us persistence unlike Memcached"
```

**Complete evidence**:
```
PRIMARY EVIDENCE:
- Implementation: src/session/store.ts:15-80
  ```typescript
  class SessionStore {
    private redis: Redis;
    async get(sessionId: string) { ... }
  }
  ```

SECONDARY EVIDENCE:
- Commit: abc123 (2024-01-15) "Add Redis session store"
- PR: #567 (https://github.com/company/repo/pull/567)
- Jira: BACKEND-1234 "Evaluate session storage options"
  Quote: "Need horizontally scalable solution"
  Decision: "Redis chosen for persistence + speed"

TERTIARY EVIDENCE:
- Slack: #backend-team discussion (2024-01-10)
  Quote: "Redis gives us persistence unlike Memcached"
  Participants: @engineer1, @engineer2, @architect
```

This is forensic search done right: code + context + rationale, all verifiable.
