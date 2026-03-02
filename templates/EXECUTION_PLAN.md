# Execution Plan & Milestones

**Owner:** PM Agent
**Project:** <!-- Project name -->
**Updated:** <!-- PM updates each cycle -->

---

## Milestone 1: <!-- Name -->
**Goal:** <!-- One sentence -->
**Acceptance Criteria:**
- [ ] <!-- Specific, testable criteria -->
- [ ] <!-- Must be verifiable by Reviewer -->

**Assigned:**
- Engineer: <!-- Specific tasks -->
- SRE: <!-- Specific tasks -->

**Status:** NOT STARTED
**Blockers:** None

---

## Milestone 2: <!-- Name -->
**Goal:** <!-- One sentence -->
**Acceptance Criteria:**
- [ ] <!-- Criteria -->

**Assigned:**
- <!-- Agent: tasks -->

**Status:** NOT STARTED
**Blockers:** M1 must complete first

---

## Milestone 3: <!-- Name -->
**Goal:** <!-- One sentence -->
**Acceptance Criteria:**
- [ ] <!-- Criteria -->

**Assigned:**
- <!-- Agent: tasks -->

**Status:** NOT STARTED (can run parallel with M2)
**Blockers:** None

---

## Agent Assignments (Current Sprint)

| Agent | Current Task | Milestone | Priority |
|-------|-------------|-----------|----------|
| Engineer | | M1 | P0 |
| SRE | | M1 | P0 |
| Designer | | M3 | P0 |
| Reviewer | Review all | ALL | Ongoing |
| PM | Track progress | ALL | Ongoing |

## Coordination Rules

1. **Sequential milestones** -- M1 before M2 before M4 (unless marked parallel)
2. **Completion policy** -- a milestone is COMPLETE when all acceptance criteria are checked. If code-complete for 2+ cycles with no P0 blockers, PM force-advances to next milestone.
3. **Reviewer feedback** -- advisory for P1/P2 issues. Only P0 (system cannot run) blocks advancement. Reviewer must explicitly APPROVE milestones when criteria are met.
4. **PM updates** -- PM updates this file every cycle with actual status
5. **Blockers** -- if an agent is blocked, PM notes it here with suggested unblocking. Agents must not idle waiting for approval.
6. **File changes** -- agents update GAP_ANALYSIS.md checkboxes when items complete

## Progress Log

<!-- PM: Add a timestamped entry each cycle -->

### Cycle 1
- <!-- What happened this cycle -->
