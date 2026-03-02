#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# openclaw-team setup
# Installs the multi-agent team system into your OpenClaw instance
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
FORCE="${1:-}"

echo "=== openclaw-team Setup ==="
echo ""

# -- Phase 1: Prerequisites ----------------------------------------
echo "[1/6] Checking prerequisites..."

check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  [OK] $1"
        return 0
    else
        echo "  [MISSING] $1 -- $2"
        return 1
    fi
}

MISSING=0
check_cmd "openclaw" "Install from https://openclaw.com" || MISSING=1
check_cmd "python3"  "Install Python 3.8+" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "[ERROR] Missing prerequisites. Install them and re-run setup.sh"
    exit 1
fi

# Verify openclaw agent system works
if ! openclaw agents list &>/dev/null; then
    echo "  [ERROR] openclaw agents list failed. Run 'openclaw configure' first."
    exit 1
fi
echo "  [OK] openclaw agent system"

# -- Phase 2: Create agents ----------------------------------------
echo ""
echo "[2/6] Setting up agents..."

declare -A AGENT_MAP=(
    ["engineer"]="main"
    ["pm"]="pm"
    ["reviewer"]="reviewer"
    ["designer"]="designer"
    ["sre"]="sre"
    ["uxr"]="uxr"
    ["marketing"]="marketing"
)

EXISTING_AGENTS=$(openclaw agents list 2>/dev/null || true)

for role in pm reviewer designer sre uxr marketing; do
    agent_id="${AGENT_MAP[$role]}"
    if echo "$EXISTING_AGENTS" | grep -q "^- $agent_id"; then
        echo "  [OK] $role ($agent_id) -- exists"
    else
        echo "  [+] Creating $role ($agent_id)..."
        openclaw agents add "$agent_id" --non-interactive 2>/dev/null || {
            echo "  [WARN] Could not create agent '$agent_id'. Create manually: openclaw agents add $agent_id"
        }
    fi
done

# Engineer uses "main" which always exists
echo "  [OK] engineer (main) -- default agent"

# -- Phase 3: Install identities ------------------------------------
echo ""
echo "[3/6] Installing agent identities..."

SOUL_SRC="$SCRIPT_DIR/agents/SOUL.md"

for role in "${!AGENT_MAP[@]}"; do
    agent_id="${AGENT_MAP[$role]}"
    identity_src="$SCRIPT_DIR/agents/$role/IDENTITY.md"

    # Find agent workspace
    workspace="$OPENCLAW_DIR/agents/$agent_id/workspace"
    if [ "$agent_id" = "main" ]; then
        workspace="$OPENCLAW_DIR/workspace"
    fi

    if [ ! -d "$workspace" ]; then
        echo "  [SKIP] $role -- workspace not found at $workspace"
        continue
    fi

    # Install IDENTITY.md
    if [ -f "$identity_src" ]; then
        if [ ! -f "$workspace/IDENTITY.md" ] || [ "$FORCE" = "--force" ]; then
            cp "$identity_src" "$workspace/IDENTITY.md"
            echo "  [OK] $role IDENTITY.md installed"
        else
            echo "  [OK] $role IDENTITY.md exists (use --force to overwrite)"
        fi
    fi

    # Install shared SOUL.md
    if [ -f "$SOUL_SRC" ]; then
        if [ ! -f "$workspace/SOUL.md" ] || [ "$FORCE" = "--force" ]; then
            cp "$SOUL_SRC" "$workspace/SOUL.md"
        fi
    fi
done

# -- Phase 4: Install skill ----------------------------------------
echo ""
echo "[4/6] Installing team-project skill..."

SKILL_DEST="$OPENCLAW_DIR/workspace/skills/team-project"
mkdir -p "$SKILL_DEST/scripts"

cp "$SCRIPT_DIR/skill/SKILL.md" "$SKILL_DEST/SKILL.md"
cp "$SCRIPT_DIR/skill/scripts/bootstrap.sh" "$SKILL_DEST/scripts/bootstrap.sh"
cp "$SCRIPT_DIR/skill/scripts/manage.sh" "$SKILL_DEST/scripts/manage.sh"
chmod +x "$SKILL_DEST/scripts/"*.sh

# Also copy templates alongside the skill for bootstrap.sh to find
if [ -d "$SCRIPT_DIR/templates" ]; then
    mkdir -p "$SKILL_DEST/templates"
    cp "$SCRIPT_DIR/templates/"*.md "$SKILL_DEST/templates/" 2>/dev/null || true
fi

echo "  [OK] Skill installed to $SKILL_DEST"

# Verify skill is recognized
if openclaw skills list 2>/dev/null | grep -q "team-project"; then
    echo "  [OK] Skill recognized by OpenClaw"
else
    echo "  [WARN] Skill not showing in 'openclaw skills list' -- may need gateway restart"
fi

# -- Phase 5: Install CLI ------------------------------------------
echo ""
echo "[5/6] Installing CLI..."

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/openclaw-team.sh" "$INSTALL_DIR/openclaw-team"
chmod +x "$INSTALL_DIR/openclaw-team"

if echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo "  [OK] openclaw-team installed to $INSTALL_DIR (in PATH)"
else
    echo "  [OK] openclaw-team installed to $INSTALL_DIR"
    echo "  [NOTE] Add to PATH: export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# -- Phase 6: Initialize team.json ---------------------------------
echo ""
echo "[6/6] Initializing project registry..."

TEAM_JSON="$OPENCLAW_DIR/team.json"
if [ ! -f "$TEAM_JSON" ]; then
    echo '{"activeProject":"","projects":{}}' > "$TEAM_JSON"
    echo "  [OK] Created $TEAM_JSON"
else
    echo "  [OK] $TEAM_JSON exists"
fi

# -- Done -----------------------------------------------------------
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your multi-agent team is ready:"
echo ""
openclaw agents list 2>/dev/null | grep "^-" | head -10
echo ""
echo "Quick start:"
echo "  openclaw-team new my-app ~/Projects/my-app \"My awesome project\""
echo "  openclaw-team status"
echo "  openclaw-team ask pm \"What should we build first?\""
echo ""
echo "For more: openclaw-team --help"
