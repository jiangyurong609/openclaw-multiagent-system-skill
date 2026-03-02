#!/usr/bin/env bash
set -euo pipefail

# Team Project Manager
# Usage: manage.sh <command> [project-name]
# Commands: status, pause, resume, stop, standup, kickoff

TEAM_JSON="$HOME/.openclaw/team.json"
CMD="${1:?Usage: manage.sh <status|pause|resume|stop|standup|kickoff> [project-name]}"
PROJECT_NAME="${2:-}"

# Resolve active project if not specified
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['activeProject'])" 2>/dev/null || true)
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "[ERROR] No active project. Specify project name or run bootstrap.sh first."
    exit 1
fi

# Load project config
PROJECT_PATH=$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['projects']['$PROJECT_NAME']['path'])" 2>/dev/null || true)
if [ -z "$PROJECT_PATH" ]; then
    echo "[ERROR] Project '$PROJECT_NAME' not found in $TEAM_JSON"
    exit 1
fi

get_cron_ids() {
    python3 -c "
import json
p = json.load(open('$TEAM_JSON'))['projects']['$PROJECT_NAME']
crons = p.get('crons', {})
for role, cid in crons.items():
    print(f'{role}={cid}')
" 2>/dev/null || true
}

case "$CMD" in
    status)
        echo "=== Project: $PROJECT_NAME ==="
        echo "Path: $PROJECT_PATH"
        echo ""

        echo "--- Cron Status ---"
        openclaw cron list 2>&1 | grep -E "$PROJECT_NAME|Status|ID" || echo "No crons found"
        echo ""

        echo "--- Milestone Progress ---"
        if [ -f "$PROJECT_PATH/EXECUTION_PLAN.md" ]; then
            grep -E "^\*\*Status:\*\*|^## Milestone|^\- \[" "$PROJECT_PATH/EXECUTION_PLAN.md" 2>/dev/null | head -30
        else
            echo "No execution plan found"
        fi
        echo ""

        echo "--- Gap Completion ---"
        if [ -f "$PROJECT_PATH/GAP_ANALYSIS.md" ]; then
            TOTAL=$(grep -c '^\- \[' "$PROJECT_PATH/GAP_ANALYSIS.md" 2>/dev/null || echo 0)
            DONE=$(grep -c '^\- \[x\]' "$PROJECT_PATH/GAP_ANALYSIS.md" 2>/dev/null || echo 0)
            echo "  $DONE / $TOTAL items complete"
        else
            echo "No gap analysis found"
        fi
        ;;

    pause)
        echo "Pausing project $PROJECT_NAME..."
        for line in $(get_cron_ids); do
            role="${line%%=*}"
            cid="${line#*=}"
            openclaw cron disable "$cid" 2>/dev/null && echo "  [OK] Paused $role" || echo "  [WARN] Failed $role ($cid)"
        done
        echo "Done. Resume with: manage.sh resume $PROJECT_NAME"
        ;;

    resume)
        echo "Resuming project $PROJECT_NAME..."
        for line in $(get_cron_ids); do
            role="${line%%=*}"
            cid="${line#*=}"
            openclaw cron enable "$cid" 2>/dev/null && echo "  [OK] Resumed $role" || echo "  [WARN] Failed $role ($cid)"
        done
        echo "Done. Agents will resume on next cycle."
        ;;

    stop)
        echo "Stopping project $PROJECT_NAME (removing crons)..."
        for line in $(get_cron_ids); do
            role="${line%%=*}"
            cid="${line#*=}"
            openclaw cron rm "$cid" 2>/dev/null && echo "  [OK] Removed $role" || echo "  [WARN] Failed $role ($cid)"
        done
        echo "Done. Code remains at $PROJECT_PATH."
        ;;

    standup)
        echo "=== Team Standup: $PROJECT_NAME ==="
        echo ""
        echo "--- PM Report ---"
        openclaw agent --agent pm \
            -m "Quick standup for $PROJECT_NAME: read $PROJECT_PATH/EXECUTION_PLAN.md and report in 5 bullet points: which milestones done, which in progress, any blockers" \
            --timeout 120 2>&1 | tail -20
        echo ""
        echo "--- Reviewer Report ---"
        openclaw agent --agent reviewer \
            -m "Quick review for $PROJECT_NAME: check $PROJECT_PATH for recent code changes, report in 3 bullet points: security issues, off-track agents, quality concerns" \
            --timeout 120 2>&1 | tail -20
        ;;

    kickoff)
        echo "=== Kickoff: $PROJECT_NAME ==="
        DESC=$(python3 -c "import json; print(json.load(open('$TEAM_JSON'))['projects']['$PROJECT_NAME'].get('description',''))" 2>/dev/null || true)
        openclaw agent --agent pm \
            -m "PROJECT KICKOFF for $PROJECT_NAME at $PROJECT_PATH ($DESC). Read all existing code, then fill in GAP_ANALYSIS.md, EXECUTION_PLAN.md with milestones, and REVIEWER_FEEDBACK.md with initial steering." \
            --timeout 300 2>&1
        ;;

    *)
        echo "Unknown command: $CMD"
        echo "Usage: manage.sh <status|pause|resume|stop|standup|kickoff> [project-name]"
        exit 1
        ;;
esac
