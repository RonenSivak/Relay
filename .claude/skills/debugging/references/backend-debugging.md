# Backend Debugging Reference

## Loki Log Queries

### Finding the Right Datasource

```markdown
1. list_datasources(type="loki") → Get available Loki datasources
2. Note the UID of the relevant datasource
3. Always use query_loki_stats first to check volume before querying
```

### Essential LogQL Patterns

```logql
# Basic error search by service
{app="my-service"} |= "error" | json

# Search by requestId
{app="my-service"} |= "abc123-request-id"

# Error level only
{app="my-service"} | json | level="error"

# Specific error message pattern
{app="my-service"} |= "TimeoutError" | json

# Exclude noise
{app="my-service"} |= "error" !~ "health-check|readiness"

# With time range (always specify in tool params, not in query)
# Use startRfc3339 and endRfc3339 parameters
```

### Log Investigation Workflow

```markdown
Step 1: Check stream volume
  → query_loki_stats(logql='{app="my-service"}')
  → If streams > 100 or entries > 100K, narrow scope first

Step 2: Get error logs (start with small limit)
  → query_loki_logs(
      logql='{app="my-service"} |= "error" | json | level="error"',
      limit=20,
      startRfc3339="2026-02-06T10:00:00Z",
      endRfc3339="2026-02-06T11:00:00Z"
    )

Step 3: Identify patterns
  → Look for: repeated errors, common stack traces, correlated timestamps

Step 4: Deep dive specific error
  → query_loki_logs with requestId or unique error identifier
  → Get full request lifecycle logs
```

## Prometheus Metrics

### Finding Metrics

```markdown
1. list_datasources(type="prometheus") → Get Prometheus UID
2. list_prometheus_metric_names(regex="my_service.*error") → Find relevant metrics
3. list_prometheus_label_values(labelName="app") → Verify service name
```

### Essential PromQL Patterns

```promql
# Error rate (5xx) over time
rate(http_requests_total{app="my-service", status=~"5.."}[5m])

# Request latency percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app="my-service"}[5m]))

# Error ratio
sum(rate(http_requests_total{app="my-service", status=~"5.."}[5m]))
/
sum(rate(http_requests_total{app="my-service"}[5m]))

# CPU usage
rate(process_cpu_seconds_total{app="my-service"}[5m])

# Memory usage
process_resident_memory_bytes{app="my-service"}
```

### Metric Investigation Workflow

```markdown
Step 1: Check error rate
  → query_prometheus(
      expr='rate(http_requests_total{app="my-service", status=~"5.."}[5m])',
      queryType="range", startTime="now-1h", endTime="now", stepSeconds=60
    )

Step 2: Check latency
  → query_prometheus(
      expr='histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app="my-service"}[5m]))',
      queryType="range", startTime="now-1h", endTime="now", stepSeconds=60
    )

Step 3: Correlate with deployments
  → get_rollout_history to check recent deployments
  → Compare deployment time with metric spike time

Step 4: Check dependencies
  → query_prometheus for downstream service error rates
  → find_slow_requests for slow external calls
```

## Grafana Dashboards

```markdown
Step 1: Find service dashboard
  → search_dashboards(query="my-service")

Step 2: Get dashboard details
  → get_dashboard_by_uid(uid="...")
  → Review panel queries for relevant metrics

Step 3: Check alerts
  → list_alert_rules with label filter for service
  → get_alert_rule_by_uid for detailed alert config
```

## Root Cause Analysis MCP

### When to Use

- You have a specific `requestId` from a failed request
- Complex multi-service failure
- Need automated log correlation

### Workflow

```markdown
Step 1: Start analysis
  → start_root_cause_analysis(
      requestId="1743428994.68187642512522647652",
      hint="User getting 500 on checkout",
      artifactIds=["com.wixpress.my-service"]
    )
  → Returns: analysisId, pollingUrl

Step 2: Poll for results (4-5 minute typical)
  → await_root_cause_analysis(analysisId="...", timeoutSeconds=25)
  → If RUNNING: call again
  → If COMPLETED: review markdown report
  → If FAILED: fall back to manual log investigation

Step 3: Review findings
  → Report contains: error chain, root cause, affected services
  → Cross-reference with code using octocode LSP tools
```

## Wix Internal Docs Lookup

A cheap, fast **hypothesis source** — check early, but findings still need validation through logs/code. Docs may also return nothing useful; that's fine, move on to primary tools.

**Important**: When docs surface a relevant detail (e.g., "X happens if Y"), add it to your hypothesis list — don't treat it as a confirmed root cause.

### Finding Documentation

```markdown
Step 1: Quick search (may find nothing — that's OK)
  → search_docs(query="your question or error message")
  → Works for: components, SDKs, platform features, error messages, configuration
  → If useful: add findings to hypotheses for validation

Step 2 (if API-specific): Find the FQDN
  → fqdn_lookup(keywords related to the domain)
  → Example: fqdn_lookup("stores product") → finds wix.stores.v1.product

Step 3: Get API details
  → fqdn_info(fqdn="wix.stores.v1.product")
  → Returns: actions, request/response schemas, permissions, HTTP mappings

Step 4: Check specific schema
  → fqdn_schema(fqdn, schemaName) for detailed field types and nested structures
```

### Common Debugging Scenarios with Docs

```markdown
"Component not rendering / behaving as expected"
  → search_docs for component name, correct props, usage examples
  → Check: required props, event handlers, controlled vs uncontrolled

"Getting 400 Bad Request from a Wix API"
  → fqdn_info to check required fields and allowed values
  → fqdn_schema to verify exact types (string vs enum vs nested object)

"TypeError on response data"
  → fqdn_schema to check actual response shape vs what code expects
  → Look for: nullable fields, nested objects, enum values

"Don't know how to use SDK / platform feature"
  → search_docs with feature name or keyword
  → fqdn_lookup if it involves a service API

"Need to understand error codes from a service"
  → search_docs with the error message or code
  → fqdn_service to find owning team's Slack channel for questions
```

## Node.js Debugging Patterns

### Common Server Error Patterns

| Error Pattern | Likely Cause | Investigation |
|--------------|-------------|---------------|
| `ECONNREFUSED` | Downstream service down | Check dependency status in Grafana |
| `ETIMEDOUT` | Network/service slow | Check latency metrics + `find_slow_requests` |
| `ENOMEM` | Memory leak | Check memory metrics in Prometheus |
| `UnhandledPromiseRejection` | Missing error handler | Search code for unhandled async |
| `TypeError: Cannot read property` | Null/undefined data | Check input validation + data flow |
| `ECONNRESET` | Connection dropped | Check load balancer / proxy logs |

### Tracing Request Flow in Code

```markdown
1. Find the route handler
   → localSearchCode("app.get('/my-endpoint')" or "router.get")
   → Or search for the handler function name from logs

2. Trace the execution path
   → lspGotoDefinition on the handler function
   → lspCallHierarchy(outgoing) to see what it calls
   → Follow async chains through the code

3. Identify failure point
   → Match stack trace lines to code locations
   → Check error handling (try/catch, .catch(), error middleware)
   → Verify input validation at each step
```

## Slow Request Investigation

```markdown
Step 1: Find slow requests
  → find_slow_requests(
      labels={"app": "my-service"},
      name="Slow checkout investigation"
    )

Step 2: Identify bottleneck
  → Results show: slowest spans, time breakdown
  → Common bottlenecks: DB queries, external API calls, computation

Step 3: Database queries
  → Check for N+1 patterns in code
  → Look for missing indexes (get_schema_analysis if MySQL)
  → Check query execution plans (explain_sql_query)

Step 4: External dependencies
  → query_prometheus for downstream service latency
  → Check circuit breaker state in logs
```
