# Production Incident Response Reference

## Incident Triage Checklist

```
Triage Progress:
- [ ] Identify symptom (what's broken?)
- [ ] Assess blast radius (who's affected?)
- [ ] Check for recent deployments
- [ ] Start automated RCA if requestId available
- [ ] Communicate status to team
- [ ] Identify root cause
- [ ] Apply fix or rollback
- [ ] Verify resolution
- [ ] Document findings
```

## Step 1: Assess the Situation

### Check Alerts

```markdown
→ list_alert_rules(label_selectors=[{filters: [{name: "app", type: "=", value: "my-service"}]}])
→ Filter for state: "firing" or "pending"
→ get_alert_rule_by_uid(uid) for alert details and thresholds
```

### Check Error Patterns

```markdown
→ find_error_pattern_logs(
    name="Incident investigation - my-service",
    labels={"app": "my-service"},
    start="2026-02-06T10:00:00Z"  # When incident started
  )
→ Returns: elevated error patterns compared to baseline
```

### Check Deployment Timeline

```markdown
→ get_rollout_history(groupId="com.wixpress", artifactId="my-service")
→ Compare last deployment time with incident start
→ If correlated: this is likely a deployment-caused incident
```

## Step 2: Automated Root Cause Analysis

When you have a requestId from the failing request:

```markdown
→ start_root_cause_analysis(
    requestId="<requestId from error>",
    hint="Users seeing 500 on /api/checkout since 10:30 UTC",
    artifactIds=["com.wixpress.my-service"],
    fromDate="2026-02-06T10:25:00Z",
    toDate="2026-02-06T10:45:00Z"
  )

→ Poll with await_root_cause_analysis(analysisId, timeoutSeconds=25)
→ Repeat polling until COMPLETED or FAILED (typically 4-5 min)
```

## Step 3: Manual Investigation (if RCA not available)

### Error Log Analysis

```markdown
1. query_loki_stats to check volume
2. query_loki_logs with error filter
3. Look for:
   - First occurrence timestamp (when did it start?)
   - Error frequency (constant vs. intermittent?)
   - Affected endpoints (one route vs. all?)
   - Common requestIds or user patterns
```

### Metric Correlation

```markdown
1. Error rate spike: When exactly did errors start?
2. Latency change: Did latency increase before errors?
3. Resource usage: CPU/memory spike?
4. Dependency health: Are downstream services healthy?
5. Traffic pattern: Traffic spike causing overload?
```

### Infrastructure Checks

```markdown
→ fleets_pods_overview(serviceId="com.wixpress.my-service")
→ Check: pod count, served versions across DCs, pod status
→ Look for: pods in CrashLoopBackoff, version mismatches, DC-specific issues
```

## Step 4: Communication

### Search for Existing Context

```markdown
→ search-messages(searchText="my-service error", in="#incidents")
→ search-messages(searchText="my-service", in="#my-team-channel", after="2026-02-06")
→ Check if someone else is already investigating
```

### Post Update (if needed)

```markdown
→ slack_find-channel-id(channelName="incidents")
→ slack_post_message(channel_id, text="Investigating elevated 5xx on my-service since 10:30 UTC. Error pattern: [description]. Checking recent deployment.")
```

### Create/Update Jira Ticket

```markdown
→ get-issues(projectKey="PROJ", jql="summary ~ 'my-service' AND status != Done", maxResults=5)
→ If no existing ticket:
  create-issue(
    projectKey="PROJ",
    summary="[Incident] Elevated 5xx errors on my-service",
    issueTypeId="<bug_type_id>",
    description="## Symptom\n...\n## Timeline\n...\n## Root Cause\n...\n## Resolution\n..."
  )
→ If existing ticket:
  comment-on-issue(issueKey="PROJ-123", comment="New findings: ...")
```

## Step 5: Resolution

### Verify Fix

```markdown
After applying fix or rollback:
1. query_loki_logs → Errors stopped?
2. query_prometheus → Error rate back to normal?
3. list_alert_rules → Alerts resolved?
4. Chrome DevTools (if UI issue) → Page working?
5. Monitor for 15-30 minutes for recurrence
```

### Post-Incident

```markdown
1. Update Jira ticket with:
   - Root cause
   - Resolution applied
   - Timeline of events
   - Follow-up actions needed

2. Slack thread update:
   - "Resolved: [brief description of fix]"
```

## Common Incident Patterns

| Pattern | Typical Cause | Quick Check |
|---------|--------------|-------------|
| Sudden 5xx spike | Bad deployment | `get_rollout_history` |
| Gradual degradation | Memory/connection leak | Prometheus memory/connection metrics |
| Intermittent failures | Flaky dependency | Downstream service metrics |
| DC-specific errors | Infrastructure issue | `fleets_pods_overview` |
| After traffic spike | Resource exhaustion | Traffic + CPU/memory metrics |
| Single endpoint failing | Code bug in that route | Loki logs filtered by endpoint |

## Rollback Decision Tree

```
Is the incident caused by a recent deployment?
│
├─ Yes, clearly correlated
│  ├─ Can we rollback safely? (no DB migrations, no breaking changes)
│  │  └─ Yes → Rollback immediately, investigate after
│  │  └─ No  → Apply hotfix or feature flag
│  │
├─ No / Unclear
│  └─ Continue investigation, don't rollback blindly
│
└─ Infrastructure issue (not code)
   └─ Escalate to infrastructure team
```
