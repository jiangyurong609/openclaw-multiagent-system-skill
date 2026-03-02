# Customization Guide

## Customizing Agent Identities

Each agent's personality is defined in `IDENTITY.md`. Edit these before
running `setup.sh` or directly in `~/.openclaw/agents/<id>/workspace/IDENTITY.md`.

### Changing Names

Replace the generic names with your team's personality:

```markdown
- **Name:** CodeBot     # was: Engineer
- **Vibe:** Caffeinated hacker energy. Ships at 3am.
```

### Adding Specializations

Add domain-specific competencies:

```markdown
### Core Competencies
- Machine Learning Pipelines    # domain-specific
- FastAPI & SQLAlchemy           # stack-specific
- Kubernetes Operations          # infra-specific
```

### Changing the SOUL

`agents/SOUL.md` is shared across all agents. Edit it to change the
fundamental personality traits of your entire team.

## Adding New Agent Roles

### 1. Create the agent in OpenClaw

```bash
openclaw agents add data-engineer --non-interactive
```

### 2. Create identity files

```bash
mkdir -p agents/data-engineer
cat > agents/data-engineer/IDENTITY.md << 'EOF'
# IDENTITY.md - Who Am I?

- **Name:** Data Engineer
- **Role:** Data Pipeline Specialist
- **Vibe:** ETL wizard. Data in, insights out.
- **Emoji:** 📊

## My Specialization
...
EOF
```

### 3. Add to the role resolver

In `openclaw-team.sh`, add to the `resolve_agent()` function:

```bash
data|data-eng)  echo "data-engineer" ;;
```

### 4. Add a cron cycle (optional)

In `skill/scripts/bootstrap.sh`, add another `create_cron` call:

```bash
DE_ID=$(create_cron "data-engineer" "data-engineer" "30m" "900" "high" \
"You are the DATA ENGINEER. Every cycle: ...")
```

## Tuning Cron Intervals

Default intervals (configurable via `--pm-interval` and `--worker-interval`):
- **PM**: 45 minutes (reads code, updates plan, force-advances stale gates)
- **Reviewer**: 45 minutes (reviews code, steers agents, approves milestones)
- **Workers**: 1 hour (reads feedback, implements, updates gap)

### For faster iteration
Reduce intervals (costs more API credits):
```bash
openclaw cron edit <id> --every 10m
```

### For cost savings
Increase intervals:
```bash
openclaw cron edit <id> --every 1h
```

### Thinking levels
- `off` / `minimal`: Fastest, cheapest. Good for simple status checks.
- `low` / `medium`: Balanced. Default for PM.
- `high`: Most thorough. Default for workers and reviewer.

```bash
openclaw cron edit <id> --thinking medium
```

## Running Multiple Projects

```bash
# Create projects
openclaw-team new frontend ~/Projects/frontend "React dashboard"
openclaw-team new backend ~/Projects/backend "API server"

# Switch between them
openclaw-team switch frontend
openclaw-team status

openclaw-team switch backend
openclaw-team standup

# Pause one, keep the other running
openclaw-team pause frontend
```

Each project gets its own set of cron jobs. They run independently.

## Changing the Model

Agents can use different models. Set per-agent:

```bash
openclaw agents list  # see current models
```

Or override per-cron:

```bash
openclaw cron edit <id> --model anthropic/claude-sonnet-4-6
```

Recommended:
- **PM/Reviewer**: Sonnet (good reasoning, lower cost)
- **Engineer/SRE/Designer**: Sonnet or Opus (best coding)
