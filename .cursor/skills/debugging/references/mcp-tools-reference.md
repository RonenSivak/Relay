# MCP Tools Quick Reference for Debugging

## Chrome DevTools MCP

### Navigation & Pages
| Tool | Purpose | Key Params |
|------|---------|------------|
| `list_pages` | List open tabs | - |
| `select_page` | Switch active tab | `pageId` |
| `navigate_page` | Go to URL / reload | `url`, `action` |
| `wait_for` | Wait for text to appear | `text`, `timeout` |

### Inspection
| Tool | Purpose | Key Params |
|------|---------|------------|
| `take_snapshot` | Accessibility tree (get UIDs) | - |
| `take_screenshot` | Visual capture | `selector` (optional) |
| `evaluate_script` | Run JS in page context | `expression` |
| `list_console_messages` | Get console output | - |
| `get_console_message` | Specific message details | `id` |

### Network
| Tool | Purpose | Key Params |
|------|---------|------------|
| `list_network_requests` | All network activity | - |
| `get_network_request` | Request/response details | `id` |

### Performance
| Tool | Purpose | Key Params |
|------|---------|------------|
| `performance_start_trace` | Start profiling | `reload`, `autoStop` |
| `performance_stop_trace` | Stop profiling | - |
| `performance_analyze_insight` | Analyze trace results | - |

### Interaction (for reproducing bugs)
| Tool | Purpose | Key Params |
|------|---------|------------|
| `click` | Click element | `uid` (from snapshot) |
| `fill` | Type into input | `uid`, `value` |
| `press_key` | Keyboard input | `key` |

## Grafana MCP

### Logs (Loki)
| Tool | Purpose | Key Params |
|------|---------|------------|
| `list_datasources` | Find Loki datasource UID | `type="loki"` |
| `list_loki_label_names` | Available log labels | `datasourceUid` |
| `list_loki_label_values` | Values for a label | `datasourceUid`, `labelName` |
| `query_loki_stats` | Check stream volume (ALWAYS first) | `datasourceUid`, `logql` |
| `query_loki_logs` | Execute LogQL query | `datasourceUid`, `logql`, `limit` |
| `find_error_pattern_logs` | Elevated error patterns | `name`, `labels` |

### Metrics (Prometheus)
| Tool | Purpose | Key Params |
|------|---------|------------|
| `list_datasources` | Find Prometheus UID | `type="prometheus"` |
| `list_prometheus_metric_names` | Find metrics | `datasourceUid`, `regex` |
| `query_prometheus` | Execute PromQL | `datasourceUid`, `expr`, `queryType` |

### Dashboards & Alerts
| Tool | Purpose | Key Params |
|------|---------|------------|
| `search_dashboards` | Find dashboards | `query` |
| `get_dashboard_by_uid` | Dashboard details | `uid` |
| `list_alert_rules` | Active/firing alerts | `label_selectors` |
| `get_alert_rule_by_uid` | Alert details | `uid` |

### Tracing
| Tool | Purpose | Key Params |
|------|---------|------------|
| `find_slow_requests` | Slow request analysis | `name`, `labels` |

### Investigations
| Tool | Purpose | Key Params |
|------|---------|------------|
| `get_assertions` | Entity health assertions | `entityName`, `entityType` |
| `get_incident` | Incident details | `id` |
| `list_incidents` | Active/resolved incidents | `status` |

## Root Cause Analysis MCP

| Tool | Purpose | Key Params |
|------|---------|------------|
| `start_root_cause_analysis` | Start automated RCA | `requestId`, `hint`, `artifactIds` |
| `await_root_cause_analysis` | Poll for results | `analysisId`, `timeoutSeconds` |

**Workflow**: start → poll (repeat until COMPLETED) → review markdown report

**Timing**: Analysis takes 4-5 minutes. Poll with `timeoutSeconds=25`.

## Slack MCP

| Tool | Purpose | Key Params |
|------|---------|------------|
| `slack_find-channel-id` | Get channel ID by name | `channelName` |
| `search-messages` | Search across messages | `searchText`, `in`, `from`, `after` |
| `slack_get_channel_history` | Recent channel messages | `channel_id`, `limit` |
| `slack_get_thread_replies` | Thread conversation | `channel_id`, `thread_ts` |
| `slack_post_message` | Post to channel | `channel_id`, `text` |
| `slack_reply_to_thread` | Reply in thread | `channel_id`, `thread_ts`, `text` |

## Jira MCP

| Tool | Purpose | Key Params |
|------|---------|------------|
| `get-issues` | Search issues (JQL) | `projectKey`, `jql`, `maxResults` |
| `create-issue` | Create bug/incident ticket | `projectKey`, `summary`, `issueTypeId` |
| `update-issue` | Update existing ticket | `issueKey`, `description` |
| `comment-on-issue` | Add findings to ticket | `issueKey`, `comment` |

## Wix Internal Docs & Schema MCP

A cheap, fast **hypothesis source** — check early in any investigation. May surface known issues, expected behavior, or usage gotchas. Findings feed hypotheses (not conclusions) and still need validation. May also return nothing useful — that's fine, move on.

### Documentation Search
| Tool | Purpose | Key Params |
|------|---------|------------|
| `search_docs` | Search Wix internal documentation | `query` |

### FQDN / API Lookup
| Tool | Purpose | Key Params |
|------|---------|------------|
| `fqdn_lookup` | Find FQDNs by keyword (when exact FQDN unknown) | keywords (domain, product, resource) |
| `fqdn_info` | Get full API info: actions, events, schemas, permissions | FQDN (e.g. `wix.stores.v1.product`) |
| `fqdn_schema` | Get detailed schema for request/response/nested types | FQDN + schema name |
| `fqdn_service` | Get service ownership, artifact ID, team contacts | FQDN + service name |
| `client_lib` | Find SDK package name for an API | FQDN |

### When to Use During Debugging

Check docs early at any level. If something relevant turns up, add it to your hypotheses for validation.

| Situation | Tool | Example |
|-----------|------|---------|
| Unfamiliar component/SDK behavior | `search_docs` | "How does WDS Table pagination work?" |
| Unknown error message or code | `search_docs` | Search for the exact error string |
| Wrong request/response shape | `fqdn_info` → `fqdn_schema` | Check expected fields and types |
| UI component not rendering as expected | `search_docs` | Look up correct props, usage examples |
| Don't know which API to call | `fqdn_lookup` | Search by domain keyword (e.g. "stores", "members") |
| Configuration / setup question | `search_docs` | Platform conventions, SDK initialization |
| Need to contact the owning team | `fqdn_service` | Get team Slack channel and owners |
| Need the right import/package | `client_lib` | Get SDK package name |

## DevEx MCP (Service Info)

| Tool | Purpose | Key Params |
|------|---------|------------|
| `fleets_pods_overview` | Pod/fleet status | `serviceId` |
| `get_rollout_history` | Deployment history | `groupId`, `artifactId` |
| `get_project` | Project details | `projectName` |

## Tool Selection Cheat Sheet

```
"I see an error in the browser"
  → Chrome DevTools: list_console_messages

"API returns 500"
  → Chrome DevTools: get_network_request (get requestId)
  → Grafana: query_loki_logs (search by requestId)
  → Root Cause: start_root_cause_analysis (if complex)

"Page is slow"
  → Chrome DevTools: performance_start_trace
  → Grafana: find_slow_requests

"Alert is firing"
  → Grafana: list_alert_rules, get_alert_rule_by_uid
  → Grafana: query_loki_logs, query_prometheus

"How does X work?" / unfamiliar Wix SDK or component
  → Wix Docs: search_docs (docs, usage, examples)
  → Wix Docs: fqdn_lookup → fqdn_info (API details)

"Unknown error or unexpected behavior from a Wix service"
  → Wix Docs: search_docs (known issues, correct usage)
  → Wix Docs: fqdn_schema (verify expected types/contract)
  → Slack: search-messages (others hit this?)

"Need to find similar past issues"
  → Slack: search-messages
  → Jira: get-issues with JQL

"Service pods are unhealthy"
  → DevEx: fleets_pods_overview
  → Grafana: query_prometheus (resource metrics)
```
