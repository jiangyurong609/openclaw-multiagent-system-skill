#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# openclaw-team -- Multi-Agent Development Team CLI
# ================================================================

TEAM_JSON="$HOME/.openclaw/team.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$HOME/.openclaw/workspace/skills/team-project"

show_help() {
    cat << 'HELP'
openclaw-team -- Multi-Agent Development Team for OpenClaw

Usage: openclaw-team <command> [options]

PROJECT COMMANDS:
  new <name> <path> "<desc>" [--to N]  Create project (--to: Telegram chat ID)
  list                                List all projects
  switch <name>                       Set active project
  status [name]                       Show project dashboard

TEAM COMMANDS:
  ask <role> "message"                Ask a specific team member
  standup [name]                      Run team standup
  review <file>                       Multi-agent code review
  build <role> "task"                 Delegate coding via Claude Code
  kickoff [name]                      Re-run kickoff meeting

LIFECYCLE COMMANDS:
  pause [name]                        Pause all project cron cycles
  resume [name]                       Resume paused cron cycles
  stop [name]                         Remove all cron cycles (keeps code)

ROLES:
  engineer | eng      Software development & coding
  pm | product        Product management & strategy
  reviewer | review   Code review & security
  designer | design   UI/UX design
  uxr                 User experience research
  marketing | mkt     Marketing & GTM
  sre | ops           Infrastructure & reliability

EXAMPLES:
  openclaw-team new my-saas ~/Projects/my-saas "B2B SaaS platform"
  openclaw-team ask pm "Create PRD for user onboarding"
  openclaw-team standup
  openclaw-team build engineer "Implement auth middleware"
  openclaw-team pause
HELP
}

resolve_agent() {
    case "$1" in
        engineer|eng)       echo "main" ;;
        pm|product)         echo "pm" ;;
        reviewer|review)    echo "reviewer" ;;
        designer|design)    echo "designer" ;;
        uxr)                echo "uxr" ;;
        marketing|mkt)      echo "marketing" ;;
        sre|ops)            echo "sre" ;;
        *) echo ""; return 1 ;;
    esac
}

get_active_project() {
    if [ -f "$TEAM_JSON" ]; then
        python3 -c "import json; print(json.load(open('$TEAM_JSON'))['activeProject'])" 2>/dev/null || true
    fi
}

get_project_path() {
    local name="${1:-$(get_active_project)}"
    if [ -f "$TEAM_JSON" ] && [ -n "$name" ]; then
        python3 -c "import json; print(json.load(open('$TEAM_JSON'))['projects']['$name']['path'])" 2>/dev/null || true
    fi
}

get_project_desc() {
    local name="${1:-$(get_active_project)}"
    if [ -f "$TEAM_JSON" ] && [ -n "$name" ]; then
        python3 -c "import json; print(json.load(open('$TEAM_JSON'))['projects']['$name'].get('description',''))" 2>/dev/null || true
    fi
}

# -- NEW PROJECT ---------------------------------------------------
cmd_new() {
    local name="$1" path="$2" desc="${3:-Software project}"

    if [ -z "$name" ] || [ -z "$path" ]; then
        echo "Usage: openclaw-team new <name> <path> \"<description>\""
        exit 1
    fi

    path=$(eval echo "$path")

    echo "Creating project: $name"
    echo "  Path: $path"
    echo "  Description: $desc"
    echo ""

    # Use bootstrap script
    local bootstrap="$SKILL_DIR/scripts/bootstrap.sh"
    if [ ! -f "$bootstrap" ]; then
        bootstrap="$SCRIPT_DIR/skill/scripts/bootstrap.sh"
    fi

    # Extract --to flag if present
    local telegram_to=""
    if [ "${5:-}" = "--to" ] && [ -n "${6:-}" ]; then
        telegram_to="$6"
    fi

    if [ -f "$bootstrap" ]; then
        bash "$bootstrap" "$name" "$path" "$desc" "$telegram_to"
    else
        echo "[ERROR] bootstrap.sh not found. Run setup.sh first."
        exit 1
    fi
}

# -- LIST -----------------------------------------------------------
cmd_list() {
    if [ ! -f "$TEAM_JSON" ]; then
        echo "No projects yet. Run: openclaw-team new <name> <path> \"<desc>\""
        return
    fi

    local active
    active=$(get_active_project)
    echo "Projects:"
    echo ""
    python3 -c "
import json
data = json.load(open('$TEAM_JSON'))
active = data.get('activeProject', '')
for name, info in data.get('projects', {}).items():
    marker = '> ' if name == active else '  '
    print(f'  {marker}{name} -> {info[\"path\"]}')
    print(f'     {info.get(\"description\", \"\")}')
"
}

# -- SWITCH ---------------------------------------------------------
cmd_switch() {
    local name="$1"
    python3 -c "
import json
with open('$TEAM_JSON') as f:
    data = json.load(f)
if '$name' not in data.get('projects', {}):
    print('[ERROR] Project not found: $name')
    exit(1)
data['activeProject'] = '$name'
with open('$TEAM_JSON', 'w') as f:
    json.dump(data, f, indent=2)
"
    echo "[OK] Active project: $name ($(get_project_path "$name"))"
}

# -- STATUS ---------------------------------------------------------
cmd_status() {
    local name="${1:-$(get_active_project)}"
    local path
    path=$(get_project_path "$name")

    if [ -z "$path" ]; then
        echo "[ERROR] No active project."
        exit 1
    fi

    local manage="$SKILL_DIR/scripts/manage.sh"
    if [ ! -f "$manage" ]; then
        manage="$SCRIPT_DIR/skill/scripts/manage.sh"
    fi

    if [ -f "$manage" ]; then
        bash "$manage" status "$name"
    else
        echo "Project: $name"
        echo "Path: $path"
        echo "Description: $(get_project_desc "$name")"
    fi
}

# -- ASK ------------------------------------------------------------
cmd_ask() {
    local role="$1" message="$2"
    local agent_id
    agent_id=$(resolve_agent "$role") || { echo "[ERROR] Unknown role: $role"; exit 1; }

    local name path desc context=""
    name=$(get_active_project)
    path=$(get_project_path)
    desc=$(get_project_desc)

    if [ -n "$name" ]; then
        context="[Project: $name | Path: $path | $desc] "
    fi

    openclaw agent --agent "$agent_id" -m "${context}${message}"
}

# -- BUILD ----------------------------------------------------------
cmd_build() {
    local role="$1" task="$2"
    local agent_id
    agent_id=$(resolve_agent "$role") || { echo "[ERROR] Unknown role: $role"; exit 1; }
    local path
    path=$(get_project_path)

    if [ -z "$path" ]; then
        echo "[ERROR] No active project."
        exit 1
    fi

    echo "Delegating to $role via Claude Code..."
    openclaw agent --agent "$agent_id" -m "Use Claude Code to implement this in $path:

$task

Run: bash pty:true workdir:$path command:\"claude '$task'\"

Report back what was implemented."
}

# -- STANDUP --------------------------------------------------------
cmd_standup() {
    local name="${1:-$(get_active_project)}"
    local manage="$SKILL_DIR/scripts/manage.sh"
    if [ ! -f "$manage" ]; then
        manage="$SCRIPT_DIR/skill/scripts/manage.sh"
    fi

    if [ -f "$manage" ]; then
        bash "$manage" standup "$name"
    else
        echo "[ERROR] manage.sh not found."
        exit 1
    fi
}

# -- REVIEW ---------------------------------------------------------
cmd_review() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "[ERROR] File not found: $file"
        exit 1
    fi

    local code
    code=$(cat "$file")

    echo "Code Reviewer analyzing..."
    openclaw agent --agent reviewer -m "Review this code for security, quality, and best practices:

File: $file

\`\`\`
$code
\`\`\`

Provide: security issues, performance concerns, best practices violations, actionable suggestions."

    echo ""
    echo "SRE checking reliability..."
    openclaw agent --agent sre -m "From a testing/reliability perspective, review:

File: $file

\`\`\`
$code
\`\`\`

What tests are needed? Deployment concerns?"
}

# -- KICKOFF --------------------------------------------------------
cmd_kickoff() {
    local name="${1:-$(get_active_project)}"
    local path desc
    path=$(get_project_path "$name")
    desc=$(get_project_desc "$name")

    if [ -z "$path" ]; then
        echo "[ERROR] No active project."
        exit 1
    fi

    echo "KICKOFF MEETING: $name"
    echo "========================================"
    echo ""

    local agents=(
        "pm:PM:Define product strategy, MVP scope, and phased roadmap"
        "main:Engineer:Design technical architecture, tech stack, and database schema"
        "sre:SRE:Plan infrastructure, CI/CD, security controls, and deployment"
        "designer:Designer:Design UI/UX, page layouts, component hierarchy"
        "reviewer:Reviewer:Analyze security requirements and code quality standards"
    )

    mkdir -p "$path/docs"

    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent_id agent_name agent_task <<< "$agent_info"
        echo "  $agent_name: Working..."
        (
            output=$(openclaw agent --agent "$agent_id" -m "PROJECT KICKOFF: $name
Description: $desc
Project path: $path

Your task: $agent_task

Provide comprehensive, actionable output. This is a real project -- be specific." 2>&1)
            echo "$output" > "$path/docs/${agent_name}_KICKOFF.md"
        ) &
    done

    wait
    echo ""
    echo "[OK] Kickoff complete. Docs in: $path/docs/"
}

# -- PAUSE / RESUME / STOP ------------------------------------------
cmd_lifecycle() {
    local action="$1"
    local name="${2:-$(get_active_project)}"
    local manage="$SKILL_DIR/scripts/manage.sh"
    if [ ! -f "$manage" ]; then
        manage="$SCRIPT_DIR/skill/scripts/manage.sh"
    fi

    if [ -f "$manage" ]; then
        bash "$manage" "$action" "$name"
    else
        echo "[ERROR] manage.sh not found."
        exit 1
    fi
}

# -- MAIN DISPATCHER -------------------------------------------------
case "${1:-help}" in
    new)        cmd_new "${2:-}" "${3:-}" "${4:-}" ;;
    list)       cmd_list ;;
    switch)     cmd_switch "${2:?Specify project name}" ;;
    status)     cmd_status "${2:-}" ;;
    ask)        cmd_ask "${2:?Specify role}" "${3:?Specify message}" ;;
    build)      cmd_build "${2:?Specify role}" "${3:?Specify task}" ;;
    standup)    cmd_standup "${2:-}" ;;
    review)     cmd_review "${2:?Specify file path}" ;;
    kickoff)    cmd_kickoff "${2:-}" ;;
    pause)      cmd_lifecycle "pause" "${2:-}" ;;
    resume)     cmd_lifecycle "resume" "${2:-}" ;;
    stop)       cmd_lifecycle "stop" "${2:-}" ;;
    help|--help|-h) show_help ;;
    *)          echo "Unknown command: $1"; show_help; exit 1 ;;
esac
