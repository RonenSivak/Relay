# MCP Tools Reference for API Discovery

Detailed patterns for using docs-schema, octocode, devex, and wix-internal-docs MCPs.

## docs-schema MCP

Primary tool for discovering Wix API contracts.

### fqdn_lookup

**Purpose**: Find FQDNs by keyword search across domain, product, and resource.

**When to use**: User describes a capability but doesn't know the FQDN.

```
fqdn_lookup(keywords: "contacts email members")
→ Returns: matching FQDNs like wix.contacts.v4.contact
```

**Tips**:
- Use multiple keywords for better results
- Try domain terms: "billing", "members", "sites", "media"
- If no results, try synonyms or broader terms
- Wildcards in version segment supported: `wix.contacts.*.contact`

### fqdn_info

**Purpose**: Get full API info — actions, events, HTTP mappings, permissions, request/response schemas.

**When to use**: You have an FQDN and need to understand its API surface.

```
fqdn_info(fqdn: "wix.contacts.v4.contact")
→ Returns: actions (Create, Get, List, Update, Delete), events, HTTP mappings, permissions
```

**What to extract**:
- Action names and their HTTP methods/paths
- Request/response schema names (use with `fqdn_schema`)
- Required permissions
- Event types (for webhooks/subscriptions)

### fqdn_schema

**Purpose**: Get detailed field-level schema for request/response types.

**When to use**: Need to understand request payloads, response shapes, or nested structures.

```
fqdn_schema(fqdn: "wix.contacts.v4.contact", schemaName: "Contact")
→ Returns: fields, types, nested member schemas
```

**Tips**:
- Schema names come from `fqdn_info` action request/response types
- Nested schemas can be queried by their member schema name
- Look for enum fields to understand allowed values

### fqdn_service

**Purpose**: Get service ownership, artifact IDs, server mappings, team contacts.

**When to use**: Need to know who owns an API or find the artifact ID for further investigation.

```
fqdn_service(fqdn: "wix.contacts.v4.contact", serviceName: "ContactsService")
→ Returns: ownership, artifact ID, team contact info
```

### client_lib

**Purpose**: Find the ambassador/SDK package for calling an API.

**When to use**: Need the import path for a client library.

```
client_lib(fqdn: "wix.contacts.v4.contact")
→ Returns: SDK package name (e.g., @wix/ambassador-contacts-v4-server)
```

**Fallback if no result**:
1. Search GitHub: `githubSearchCode(keywordsToSearch: ["ambassador", "<service-name>"])`
2. Search npm: `packageSearch(name: "@wix/ambassador-<service-name>")`

### search_docs

**Purpose**: Search Wix internal documentation for API references, guides, and tutorials.

**When to use**: FQDN tools don't return enough info, or you need conceptual documentation.

```
search_docs(query: "how to send transactional emails")
→ Returns: matching documentation resources with metadata
```

## octocode MCP

Used for cross-repo code search and finding real-world API usage patterns.

### githubSearchCode — Finding API Usage

**Primary pattern**: Find how other services call an API.

```
githubSearchCode(
  keywordsToSearch: ["ambassador-contacts", "ContactsService"],
  owner: "wix-private",
  match: "file"
)
→ Returns: files containing the import/usage
```

**Narrowing to specific repos**:
```
githubSearchCode(
  keywordsToSearch: ["siteProperties", "import"],
  owner: "wix-private",
  repo: "santa-editor",
  match: "file"
)
```

**Search strategies by what you're looking for**:

| Goal | Keywords to search |
|------|--------------------|
| Ambassador imports | `["ambassador-<service>", "import"]` |
| SDK imports | `["@wix/sdk", "<service-name>"]` |
| gRPC service calls | `["<ServiceName>", "rpcClient"]` |
| REST calls | `["<endpoint-path>", "fetch"]` or `["<endpoint-path>", "axios"]` |

### githubGetFileContent — Reading Usage Code

**After finding files with `githubSearchCode`**, read the actual implementation:

```
githubGetFileContent(
  owner: "wix-private",
  repo: "santa-editor",
  path: "packages/editor-platform/src/api/contacts.ts",
  matchString: "ContactsService",
  matchStringContextLines: 20
)
```

**Tips**:
- Use `matchString` to avoid reading entire large files
- Set `matchStringContextLines: 15-20` for sufficient context
- Look for initialization patterns, error handling, and response processing

### githubViewRepoStructure — Exploring API Directories

**When you found a repo but need to locate the right file**:

```
githubViewRepoStructure(
  owner: "wix-private",
  repo: "santa-editor",
  branch: "master",
  path: "packages/editor-platform/src/api",
  depth: 1
)
```

### githubSearchRepositories — Finding Service Repos

**When you know the service name but not the repo**:

```
githubSearchRepositories(
  keywordsToSearch: ["contacts-service"],
  owner: "wix-private"
)
```

### packageSearch — Finding NPM Packages

**When looking for ambassador/SDK packages**:

```
packageSearch(
  name: "@wix/ambassador-contacts-v4-server",
  ecosystem: "npm"
)
→ Returns: package info including repo URL
```

**Search patterns**:
- Ambassador: `@wix/ambassador-<service-name>-server`
- SDK: `@wix/sdk-<domain>`
- If exact name unknown, try partial: `@wix/ambassador-contacts`

## devex MCP

Used for understanding service topology and project metadata.

### get_project

**Purpose**: Get project details including repo, framework, ownership, versions.

```
get_project(projectName: "com.wixpress.contacts-server")
→ Returns: repo URL, ownership tag, framework, RC/GA versions
```

### search_projects

**Purpose**: Find projects by ownership tag or other criteria.

First get the schema via `get_devex_fqdn(fqdn: "wix.devex.ci.v1.project_data")`, then query:

```
search_projects(search: {
  filter: { "ownershipTag": "contacts-team" },
  cursorPaging: { limit: 20 }
})
```

### list_bindings

**Purpose**: Find database bindings for a service (shows dependencies).

```
list_bindings(artifactId: "com.wixpress.contacts-server")
→ Returns: database clusters, types, binding details
```

## wix-internal-docs MCP

### search_docs

**Purpose**: Search Wix internal documentation for guides, architecture docs, and API references.

```
search_docs(query: "contacts API integration guide")
→ Returns: matching documentation with portal IDs and resource IDs
```

**When to use**:
- API not found via docs-schema tools
- Need conceptual/architectural documentation
- Looking for integration guides or best practices

## Combined Search Patterns

### Pattern: Full API Discovery (Unknown Capability)

```
1. fqdn_lookup(keywords: "send email notification")
   → Found: wix.notifications.v1.notification

2. fqdn_info(fqdn: "wix.notifications.v1.notification")
   → Actions: Send, BulkSend, ...

3. fqdn_schema(fqdn: "...", schemaName: "SendNotificationRequest")
   → Request fields and types

4. client_lib(fqdn: "wix.notifications.v1.notification")
   → @wix/ambassador-notifications-server

5. githubSearchCode(keywordsToSearch: ["ambassador-notifications", "import"], owner: "wix-private")
   → Usage examples in other repos

6. githubGetFileContent(...)
   → Read actual usage code
```

### Pattern: Service Integration Planning

```
1. get_project(projectName: "com.wixpress.target-service")
   → Repo, ownership, versions

2. fqdn_lookup(keywords: "<service-domain>")
   → All FQDNs for this service

3. For each relevant FQDN:
   a. fqdn_info → Actions
   b. client_lib → Package name

4. githubSearchCode in YOUR repo
   → Check if already integrated

5. githubSearchCode in other repos
   → Find integration examples to follow
```

### Pattern: Ambassador Package Hunt

```
1. client_lib(fqdn: "wix.example.v1.resource")
   → If found: done

2. If not found:
   packageSearch(name: "@wix/ambassador-example", ecosystem: "npm")
   → Check multiple naming patterns

3. If still not found:
   githubSearchCode(keywordsToSearch: ["example-service", "ambassador"], owner: "wix-private")
   → Find by usage in other repos

4. If still not found:
   search_docs(query: "example service client library")
   → Check documentation for integration guide
```
