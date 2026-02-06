# Workflow Examples

This document shows how skills combine to create complete workflows. All workflows follow: **Clarify → Plan → Execute → VERIFY → Publish**

## Workflow 1: Design and Implement New Component

**Scenario**: User says "Add a logout button to the user profile"

**Flow:**
1. **Clarify** (brainstorming)
   - Agent: Uses `/brainstorming`
   - Explores: Placement, styling, behavior on click, error handling
   - Output: Design validated with user

2. **Plan** (planning-with-files)
   - Create implementation plan
   - Steps: Add button component, wire up click handler, add API call, update tests
   - Output: plan.md

3. **Execute** (wds-docs + implementation)
   - Agent: References `/wds-docs` for Button component props
   - Implements button following WDS patterns
   - Adds click handler, API integration

4. **VERIFY**
   - Run tests: `npm test`
   - Run linters: `npm run lint`
   - Type check: `tsc --noEmit`
   - If all pass: proceed to Publish
   - If fail: fix and re-verify

5. **Publish**
   - Generate implementation-report.md
   - Show user what was implemented
   - Ask: "Tests pass. Ready to commit?"

**Skills used**: brainstorming → wds-docs
**Output**: Implementation + report + ready for commit

---

## Workflow 2: Refactor Existing Code

**Scenario**: User requests "Refactor the authentication middleware to be more testable"

**Flow:**
1. **Clarify** (brainstorming)
   - Agent: Uses `/brainstorming`
   - Questions: "What makes it hard to test now? Dependencies? State? Side effects?"
   - Explores: Extract pure functions vs dependency injection vs mocking strategy
   - Output: Agreed approach (e.g., "Extract validation logic to pure functions")

2. **Plan** (planning-with-files)
   - Create refactoring plan
   - Steps: Identify extraction points, create pure functions, update tests, migrate gradually
   - Output: refactor-plan.md

3. **Execute** (implementation)
   - Agent implements refactoring following plan
   - Extracts validation logic, updates middleware, creates tests

4. **VERIFY**
   - Run existing tests: ensure no regressions
   - Run new tests: verify extracted functions
   - Check coverage: `npm run coverage`
   - If uncertain: "I've extracted 3 functions but middleware still has some state. Continue or extract more?"

5. **Publish**
   - Generate refactor-report.md showing before/after
   - Present to user with test results
   - Ask: "Refactoring complete with no regressions. Ready to commit?"

**Skills used**: brainstorming
**Output**: Refactored code + report + test results

---

## Workflow 3: Document Technical Decision

**Scenario**: User says "Document why we chose Redis for session storage"

**Flow:**
1. **Clarify** (brainstorming)
   - Agent: Uses `/brainstorming`
   - Questions: "Should this cover alternatives considered? Performance requirements? Migration path?"
   - Output: Documentation scope agreed

2. **Plan** (planning-with-files)
   - Documentation outline
   - Sections: Context, requirements, alternatives, decision rationale, consequences
   - Output: doc-plan.md

3. **Execute** (documentation)
   - Agent: Reads existing session code to understand implementation
   - Drafts architectural decision record (ADR)
   - Includes: Why Redis? What alternatives? Trade-offs?

4. **VERIFY**
   - Check: All sections present? Technical accuracy? Clear rationale?
   - Cross-reference with actual implementation
   - If uncertain: "I stated Redis provides sub-millisecond latency. Is this the primary reason or was it horizontal scaling?"

5. **Publish**
   - Generate docs/decisions/0001-redis-sessions.md
   - Present to user
   - Ask: "Does this accurately capture the decision rationale?"

**Skills used**: brainstorming
**Output**: ADR document

---

## Shared Context Pattern

All workflows maintain continuity using shared context.

**Purpose**: Prevents the agent from losing track in multi-step workflows.

**Usage**:
- At each step, agent checks context: "What have we learned so far?"
- Updates context: "Adding decision: Using dependency injection over mocking"
- If confused: "Let me review my previous findings to remember why we chose this refactoring approach"

This ensures continuity across the Clarify → Plan → Execute → VERIFY → Publish flow.
