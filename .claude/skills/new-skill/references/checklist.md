# Skill Validation Checklist

4-phase checklist adapted from Anthropic's Complete Guide to Building Skills for Claude (Reference A).

Check every item. If any fails, fix it before proceeding.

---

## Phase 1: Before You Start

- [ ] Identified 2-3 concrete use cases with triggers, steps, and expected results
- [ ] Tools identified (built-in capabilities, MCP servers, or scripts)
- [ ] Planned folder structure (SKILL.md + optional scripts/, references/, assets/)
- [ ] Reviewed existing skills for patterns to reuse

## Phase 2: During Development

### Structure
- [ ] Folder named in kebab-case (no spaces, underscores, or capitals)
- [ ] `SKILL.md` file exists (exact casing — not `SKILL.MD`, `skill.md`, or `Skill.md`)
- [ ] No `README.md` inside the skill folder

### Frontmatter
- [ ] YAML frontmatter has `---` delimiters (opening and closing)
- [ ] `name` field: kebab-case, no spaces, no capitals, matches folder name
- [ ] `description` field present and non-empty
- [ ] `description` includes WHAT the skill does
- [ ] `description` includes WHEN to use it (trigger conditions/phrases)
- [ ] `description` is under 1024 characters
- [ ] No XML angle brackets (`<` or `>`) anywhere in frontmatter
- [ ] Name does not contain "claude" or "anthropic"

### Content Quality
- [ ] Instructions are specific and actionable (not vague)
- [ ] Error handling / troubleshooting section included
- [ ] Examples with expected output provided
- [ ] References clearly linked (one level deep, not nested)
- [ ] Critical instructions placed at the top
- [ ] SKILL.md under 500 lines / 5,000 words
- [ ] Consistent terminology throughout (no mixing synonyms)

### Subagent Skills (if applicable)
- [ ] Has plan.md + def-done.md generation step
- [ ] Execution strategy section with parallelism options
- [ ] Red flags section blocking skipped reviews and self-justified direct mode
- [ ] Error handling for resource_exhausted fallback
- [ ] Processor prompt includes self-review and "Before You Begin" sections
- [ ] Reviewer prompt includes "Do Not Trust the Report" with DO/DON'T lists

## Phase 3: Before Sharing

- [ ] Tested triggering on obvious tasks (skill loads when expected)
- [ ] Tested triggering on paraphrased requests (different wording, same intent)
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass (correct output for representative inputs)
- [ ] Tool integration works (MCP calls succeed, scripts execute)

## Phase 4: After Registration

- [ ] Registered in the AGENTS.md corresponding to the target location
- [ ] Monitor for under-triggering (skill not loading when it should)
- [ ] Monitor for over-triggering (skill loading for irrelevant queries)
- [ ] Iterate on description and instructions based on feedback
- [ ] Update `metadata.version` if using versioning
