---
name: team-project
description: Bootstrap and manage multi-agent development projects. Use when starting a new software project with the AI team, checking project status, or managing sprints. Triggers on "start project", "new project", "project status", "team standup", "sprint review", or any request to have the multi-agent team build something.
license: MIT
---

# Team Project Orchestrator

This skill manages multi-agent software development projects. It sets up autonomous work cycles where specialized agents (Engineer, SRE, Designer, PM, Reviewer) coordinate via shared documents and cron-based work cycles.

## Architecture

```
EXECUTION_PLAN.md    <-- PM owns milestones & gates
        |
        v reads
REVIEWER_FEEDBACK.md <-- Reviewer writes steering instructions
        |
        v reads first each cycle
Engineer / SRE / Designer --> implement using Claude Code
        |
        v updates
GAP_ANALYSIS.md      <-- checkboxes track completion
```

## Commands

### Start a New Project

When user says "start project [name]" or "build [something]":

1. Run the bootstrap script:
```bash
bash command:"~/.openclaw/workspace/skills/team-project/scripts/bootstrap.sh '[name]' '[path]' '[description]'"
```

This creates:
- GAP_ANALYSIS.md, EXECUTION_PLAN.md, REVIEWER_FEEDBACK.md in the project
- 5 autonomous cron work cycles (PM 45m, Reviewer 45m, Engineer 1h, SRE 1h, Designer 1h)
- Project registration in ~/.openclaw/team.json
- PM kickoff meeting to fill in the plan

2. Then ask the PM agent to fill in the gap analysis based on the project description and any existing code.

### Check Project Status

When user says "project status" or "how's the project":

```bash
bash command:"~/.openclaw/workspace/skills/team-project/scripts/manage.sh status"
```

### Team Standup

When user says "standup" or "team update":

```bash
bash command:"~/.openclaw/workspace/skills/team-project/scripts/manage.sh standup"
```

### Pause / Resume / Stop

```bash
bash command:"~/.openclaw/workspace/skills/team-project/scripts/manage.sh pause"
bash command:"~/.openclaw/workspace/skills/team-project/scripts/manage.sh resume"
bash command:"~/.openclaw/workspace/skills/team-project/scripts/manage.sh stop"
```

## Coordination Protocol

### The Three Documents

1. **EXECUTION_PLAN.md** (PM owns): Milestones with acceptance criteria, agent assignments, progress log. Sequential by default, parallel tracks marked explicitly.

2. **REVIEWER_FEEDBACK.md** (Reviewer owns): Per-agent steering with DO NOW / DO NOT instructions. Workers read this FIRST every cycle before picking tasks.

3. **GAP_ANALYSIS.md** (shared): Prioritized checklist (P0 > P1 > P2). Agents check items `[x]` as they complete them.

### The Cycle

Every 45 minutes:
- PM reads code changes, updates EXECUTION_PLAN.md, force-advances stale milestones
- Reviewer reads code, writes steering to REVIEWER_FEEDBACK.md, approves milestones when criteria met

Every 1 hour:
- Engineer reads feedback, reads plan, implements, updates gap
- SRE reads feedback, reads plan, implements, updates gap
- Designer reads feedback, reads plan, implements, updates gap

### Why Documents, Not Messages?

- Agents have no shared memory between cron sessions
- Files on disk are the only persistent coordination layer
- Markdown is human-readable -- users can intervene by editing files directly
- No infrastructure needed (no Redis, no Kafka, no database)

## Cron Message Templates

### PM (every 45m)
```
You are the PM. You OWN the execution plan. Every cycle:
1. READ [path]/EXECUTION_PLAN.md
2. READ [path]/GAP_ANALYSIS.md
3. CHECK code changes in [path]
4. UPDATE EXECUTION_PLAN.md: mark criteria, update status, log progress
5. FLAG blockers if agents are stuck or on wrong milestone

GATE POLICY:
- If a milestone is code-complete AND all acceptance criteria are checked, mark it COMPLETE.
- If code-complete for 2+ cycles with no P0 blockers, FORCE-ADVANCE to the next milestone.
- Only P0 issues (system won't run) block advancement. P1/P2 are advisory.
- Your job is to keep the team SHIPPING, not waiting.
```

### Reviewer (every 45m)
```
You are the CODE REVIEWER. Every cycle:
1. READ [path]/EXECUTION_PLAN.md for milestones
2. CHECK recent code in [path]
3. REVIEW: security, correctness vs milestone, architecture, TEST COVERAGE
4. WRITE steering to [path]/REVIEWER_FEEDBACK.md per agent
5. CHECK TEST COVERAGE: run test commands and report results

APPROVAL RULES:
- If ALL acceptance criteria for a milestone are checked, APPROVE IT. Write APPROVED clearly.
- Only block on P0 issues (system cannot run). P1/P2 are noted but do NOT block approval.
- A milestone code-complete for 2+ cycles MUST be approved or state the single remaining fix.
- After approving, tell agents to START the next milestone immediately.
- When you write a BLOCKER, you MUST assign it to a specific agent. Unassigned blockers are ignored.
- Your job is to STEER and UNBLOCK. Ship progress, not perfection.

TEST COVERAGE ENFORCEMENT:
- Check if new code has corresponding test files. Flag untested modules as P1.
- Backend target: 80%+ coverage. Frontend target: component tests for every page.
- If coverage drops below 60% on any new module, write a BLOCKER assigned to the module owner.
- Include test coverage summary in your feedback each cycle.
```

### Workers (every 1h)
```
You are the [ROLE]. Every cycle:
1. FIRST read [path]/REVIEWER_FEEDBACK.md for steering. Follow it.
2. If any BLOCKER is assigned to you, fix it IMMEDIATELY before doing anything else.
3. Read [path]/EXECUTION_PLAN.md for your milestone.
4. Read [path]/GAP_ANALYSIS.md for the checklist.
5. Implement using Claude Code: bash pty:true workdir:[path] command:"claude '[task]'"
6. WRITE TESTS for every feature you implement. Run tests before checking off items.
7. After implementing AND tests pass, update GAP_ANALYSIS.md to check off completed items.

TESTING RULES:
- Write tests FIRST (TDD): create test, make it fail, implement to pass.
- Target 80%+ coverage for any module you touch.
- Every new module MUST have a corresponding test file.
- Do NOT check off GAP_ANALYSIS items until tests pass.
```

## Key Principles

1. **PM owns the plan** -- defines milestones, sequences, acceptance criteria
2. **Reviewer steers** -- writes feedback that workers read first each cycle; must APPROVE milestones when criteria are met; enforces test coverage
3. **Workers follow** -- read feedback before picking tasks, stay on assigned milestone
4. **Test before check-off** -- every feature must have tests; workers write tests first (TDD) and only check off GAP_ANALYSIS items after tests pass
5. **Sequential milestones** -- no skipping ahead; parallel tracks explicitly marked
6. **Ship over perfection** -- P0 issues (system can't run) block advancement; P1/P2 are advisory. Milestones code-complete for 2+ cycles are force-advanced by PM.
