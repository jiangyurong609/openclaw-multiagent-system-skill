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
- 5 autonomous cron work cycles (PM 20m, Reviewer 20m, Engineer 30m, SRE 30m, Designer 30m)
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

Every 20 minutes:
- PM reads code changes, updates EXECUTION_PLAN.md
- Reviewer reads code, writes steering to REVIEWER_FEEDBACK.md

Every 30 minutes:
- Engineer reads feedback, reads plan, implements, updates gap
- SRE reads feedback, reads plan, implements, updates gap
- Designer reads feedback, reads plan, implements, updates gap

### Why Documents, Not Messages?

- Agents have no shared memory between cron sessions
- Files on disk are the only persistent coordination layer
- Markdown is human-readable -- users can intervene by editing files directly
- No infrastructure needed (no Redis, no Kafka, no database)

## Cron Message Templates

### PM (every 20m)
```
You are the PM. You OWN the execution plan. Every cycle:
1. READ [path]/EXECUTION_PLAN.md
2. READ [path]/GAP_ANALYSIS.md
3. CHECK code changes in [path]
4. UPDATE EXECUTION_PLAN.md: mark criteria, update status, log progress
5. FLAG blockers if agents are stuck or on wrong milestone
```

### Reviewer (every 20m)
```
You are the CODE REVIEWER. Every cycle:
1. READ [path]/EXECUTION_PLAN.md for milestones
2. CHECK recent code in [path]
3. REVIEW: security, correctness vs milestone, architecture
4. WRITE steering to [path]/REVIEWER_FEEDBACK.md per agent
5. FLAG if agents are on wrong milestone
```

### Workers (every 30m)
```
You are the [ROLE]. Every cycle:
1. FIRST read [path]/REVIEWER_FEEDBACK.md for steering. Follow it.
2. Read [path]/EXECUTION_PLAN.md for your milestone.
3. Read [path]/GAP_ANALYSIS.md for the checklist.
4. Implement using Claude Code: bash pty:true workdir:[path] command:"claude '[task]'"
5. Update GAP_ANALYSIS.md to check off completed items.
```

## Key Principles

1. **PM owns the plan** -- defines milestones, sequences, acceptance criteria
2. **Reviewer steers** -- writes feedback that workers read first each cycle
3. **Workers follow** -- read feedback before picking tasks, stay on assigned milestone
4. **Sequential milestones** -- no skipping ahead; parallel tracks explicitly marked
5. **Acceptance gates** -- reviewer must approve before milestone is "done"
