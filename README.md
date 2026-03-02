# openclaw-team

A multi-agent AI development team that builds software autonomously. Seven specialized agents (PM, Engineer, Reviewer, Designer, SRE, UXR, Marketing) coordinate via shared markdown documents and cron-based work cycles on [OpenClaw](https://openclaw.com).

```
         +-----------+     +-----------+
         |    PM     |     | Reviewer  |
         | (20 min)  |     | (20 min)  |
         +-----+-----+     +-----+-----+
               |                  |
     writes    |                  |  writes
               v                  v
      EXECUTION_PLAN.md   REVIEWER_FEEDBACK.md
               |                  |
               +------+   +------+
                      |   |
            reads     v   v     reads
              +-------------------+
              | Engineer  SRE     |
              | Designer (30 min) |
              +--------+----------+
                       |
             updates   v
               GAP_ANALYSIS.md
```

Agents coordinate through three markdown files. No message queues, no databases -- just files on disk.

## How It Works

1. **You describe what to build** -- `openclaw-team new my-app ~/Projects/my-app "B2B SaaS platform"`
2. **PM creates the plan** -- milestones, acceptance criteria, agent assignments
3. **Reviewer steers the team** -- writes DO NOW / DO NOT instructions per agent each cycle
4. **Workers implement** -- read feedback first, then code using Claude Code, update the checklist
5. **You intervene anytime** -- edit the markdown files directly, pause agents, ask questions

## Prerequisites

- [OpenClaw](https://openclaw.com) installed and configured (`openclaw configure`)
- Python 3.8+
- Bash 4+
- An AI model provider configured in OpenClaw (API credits required)

## Quickstart

```bash
git clone https://github.com/user/openclaw-team.git
cd openclaw-team
./setup.sh
```

This will:
- Create 7 specialized agents in your OpenClaw instance
- Install agent identities (IDENTITY.md + SOUL.md)
- Install the `team-project` skill
- Add `openclaw-team` CLI to `~/.local/bin/`

Then start a project:

```bash
openclaw-team new my-app ~/Projects/my-app "My awesome application"
```

The team begins working autonomously. Check progress:

```bash
openclaw-team status
```

## Team Roles

| Role | Agent | Cycle | What They Do |
|------|-------|-------|-------------|
| PM | `pm` | 45 min | Owns milestones, tracks progress, unblocks agents |
| Reviewer | `reviewer` | 45 min | Security review, quality gates, steers workers |
| Engineer | `main` | 60 min | Backend code, APIs, business logic |
| SRE | `sre` | 60 min | Infrastructure, Docker, CI/CD, reliability |
| Designer | `designer` | 60 min | Frontend UI, components, design system |
| UXR | `uxr` | on-demand | User research, usability testing |
| Marketing | `marketing` | on-demand | Go-to-market, positioning, content |

## Command Reference

### Project Lifecycle

```bash
openclaw-team new <name> <path> "<description>"   # Create project, start agents
openclaw-team list                                  # List all projects
openclaw-team switch <name>                         # Set active project
openclaw-team status                                # Project dashboard
openclaw-team pause                                 # Pause all agent cycles
openclaw-team resume                                # Resume paused cycles
openclaw-team stop                                  # Remove all cron cycles
```

### Team Interaction

```bash
openclaw-team ask <role> "message"                  # Ask a team member
openclaw-team build <role> "task"                    # Delegate coding task
openclaw-team standup                                # Run team standup
openclaw-team kickoff                                # Re-run kickoff meeting
openclaw-team review <file>                          # Multi-agent code review
```

### Examples

```bash
# Ask the PM for a status update
openclaw-team ask pm "What milestone are we on?"

# Have the engineer implement a feature
openclaw-team build engineer "Add user authentication with JWT"

# Get a security + reliability review of a file
openclaw-team review src/auth.py

# Pause when you're done for the day
openclaw-team pause
```

## The Three Documents

All coordination happens through three markdown files in your project directory:

### EXECUTION_PLAN.md (PM owns)
Sequential milestones with acceptance criteria and agent assignments. The PM updates this every cycle based on code changes.

### REVIEWER_FEEDBACK.md (Reviewer owns)
Per-agent steering instructions. Workers read this **first** every cycle:

```markdown
## Engineer
**DO NOW:** Implement the auth middleware in auth.py
**DO NOT:** Skip to the billing module -- auth must work first
```

### GAP_ANALYSIS.md (shared)
Prioritized checklist (P0 > P1 > P2). Agents check items off as they complete them:

```markdown
- [x] Firebase Auth integration
- [x] Protected routes
- [ ] Rate limiting per user
```

## Human Intervention

You can steer the team at any time:

- **Edit REVIEWER_FEEDBACK.md** to tell agents what to focus on next
- **Edit GAP_ANALYSIS.md** to add or reprioritize work items
- **Edit EXECUTION_PLAN.md** to change milestones or assignments
- **`openclaw-team pause`** to stop all agents temporarily
- **`openclaw-team ask <role> "message"`** to query any agent directly

## Project Structure

```
openclaw-team/
├── README.md
├── LICENSE
├── setup.sh                    # One-command installer
├── openclaw-team.sh            # Unified CLI
├── skill/                      # OpenClaw skill package
│   ├── SKILL.md
│   └── scripts/
│       ├── bootstrap.sh        # Project bootstrapping
│       └── manage.sh           # Project management
├── agents/                     # Agent identity templates
│   ├── SOUL.md                 # Shared philosophy (all agents)
│   ├── engineer/IDENTITY.md
│   ├── pm/IDENTITY.md
│   ├── reviewer/IDENTITY.md
│   ├── designer/IDENTITY.md
│   ├── sre/IDENTITY.md
│   ├── uxr/IDENTITY.md
│   └── marketing/IDENTITY.md
├── templates/                  # Coordination doc templates
│   ├── GAP_ANALYSIS.md
│   ├── EXECUTION_PLAN.md
│   └── REVIEWER_FEEDBACK.md
├── docs/
│   ├── ARCHITECTURE.md         # System design deep-dive
│   ├── CUSTOMIZATION.md        # Tuning agents and cycles
│   └── TROUBLESHOOTING.md      # Common issues
└── examples/
    └── skill-marketplace/      # Real worked example
```

## Cost Awareness

Each agent cycle makes API calls to your configured model provider. With default settings (5 agents, cycles every 20-30 minutes), expect moderate API usage. To reduce costs:

- **Increase intervals**: Edit cron timing in `skill/scripts/bootstrap.sh`
- **Pause when idle**: `openclaw-team pause` stops all cycles
- **Use cheaper models**: Configure PM with a lighter model via `openclaw cron edit`
- **Fewer agents**: Comment out roles you don't need in bootstrap.sh

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for details.

## Telegram Notifications

Get agent updates in Telegram. Pass your chat ID when creating a project:

```bash
openclaw-team new my-app ~/Projects/my-app "My app" --to 123456789
```

Or configure existing crons:

```bash
openclaw cron edit <id> --announce --channel telegram --to <chat-id> --best-effort-deliver
```

## Model Providers

The system supports multiple model providers with automatic failover:

```bash
openclaw models set openai-codex/gpt-5.3-codex              # primary
openclaw models fallbacks add google/gemini-3-flash-preview  # fallback
openclaw models fallbacks add anthropic/claude-sonnet-4-6    # last resort
```

For Claude.ai auth, you can use [ACP integration](docs/ARCHITECTURE.md#acp-integration)
to route through Claude Code (handles its own OAuth refresh).

## Documentation

- [Architecture](docs/ARCHITECTURE.md) -- system design, model fallbacks, ACP integration, Telegram setup
- [Customization](docs/CUSTOMIZATION.md) -- adding roles, tuning cycles, model selection
- [Troubleshooting](docs/TROUBLESHOOTING.md) -- auth errors, rate limits, delivery failures, cost optimization
- [Example: Skill Marketplace](examples/skill-marketplace/) -- real project with 80+ gap items and 5 milestones

## License

MIT
