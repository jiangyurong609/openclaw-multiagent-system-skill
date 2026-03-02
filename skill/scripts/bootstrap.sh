#!/usr/bin/env bash
set -euo pipefail

# Team Project Bootstrap
# Usage: bootstrap.sh <project-name> <project-path> [description]
#
# Sets up the full multi-agent coordination system:
# 1. Verifies agents exist
# 2. Creates project tracking documents
# 3. Sets up 5 autonomous cron work cycles
# 4. Registers project in team.json
# 5. Triggers PM kickoff

PROJECT_NAME="${1:?Usage: bootstrap.sh <project-name> <project-path> [description]}"
PROJECT_PATH="${2:?Provide project path}"
DESCRIPTION="${3:-Software project}"
TEAM_JSON="$HOME/.openclaw/team.json"
TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)/../templates"

# Fall back to installed templates location
if [ ! -d "$TEMPLATE_DIR" ]; then
    TEMPLATE_DIR="$HOME/.openclaw/workspace/skills/team-project/templates"
fi

echo "=== Team Project Bootstrap ==="
echo "Project: $PROJECT_NAME"
echo "Path:    $PROJECT_PATH"
echo ""

# -- 1. Verify agents ------------------------------------------------
echo "[1/5] Checking agents..."
REQUIRED_AGENTS=("main" "pm" "reviewer" "sre" "designer")
MISSING=0
for agent in "${REQUIRED_AGENTS[@]}"; do
    if openclaw agents list 2>/dev/null | grep -q "^- $agent"; then
        echo "  [OK] $agent"
    else
        echo "  [WARN] Agent '$agent' not found. Create with: openclaw agents add $agent"
        MISSING=$((MISSING + 1))
    fi
done
if [ "$MISSING" -gt 0 ]; then
    echo ""
    echo "  $MISSING agent(s) missing. Run setup.sh first or create them manually."
    echo "  Continuing anyway -- cron jobs for missing agents will fail."
fi

# -- 2. Create project structure -------------------------------------
echo ""
echo "[2/5] Creating project structure..."
mkdir -p "$PROJECT_PATH"

# Copy or create coordination documents
for doc in GAP_ANALYSIS.md EXECUTION_PLAN.md REVIEWER_FEEDBACK.md; do
    if [ ! -f "$PROJECT_PATH/$doc" ]; then
        if [ -f "$TEMPLATE_DIR/$doc" ]; then
            cp "$TEMPLATE_DIR/$doc" "$PROJECT_PATH/$doc"
        else
            touch "$PROJECT_PATH/$doc"
        fi
        echo "  [OK] $doc (created)"
    else
        echo "  [OK] $doc (exists)"
    fi
done

# -- 3. Set up cron work cycles -------------------------------------
echo ""
echo "[3/5] Setting up autonomous work cycles..."

create_cron() {
    local name="$1" agent="$2" interval="$3" timeout="$4" thinking="$5" message="$6"
    local cron_id
    cron_id=$(openclaw cron add \
        --name "${PROJECT_NAME}-${name}" \
        --agent "$agent" \
        --every "$interval" \
        --timeout-seconds "$timeout" \
        --session isolated \
        --thinking "$thinking" \
        --json \
        --message "$message" \
        2>&1 | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "FAILED")
    echo "$cron_id"
}

PM_ID=$(create_cron "pm" "pm" "20m" "300" "medium" \
"You are the PM. You OWN the execution plan. Every cycle:
1. READ ${PROJECT_PATH}/EXECUTION_PLAN.md
2. READ ${PROJECT_PATH}/GAP_ANALYSIS.md
3. CHECK code changes: find ${PROJECT_PATH} -name '*.py' -o -name '*.ts' -o -name '*.tsx' | xargs ls -lt 2>/dev/null | head -20
4. UPDATE EXECUTION_PLAN.md: mark acceptance criteria, update agent status, add progress log entry
5. FLAG blockers if agents are stuck or working on wrong milestone
Keep the team on track. Milestones must complete in order unless marked parallel.")
echo "  [OK] PM cycle (20m): $PM_ID"

REV_ID=$(create_cron "reviewer" "reviewer" "20m" "300" "high" \
"You are the CODE REVIEWER and TEAM LEAD. Every cycle:
1. READ ${PROJECT_PATH}/EXECUTION_PLAN.md for current milestones
2. CHECK recent code in ${PROJECT_PATH}
3. REVIEW: security, correctness vs milestone acceptance criteria, architecture
4. WRITE steering instructions to ${PROJECT_PATH}/REVIEWER_FEEDBACK.md -- one section per agent with DO NOW and DO NOT
5. FLAG if any agent is working on the wrong milestone or producing insecure code
Your feedback file is what workers read first. Be specific and actionable.")
echo "  [OK] Reviewer cycle (20m): $REV_ID"

ENG_ID=$(create_cron "engineer" "main" "30m" "900" "high" \
"You are the LEAD ENGINEER. Every cycle:
1. FIRST read ${PROJECT_PATH}/REVIEWER_FEEDBACK.md for steering instructions. Follow them.
2. Read ${PROJECT_PATH}/EXECUTION_PLAN.md for your current milestone.
3. Read ${PROJECT_PATH}/GAP_ANALYSIS.md for the checklist.
4. Implement your assigned task using Claude Code: bash pty:true workdir:${PROJECT_PATH} command:\"claude 'implement [your task]'\"
5. After implementing, update GAP_ANALYSIS.md to check off completed items [x].
Stay on your assigned milestone. Do not skip ahead.")
echo "  [OK] Engineer cycle (30m): $ENG_ID"

SRE_ID=$(create_cron "sre" "sre" "30m" "900" "high" \
"You are the SRE. Every cycle:
1. FIRST read ${PROJECT_PATH}/REVIEWER_FEEDBACK.md for steering instructions. Follow them.
2. Read ${PROJECT_PATH}/EXECUTION_PLAN.md for your current milestone.
3. Read ${PROJECT_PATH}/GAP_ANALYSIS.md for the checklist.
4. Implement your assigned task using Claude Code: bash pty:true workdir:${PROJECT_PATH} command:\"claude 'implement [your task]'\"
5. After implementing, update GAP_ANALYSIS.md to check off completed items [x].
Focus on infrastructure, sandbox, Docker, deployment, resource limits.")
echo "  [OK] SRE cycle (30m): $SRE_ID"

DES_ID=$(create_cron "designer" "designer" "30m" "900" "high" \
"You are the DESIGNER. Every cycle:
1. FIRST read ${PROJECT_PATH}/REVIEWER_FEEDBACK.md for steering instructions. Follow them.
2. Read ${PROJECT_PATH}/EXECUTION_PLAN.md for your current milestone.
3. Read ${PROJECT_PATH}/GAP_ANALYSIS.md for the checklist.
4. Implement your assigned task using Claude Code: bash pty:true workdir:${PROJECT_PATH} command:\"claude 'implement [your task]'\"
5. After implementing, update GAP_ANALYSIS.md to check off completed items [x].
Focus on frontend UI, React components, design system, user experience.")
echo "  [OK] Designer cycle (30m): $DES_ID"

# -- 4. Register project ---------------------------------------------
echo ""
echo "[4/5] Registering project..."

if [ ! -f "$TEAM_JSON" ]; then
    echo '{"activeProject":"","projects":{}}' > "$TEAM_JSON"
fi

python3 -c "
import json
with open('$TEAM_JSON') as f:
    data = json.load(f)
data['activeProject'] = '$PROJECT_NAME'
data['projects']['$PROJECT_NAME'] = {
    'path': '$PROJECT_PATH',
    'description': '$DESCRIPTION',
    'crons': {
        'pm': '$PM_ID',
        'reviewer': '$REV_ID',
        'engineer': '$ENG_ID',
        'sre': '$SRE_ID',
        'designer': '$DES_ID'
    }
}
with open('$TEAM_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"
echo "  [OK] Registered in $TEAM_JSON"

# -- 5. Trigger PM kickoff -------------------------------------------
echo ""
echo "[5/5] Triggering PM kickoff..."
openclaw agent --agent pm \
    -m "PROJECT KICKOFF: You are PM for '$PROJECT_NAME' at $PROJECT_PATH.
Description: $DESCRIPTION

Read any existing code in $PROJECT_PATH, then:
1. Fill in GAP_ANALYSIS.md with actual project state (what exists vs what's missing)
2. Define milestones in EXECUTION_PLAN.md with acceptance criteria and agent assignments
3. Write initial steering in REVIEWER_FEEDBACK.md telling each agent what to start on

This is the foundation -- all agents will follow your plan. Be thorough." \
    --timeout 300 \
    2>&1 | tail -5 || echo "  (PM kickoff dispatched -- will complete async)"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Project '$PROJECT_NAME' is running with 5 autonomous agents."
echo "Cycles: PM(20m) Reviewer(20m) Engineer(30m) SRE(30m) Designer(30m)"
echo ""
echo "Next steps:"
echo "  Status:  openclaw-team status"
echo "  Standup: openclaw-team standup"
echo "  Pause:   openclaw-team pause"
echo "  Stop:    openclaw-team stop"
