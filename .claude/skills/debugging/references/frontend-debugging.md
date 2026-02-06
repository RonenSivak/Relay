# Frontend Debugging Reference

For Chrome DevTools MCP tool details, see the `/chrome-devtools` skill: [SKILL.md](../.cursor/skills/chrome-devtools/SKILL.md)

## First: Reproduce the Problem

Before any investigation, **reproduce the issue directly**:

```markdown
Step 1: Navigate to the page/URL
  → navigate_page(url="https://...")
  → Or if page is already open: list_pages → select_page

Step 2: See what happens
  → take_screenshot → What does the user see?
  → Is the page blank? Error screen? Partial load? Wrong content?

Step 3: Then investigate based on what you observe
  → Blank page / error → Console Error Investigation
  → Partial load / spinner stuck → Network Request Debugging
  → Wrong layout / missing elements → DOM and Layout Debugging
  → Slow → Performance Profiling
```

## Chrome DevTools MCP - Detailed Patterns

### Console Error Investigation

```markdown
Step 1: List all console messages
  → list_console_messages
  → Filter by level: "error", "warning"

Step 2: Get specific error details
  → get_console_message(id=<error_id>)
  → Extract: message text, stack trace, source URL

Step 3: Evaluate page state at error point
  → evaluate_script(expression="window.__STORE__?.getState()")
  → evaluate_script(expression="document.querySelector('[data-hook=\"my-hook\"]')?.textContent")

Step 4: Trace to source
  → Use stack trace file:line to search codebase
  → localSearchCode(pattern="functionName") → lspGotoDefinition
```

### Network Request Debugging

```markdown
Step 1: List all network requests
  → list_network_requests
  → Sort by: status (4xx/5xx first), duration (slowest first)

Step 2: Inspect failed request
  → get_network_request(id=<request_id>)
  → Check: status, headers, request body, response body

Step 3: Common failure patterns
  → 401/403: Auth token expired or missing
     → evaluate_script("document.cookie") or check Authorization header
  → 404: Wrong URL or missing resource
     → Compare URL with API documentation
  → 500: Server error
     → Extract requestId from response headers
     → Switch to Backend Debugging workflow
  → CORS: Missing Access-Control headers
     → Check Origin header vs allowed origins
  → Timeout: Request took too long
     → Check server performance metrics
```

### React Component Debugging

```markdown
Step 1: Inspect component state
  → evaluate_script(`
    const fiber = document.querySelector('[data-hook="my-component"]')?.__reactFiber$;
    const state = fiber?.memoizedState;
    JSON.stringify(state, null, 2);
  `)

Step 2: Check props
  → evaluate_script(`
    const el = document.querySelector('[data-hook="my-component"]');
    const key = Object.keys(el).find(k => k.startsWith('__reactProps$'));
    JSON.stringify(el[key], null, 2);
  `)

Step 3: Look for re-render causes
  → Performance trace: performance_start_trace(reload=false, autoStop=false)
  → Trigger the action that causes re-render
  → performance_stop_trace
  → performance_analyze_insight → Look for "Rendering" section
```

### WDS Component Inspection

WDS components use `data-hook` attributes for test and debug identification.

```markdown
Step 1: Find the component
  → take_snapshot → Search for data-hook value
  → Or: evaluate_script("document.querySelector('[data-hook=\"my-hook\"]')?.outerHTML")

Step 2: Check component state via testkit pattern
  → evaluate_script to inspect:
     - Input values: querySelector('[data-hook="my-input"] input').value
     - Button state: querySelector('[data-hook="my-btn"]').disabled
     - Dropdown open: querySelector('[data-hook="my-dropdown"] [data-open]')

Step 3: Check for error boundaries
  → take_snapshot → Look for error boundary fallback UI
  → list_console_messages → Look for "Error boundary caught" messages
```

### Performance Profiling (Frontend)

```markdown
Step 1: Record a trace
  → performance_start_trace(reload=true, autoStop=true)
  → Wait for page to fully load

Step 2: Analyze
  → performance_analyze_insight
  → Key metrics to check:
     - LCP (Largest Contentful Paint): Should be < 2.5s
     - CLS (Cumulative Layout Shift): Should be < 0.1
     - FID/INP (Interaction to Next Paint): Should be < 200ms

Step 3: Common bottlenecks
  → Large JavaScript bundles: Check network tab for JS file sizes
  → Render-blocking resources: Check for sync scripts in <head>
  → Layout thrashing: Look for forced reflows in trace
  → Excessive re-renders: Look for React rendering in trace
  → Slow images: Check for unoptimized/large images in network

Step 4: Targeted investigation
  → For specific interaction: performance_start_trace(reload=false)
  → Perform the slow action
  → performance_stop_trace → performance_analyze_insight
```

### DOM and Layout Debugging

```markdown
Step 1: Visual check
  → take_screenshot → Compare with expected layout
  → take_screenshot(selector="[data-hook='specific-element']") → Focused view

Step 2: Inspect computed styles
  → evaluate_script(`
    const el = document.querySelector('[data-hook="my-element"]');
    const styles = window.getComputedStyle(el);
    JSON.stringify({
      display: styles.display,
      visibility: styles.visibility,
      opacity: styles.opacity,
      width: styles.width,
      height: styles.height,
      overflow: styles.overflow,
    });
  `)

Step 3: Check for hidden elements
  → evaluate_script(`
    const el = document.querySelector('[data-hook="missing-element"]');
    el ? { exists: true, visible: el.offsetParent !== null } : { exists: false }
  `)
```

## Common Frontend Bug Patterns

| Symptom | Likely Cause | Investigation |
|---------|-------------|---------------|
| Blank page | JS error in render | `list_console_messages` |
| Spinner stuck | API never resolves | `list_network_requests` (pending) |
| Wrong data shown | Stale state/cache | Inspect React state via evaluate_script |
| Button doesn't work | Event handler error | Console errors + evaluate_script |
| Layout broken | CSS/style issue | Screenshot + computed styles |
| Flicker/jump | CLS / re-render | Performance trace |
| Slow page load | Large bundle/resources | Network requests + performance trace |
| "Not found" page | Routing issue | Check URL + route config in code |
