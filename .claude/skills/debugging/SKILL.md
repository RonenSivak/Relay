---
name: debugging
description: Systematic debugging for Wix full-stack applications (React frontend, Node.js backend, production incidents). Orchestrates Chrome DevTools, Grafana, Loki logs, Root Cause Analysis, Wix Internal Docs, Slack, and Jira MCPs. Use when investigating bugs, errors, performance issues, failed requests, production incidents, type mismatches, API errors, or when the user says "debug", "why is this failing", "not working", "investigate", or "root cause".
---

# Debugging

## Prerequisites: Start with Brainstorming

**MANDATORY**: Before debugging, invoke `/brainstorming` to clarify:

1. **What is the symptom?** - Error message, unexpected behavior, performance degradation?
2. **Where does it manifest?** - Browser, server, both, production?
3. **When did it start?** - After a deployment, intermittent, always?
4. **What's the impact?** - Blocking users, data loss, cosmetic?

## Decision Tree: Which Workflow?

```
What are you debugging?
│
├─ Browser/UI issue?
│  └─ Go to: Frontend Debugging
│
├─ Server/API error?
│  └─ Go to: Backend Debugging
│
├─ Production incident / alert firing?
│  └─ Go to: Production Incident Response
│
├─ Request fails end-to-end?
│  └─ Go to: Full-Stack Tracing
│
└─ Performance issue?
   ├─ Slow page load / UI jank → Frontend Debugging (performance section)
   └─ Slow API / high latency  → Backend Debugging (performance section)
```

## Core Principle: Simple First

**ALWAYS start with the most direct, obvious action:**

- Page not loading? → **Open it.** Navigate to the URL, see what happens.
- API returning errors? → **Call it.** See the actual error response.
- Button not working? → **Click it.** Watch the console and network.
- Service unhealthy? → **Check its dashboard.** Look at the metrics.

**Do NOT jump to indirect tools (Loki, Slack, Prometheus) before trying the obvious thing.** Reproduce the problem directly first, then investigate further only when the direct approach doesn't give you enough information.

For browser-related debugging, use the `/chrome-devtools` skill — see [SKILL.md](.cursor/skills/chrome-devtools/SKILL.md) for detailed tool usage.

## Core Methodology: The Loop

```
REPRODUCE → OBSERVE → HYPOTHESIZE → TEST → VERIFY
   ↑                                          │
   └──────────────────────────────────────────┘
```

1. **Reproduce**: Try the simplest, most direct action to see the problem firsthand
2. **Observe**: Gather evidence from what you see (errors, console, network, UI state)
3. **Hypothesize**: Form a theory — Wix docs (`search_docs`) can feed hypotheses here (may find nothing, that's fine)
4. **Test**: Validate or invalidate the theory with targeted checks
5. **Verify**: Confirm the fix resolves the issue without side effects

## Tool Selection Guide

| Situation | Primary MCP Tools | Fallback |
|-----------|------------------|----------|
| UI rendering issue | Chrome DevTools (`take_snapshot`, `take_screenshot`) | Manual browser inspection |
| JS console errors | Chrome DevTools (`list_console_messages`) | Browser console |
| Network failures | Chrome DevTools (`list_network_requests`) | Grafana Loki logs |
| Server errors | Grafana (`query_loki_logs`), Root Cause MCP | Server logs |
| Performance (FE) | Chrome DevTools (`performance_start_trace`) | Lighthouse |
| Performance (BE) | Grafana (`query_prometheus`, `find_slow_requests`) | APM dashboards |
| Production incident | Root Cause MCP, Grafana alerts, Loki logs | Manual log search |
| Quick hypothesis source (check first) | Wix Docs (`search_docs`, `fqdn_info`) — may find nothing, that's OK | Reading source code |
| Historical context | Slack (`search-messages`), Jira (`get-issues`) | Team knowledge |

## Workflow 1: Frontend Debugging

For Chrome DevTools MCP usage details, see the `/chrome-devtools` skill: [SKILL.md](.cursor/skills/chrome-devtools/SKILL.md)

### Quick Start

```
1. Chrome DevTools: navigate_page(url)        → REPRODUCE: load the page, see what happens
2. Chrome DevTools: take_screenshot           → What does the user actually see?
3. Chrome DevTools: list_console_messages     → Any JS errors?
4. Chrome DevTools: list_network_requests     → Any failed requests?
5. Chrome DevTools: take_snapshot             → Inspect DOM state if needed
```

### Console Errors

1. `list_console_messages` - Get all console output
2. Filter for `error` level messages
3. `evaluate_script` - Inspect specific variables or state
4. Trace error to source using stack trace + codebase search

### Network Failures

1. `list_network_requests` - List all requests
2. `get_network_request(id)` - Get details of failed request (headers, body, response)
3. Check: Is it CORS? Auth? Wrong payload? Server error?
4. If wrong payload or unexpected response: `fqdn_info` / `fqdn_schema` to verify expected API contract
5. Cross-reference with backend logs if 5xx

### UI State Issues

1. `take_snapshot` - Get accessibility tree (element UIDs)
2. `evaluate_script` - Check React state/props: `document.querySelector('[data-hook="X"]')`
3. `take_screenshot` - Visual comparison
4. Look for: Missing data, wrong conditionals, stale state

### Performance (Frontend)

1. `performance_start_trace(reload=true, autoStop=true)` - Record page load
2. `performance_analyze_insight` - Get LCP, CLS, FID analysis
3. Common causes: Large bundle, render-blocking resources, layout thrashing
4. `list_network_requests` - Check for slow/large resources

See `references/frontend-debugging.md` for detailed patterns.

## Workflow 2: Backend Debugging

### Quick Start

```
1. REPRODUCE: trigger the failing action      → See the actual error firsthand
2. Grafana: query_loki_logs                   → Search for error logs
3. Grafana: query_prometheus                  → Check error rate metrics
4. Root Cause: start_root_cause_analysis      → Automated RCA (if you have requestId)
5. Codebase: trace the code path              → Find the bug
```

### Error Investigation

1. **Get the error context**:
   - If you have a `requestId`: Use Root Cause MCP directly
   - If you have an error message: Search Loki logs with `query_loki_logs`
   - If you have a stack trace: Search codebase for the failing function
   - If the error involves a Wix API/service: `search_docs` or `fqdn_info` to check expected behavior, known issues, and correct usage

2. **Search logs** (Loki):
   ```
   {app="service-name"} |= "error" | json | level="error"
   ```
   - Always scope by service name and time range
   - Use `query_loki_stats` first to check stream size

3. **Trace the code path**:
   - Use octocode LSP: `localSearchCode` → `lspGotoDefinition` → `lspCallHierarchy`
   - Follow the execution path from entry point to failure

4. **Check recent changes**:
   - `git log --oneline -20` for recent commits
   - Correlate deployment time with error start time

### Performance (Backend)

1. `find_slow_requests` - Find slowest endpoints
2. `query_prometheus` - Check latency metrics (p50, p95, p99)
3. Common causes: N+1 queries, missing indexes, external service latency
4. `query_loki_logs` with timing filters

See `references/backend-debugging.md` for detailed patterns.

## Workflow 3: Production Incident Response

### Quick Start (Time-Critical)

```
1. Root Cause MCP: start_root_cause_analysis(requestId)  → Automated analysis
2. Grafana: list_alert_rules (state=firing)               → What's alerting?
3. Grafana: query_loki_logs                                → Error patterns
4. Slack: search-messages (in #incidents)                   → Team context
```

### Incident Triage

1. **Assess severity**: Check alert labels, affected users, error rate
2. **Start RCA**: If you have a `requestId`, immediately call `start_root_cause_analysis`
3. **Check dashboards**: `search_dashboards` for service-specific dashboards
4. **Error pattern analysis**: `find_error_pattern_logs` to find elevated error patterns
5. **Recent deployments**: Check rollout history for recent changes

### Automated Root Cause Analysis

```
1. start_root_cause_analysis(requestId="...", hint="optional context")
   → Returns analysisId + pollingUrl

2. Poll for results (takes 4-5 minutes):
   await_root_cause_analysis(analysisId="...")
   → RUNNING / COMPLETED / FAILED

3. Review markdown report with findings
```

### Communication & Tracking

- **Slack**: Search for related discussions, post updates to incident channel
- **Jira**: Create or update incident ticket with findings
  - Use `get-issues` to check for existing tickets
  - Use `create-issue` to open a new bug if needed

See `references/production-incidents.md` for detailed incident response patterns.

## Workflow 4: Full-Stack Tracing

When a request fails end-to-end:

1. **Reproduce**: Trigger the failing action in the browser (navigate, click, submit)
2. **Frontend**: `list_network_requests` → Find the failing request
3. **Get requestId**: From response headers (`x-request-id`) or `evaluate_script`
4. **Backend logs**: `query_loki_logs` with the requestId
5. **Root Cause**: `start_root_cause_analysis(requestId)` if complex
6. **Code trace**: Follow the request path through code with octocode LSP

## Common Anti-Patterns

| Anti-Pattern | Better Approach |
|-------------|----------------|
| Jumping to Loki/Slack/Prometheus before reproducing | **Reproduce first**: open the page, call the API, click the button |
| Overcomplicating with indirect tools | Start with the simplest, most direct action |
| Guessing the cause without evidence | Observe first: logs, metrics, network |
| Fixing symptoms instead of root cause | Trace to the actual source |
| Debugging in production directly | Reproduce locally first when possible |
| Ignoring error patterns | Use `find_error_pattern_logs` to spot trends |
| Not checking recent deployments | Always correlate with deployment timeline |
| Solo debugging for too long | Search Slack for similar issues, ask team |

## Evidence Standards

Same as `/deep-search` - never present findings without verifiable evidence:

- **Required**: Log lines with timestamps, file:line references, requestIds
- **Forbidden**: "It's probably a timeout issue" without evidence

## Jira Integration

When debugging reveals a confirmed bug:

1. Search existing tickets: `get-issues` with JQL filter
2. If no existing ticket: `create-issue` with:
   - Clear reproduction steps
   - Error logs / screenshots as evidence
   - Root cause analysis if known
   - Severity based on impact assessment
3. If existing ticket: `comment-on-issue` with new findings

## References

- `references/frontend-debugging.md` - Chrome DevTools patterns, React debugging, WDS component inspection
- `references/backend-debugging.md` - Loki queries, Prometheus metrics, Node.js debugging, Wix docs lookup
- `references/production-incidents.md` - Incident response playbook, RCA workflow, communication templates
- `references/mcp-tools-reference.md` - Quick reference for all debugging MCPs (incl. Wix Docs/Schema)
