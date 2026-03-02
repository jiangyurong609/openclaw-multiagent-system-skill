# Architecture

## System Overview

openclaw-team coordinates autonomous AI agents via shared markdown documents
and cron-based work cycles. No message queues, no databases, no infrastructure
beyond what OpenClaw already provides.

## Component Diagram

```
                    openclaw-team CLI
                          |
                    setup.sh / new
                          |
            +-------------+-------------+
            |                           |
      Agent Identities            Cron Work Cycles
     (IDENTITY.md + SOUL.md)     (openclaw cron)
            |                           |
            v                           v
    +-------------------------------------------+
    |           OpenClaw Gateway                 |
    |  (manages agents, cron, model routing)     |
    +-------------------------------------------+
            |                           |
     Agent Sessions              Shared Documents
     (isolated, per-cron)        (on-disk markdown)
```

## Coordination Protocol

### The Three Documents

All agent coordination happens through three markdown files in the project
directory. This is the entire coordination layer -- no other state is shared.

```
EXECUTION_PLAN.md          REVIEWER_FEEDBACK.md
(PM owns milestones)       (Reviewer steers agents)
      |                          |
      v                          v
 +---------+    reads first    +-----------+
 | Engineer |<-----------------| Reviewer  |
 | SRE      |                  | (20 min)  |
 | Designer |                  +-----------+
 | (30 min) |                       ^
 +---------+                        |
      |                        reads code
      v
 GAP_ANALYSIS.md
 (checkboxes track progress)
```

#### EXECUTION_PLAN.md (PM owns)
- Defines sequential milestones with acceptance criteria
- Assigns agents to specific tasks per milestone
- Contains progress log updated every PM cycle
- Milestones must complete in order (unless marked parallel)

#### REVIEWER_FEEDBACK.md (Reviewer owns)
- Per-agent steering: DO NOW / DO NOT instructions
- Workers read this FIRST every cycle before anything else
- Primary mechanism for course-correction
- Updated every reviewer cycle

#### GAP_ANALYSIS.md (shared)
- Prioritized checklist: P0 (critical) > P1 (important) > P2 (nice-to-have)
- Agents check items `[x]` as they complete them
- PM monitors completion rate
- Contains implementation guidelines per role

### The Cycle

```
Every 20 minutes:
  PM    -> reads code changes -> updates EXECUTION_PLAN.md
  Reviewer -> reads code     -> writes REVIEWER_FEEDBACK.md

Every 30 minutes:
  Engineer -> reads feedback -> reads plan -> implements -> updates gap
  SRE      -> reads feedback -> reads plan -> implements -> updates gap
  Designer -> reads feedback -> reads plan -> implements -> updates gap
```

### Why Documents, Not Messages?

1. **No shared memory**: Each cron cycle starts a fresh isolated session.
   Agents cannot remember previous sessions.
2. **Files persist**: Markdown on disk is the only state that survives across
   sessions.
3. **Human-readable**: Users can read, edit, and steer agents by modifying
   the documents directly.
4. **No infrastructure**: No Redis, Kafka, or database needed. Just files.
5. **Auditable**: Complete decision trail in version-controllable markdown.

## Agent Roles

### Core Team (autonomous cron cycles)

| Role | Agent ID | Cycle | Purpose |
|------|----------|-------|---------|
| PM | pm | 20m | Owns milestones, tracks progress, unblocks agents |
| Reviewer | reviewer | 20m | Security review, steering feedback, quality gates |
| Engineer | main | 30m | Implements features, writes backend code |
| SRE | sre | 30m | Infrastructure, Docker, CI/CD, reliability |
| Designer | designer | 30m | Frontend UI, components, design system |

### Extended Team (on-demand via `ask`)

| Role | Agent ID | Purpose |
|------|----------|---------|
| UXR | uxr | User research, usability testing |
| Marketing | marketing | Go-to-market, positioning, content |

Extended team agents do not run on cron cycles. Query them directly:
```bash
openclaw-team ask uxr "What user research should we do before launch?"
openclaw-team ask marketing "Draft a launch announcement"
```

## Claude Code Delegation

Worker agents (Engineer, SRE, Designer) can delegate implementation to
Claude Code for actual file creation and editing:

```
Agent receives cron trigger
  -> reads steering feedback
  -> identifies task from milestone
  -> spawns Claude Code: bash pty:true workdir:[path] command:"claude '[task]'"
  -> Claude Code writes/edits files
  -> Agent updates GAP_ANALYSIS.md checkboxes
```

This two-level delegation (OpenClaw agent -> Claude Code) enables agents to
both reason about what to build and actually write code.

## Project Registry

`~/.openclaw/team.json` tracks all projects:

```json
{
  "activeProject": "my-app",
  "projects": {
    "my-app": {
      "path": "/home/user/Projects/my-app",
      "description": "My awesome application",
      "crons": {
        "pm": "uuid-1",
        "reviewer": "uuid-2",
        "engineer": "uuid-3",
        "sre": "uuid-4",
        "designer": "uuid-5"
      }
    }
  }
}
```

Cron IDs are stored so `pause`, `resume`, and `stop` can manage them without
searching. Multiple projects can exist simultaneously, but only one is active.

## Human Intervention Points

Users can steer the team at any time:

- **Edit REVIEWER_FEEDBACK.md**: Directly tell agents what to do next
- **Edit GAP_ANALYSIS.md**: Add or reprioritize items
- **Edit EXECUTION_PLAN.md**: Change milestones or assignments
- **`openclaw-team pause`**: Pause all agents
- **`openclaw-team ask <role> "message"`**: Direct query to any agent
- **`openclaw-team build <role> "task"`**: One-off coding task
