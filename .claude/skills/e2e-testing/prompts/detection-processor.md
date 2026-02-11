# Detection Processor Subagent Prompt Template

Parameterized template for the 4 detection subagents. Replace `[DETECTION_CONCERN]` and `[INSTRUCTIONS]` per concern.

```
Task tool:
  description: "e2e-testing: Detect [DETECTION_CONCERN]"
  prompt: |
    You are a detection subagent for E2E testing infrastructure. Your job is to
    analyze a single concern and return a structured JSON report.

    ## Detection Concern
    [DETECTION_CONCERN]: [ONE OF: infrastructure, framework, patterns, storybook]

    ## Project Root
    [ABSOLUTE_PATH_TO_PROJECT]

    ## Instructions

    ### If concern = "infrastructure"
    1. Glob for: *.e2e.*, *.spec.ts, *.sled.spec.*, *.sled3.spec.*
    2. Glob for: playwright.config.*, sled/sled.json
    3. Read package.json -- look for @wix/sled-playwright, @wix/sled-test-runner, @playwright/test
    4. Return JSON:
       {
         "framework": "sled3" | "sled2" | "playwright" | "none",
         "packages": ["@wix/sled-playwright@x.y.z", ...],
         "configs": ["playwright.config.ts", ...],
         "recommendation": "brief recommendation if none found"
       }

    ### If concern = "framework"
    1. Read package.json -- check wix.framework.type field
    2. Check devDependencies for @wix/yoshi-flow-* packages
    3. Determine test directory and run command per yoshi flow type
    4. Return JSON:
       {
         "yoshiFlow": "flow-bm" | "flow-editor" | "fullstack" | "flow-library" | "non-yoshi",
         "testDir": "e2e/" | "sled/" | "__tests__/" | "tests/e2e/",
         "runCommand": "sled-playwright test" | "sled-test-runner remote" | ...,
         "configFile": "playwright.config.ts" | "sled/sled.json" | ...
       }

    ### If concern = "patterns"
    1. Glob for: *.e2e.*, *.spec.ts, __e2e__/**, e2e/**
    2. If tests found: read 2-3 examples, analyze their style
    3. Return JSON:
       {
         "hasTests": true | false,
         "testFiles": ["path/to/test1.spec.ts", ...],
         "style": "bdd-drivers" | "flat-specs" | "page-objects" | "unknown",
         "conventions": {
           "usesDataHook": true | false,
           "usesBuilders": true | false,
           "usesDrivers": true | false,
           "importStyle": "relative" | "alias"
         }
       }

    ### If concern = "storybook"
    1. Glob for: .storybook/**, *.stories.tsx, *.stories.ts
    2. Check package.json for @wix/playwright-storybook-plugin
    3. Check for storybook-static/ directory
    4. Return JSON:
       {
         "hasStorybook": true | false,
         "hasPlugin": true | false,
         "storybookConfig": ".storybook/main.ts" | null,
         "staticBuildExists": true | false,
         "storyCount": N
       }

    ## Optional: Validate with Docs
    If wix-internal-docs MCP is available, validate your detection against
    official documentation for the detected framework.

    ## Before Reporting: Self-Review
    - Did I check all the paths mentioned in my instructions?
    - Is my JSON complete with all required fields?
    - Did I handle the "not found" case (return sensible defaults)?

    ## Report
    Return ONLY the JSON report for your concern. No prose needed.
```

## Per-Concern Dispatch Examples

**Infrastructure:**
```
description: "e2e-testing: Detect infrastructure"
Replace [DETECTION_CONCERN] with "infrastructure"
```

**Framework:**
```
description: "e2e-testing: Detect framework"
Replace [DETECTION_CONCERN] with "framework"
```

**Patterns:**
```
description: "e2e-testing: Detect patterns"
Replace [DETECTION_CONCERN] with "patterns"
```

**Storybook:**
```
description: "e2e-testing: Detect storybook"
Replace [DETECTION_CONCERN] with "storybook"
```
