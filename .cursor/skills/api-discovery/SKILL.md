---
name: api-discovery
description: Discover Wix APIs, FQDNs, ambassador/SDK packages, and service contracts. Orchestrates docs-schema, octocode, devex, and wix-internal-docs MCPs. Use when the user asks "how do I call X", "find API for Y", "is there an ambassador for Z", wants to integrate with another Wix service, asks about FQDNs or schemas, or needs the right client library import.
---

# API Discovery

## Overview

API Discovery finds Wix APIs and client libraries by orchestrating multiple MCP servers. It handles three entry points: searching by capability ("I need an API that creates sites"), by service name ("what APIs does meta-site have?"), or by FQDN ("show me wix.sites.v1.site").

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before executing api-discovery, ALWAYS invoke `/brainstorming` first to:

1. **Clarify what the user needs** - A specific operation? An entire API surface? Usage examples?
2. **Determine the entry point** - Capability search, service lookup, or FQDN exploration?
3. **Define scope** - Just the contract, or also usage examples from other repos?

## When to Use This Skill

| Trigger | Example |
|---------|---------|
| Capability search | "Is there an API for creating sites?" |
| Service exploration | "What APIs does the payments service expose?" |
| FQDN lookup | "Show me the schema for wix.billing.v1.invoice" |
| Client library search | "What ambassador package lets me call the members API?" |
| Integration planning | "I need to integrate with the notifications service" |
| Cross-repo patterns | "How does editor use the site-properties API?" |

## Core Workflow

### Step 1: Determine Entry Point

Based on what the user knows, choose the right starting strategy:

**A) User describes a capability** → Start with `fqdn_lookup` + `search_docs`
```
"I need to send emails to users"
→ fqdn_lookup(keywords: "email send notification")
→ search_docs(query: "send email API")
```

**B) User names a service** → Start with `fqdn_lookup` + `get_project`
```
"What APIs does meta-site expose?"
→ fqdn_lookup(keywords: "meta site")
→ get_project(projectName: "com.wixpress.meta-site")
```

**C) User has an FQDN** → Start with `fqdn_info` directly
```
"Show me wix.contacts.v4.contact"
→ fqdn_info(fqdn: "wix.contacts.v4.contact")
```

### Step 2: Discover the API Surface

Use **docs-schema** MCP to get the full picture:

1. **`fqdn_lookup`** - Find matching FQDNs by keywords
2. **`fqdn_info`** - Get actions, events, permissions, HTTP mappings
3. **`fqdn_schema`** - Get request/response schemas with field details
4. **`fqdn_service`** - Get service ownership, artifact IDs, team contacts

If `fqdn_lookup` returns no results, broaden keywords or try synonyms. Search `wix-internal-docs` as a fallback.

### Step 3: Find the Client Library

Use **docs-schema** `client_lib` to find the ambassador/SDK package:

```
client_lib(fqdn: "wix.contacts.v4.contact")
→ Returns: SDK package name or ambassador package
```

If `client_lib` returns nothing:
1. Search with octocode: `githubSearchCode(keywordsToSearch: ["ambassador", "contacts"], owner: "wix-private")`
2. Search npm via octocode: `packageSearch(name: "@wix/ambassador-contacts", ecosystem: "npm")`

### Step 4: Find Usage Examples (Cross-Repo)

This step is critical for understanding how APIs are actually used in practice.

**Search in Wix repos** using octocode GitHub tools:
```
githubSearchCode(
  keywordsToSearch: ["import", "contacts-server"],
  owner: "wix-private"
)
```

**Priority repos to search** (common consumers):
- `wix-private/santa` - Viewer
- `wix-private/santa-editor` - Editor
- `wix-private/wix-ode` - ODE (Online Design Editor)
- `wix-private/thunderbolt` - Viewer platform

**What to look for**:
- Import statements for the ambassador/SDK package
- Configuration and initialization patterns
- Error handling approaches
- Common request/response patterns

### Step 5: Map Dependencies (Optional)

If the user wants to understand service topology:

1. **`list_bindings`** - Check database bindings for the service
2. **`search_projects`** - Find related projects by ownership tag
3. **`get_project`** - Get project details (repo, framework, ownership)

### Step 6: Assemble Findings

Present results in this structure:

```markdown
## API Discovery: [What was searched for]

### FQDN & API Contract
- **FQDN**: wix.example.v1.resource
- **Actions**: List, Get, Create, Update, Delete
- **Key schemas**: [Request/response shapes]

### Client Library
- **Package**: @wix/ambassador-example-server / @wix/sdk-...
- **Import**: `import { ExampleService } from '...'`

### Usage Examples
- [repo/file:line] - How service X uses this API
- [repo/file:line] - Another usage pattern

### Service Info
- **Ownership**: team-name
- **Artifact**: com.wixpress.example-service
- **Repo**: git@github.com:wix-private/example.git
```

## Search Strategies

### Broadening a Search

If initial keywords return nothing:
1. Try synonyms: "email" → "notification", "message", "send"
2. Drop version segment: `wix.email.v1.*` → search just "email"
3. Search docs: `search_docs(query: "email sending service")`
4. Search GitHub: `githubSearchCode(keywordsToSearch: ["sendEmail", "emailService"])`

### Narrowing Results

If too many FQDNs match:
1. Filter by version (prefer highest: v4 > v3 > v2)
2. Check `fqdn_service` for ownership to find the canonical service
3. Look at action names to match the specific capability needed

### Finding Undocumented APIs

Some APIs may not be in docs-schema. For these:
1. **octocode GitHub search**: Search for route definitions, gRPC service files, or REST endpoint patterns
2. **wix-internal-docs**: `search_docs(query: "...")` for internal documentation
3. **Cross-repo search**: Find how other teams call the service

## MCP Tools Quick Reference

| Goal | Tool | MCP Server |
|------|------|------------|
| Find FQDNs by keyword | `fqdn_lookup` | docs-schema |
| Get API actions/events | `fqdn_info` | docs-schema |
| Get schema details | `fqdn_schema` | docs-schema |
| Get service info | `fqdn_service` | docs-schema |
| Find client library | `client_lib` | docs-schema |
| Search internal docs | `search_docs` | docs-schema / wix-internal-docs |
| Search code in repos | `githubSearchCode` | octocode |
| Read files from repos | `githubGetFileContent` | octocode |
| View repo structure | `githubViewRepoStructure` | octocode |
| Search npm packages | `packageSearch` | octocode |
| Get project info | `get_project` | devex |
| Search projects | `search_projects` | devex |
| Check DB bindings | `list_bindings` | devex |

See `references/mcp-tools-reference.md` for detailed tool patterns and examples.

## Examples

### Example 1: Capability Search
```
User: "Is there an API for managing site members?"

1. fqdn_lookup(keywords: "members site")
   → wix.members.v1.member

2. fqdn_info(fqdn: "wix.members.v1.member")
   → Actions: ListMembers, GetMember, UpdateMember, DeleteMember, ...

3. client_lib(fqdn: "wix.members.v1.member")
   → @wix/ambassador-members-ng-server

4. githubSearchCode(keywordsToSearch: ["ambassador-members-ng"], owner: "wix-private")
   → Found usage in santa-editor/src/...

Output: FQDN, actions, client lib import, usage example
```

### Example 2: FQDN Deep Dive
```
User: "Show me the schema for wix.billing.v1.invoice"

1. fqdn_info(fqdn: "wix.billing.v1.invoice")
   → Actions, HTTP mappings, permissions

2. fqdn_schema(fqdn: "wix.billing.v1.invoice", schemaName: "Invoice")
   → Fields, types, nested schemas

3. fqdn_service(fqdn: "wix.billing.v1.invoice", serviceName: "InvoiceService")
   → Ownership, artifact ID, team contacts

Output: Full API contract with schema details and service info
```

### Example 3: Cross-Repo Usage Hunt
```
User: "How does the editor use the site-properties API?"

1. fqdn_lookup(keywords: "site properties")
   → wix.site_properties.v4.properties

2. client_lib(fqdn: "wix.site_properties.v4.properties")
   → @wix/ambassador-site-properties-service

3. githubSearchCode(
     keywordsToSearch: ["site-properties-service", "siteProperties"],
     owner: "wix-private",
     repo: "santa-editor"
   )
   → Found in packages/editor-platform/...

4. githubGetFileContent(owner: "wix-private", repo: "santa-editor", path: "...")
   → Read actual usage code

Output: Client lib + concrete usage patterns from editor codebase
```

## Integration with Workflows

This skill follows the standard workflow: **Clarify → Plan → Execute → VERIFY → Publish**

1. **Clarify**: Invoke `/brainstorming` - What API? What capability? What level of detail?
2. **Plan**: Choose entry point (A/B/C) and decide if cross-repo search is needed
3. **Execute**: Run through Steps 1-6 using MCP tools
4. **VERIFY**: Confirm FQDNs exist, client libs resolve, usage examples are current
5. **Publish**: Present findings in the standard output format
