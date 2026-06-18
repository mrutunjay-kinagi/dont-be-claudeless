#!/bin/bash
set -e

echo "🤖 Installing dont-be-claudeless context guard..."

# 1. Setup local scripts directory
TARGET_DIR="$HOME/.claude/scripts"
mkdir -p "$TARGET_DIR"

# 2. Download the status-line script from your repo
REPO_URL="https://raw.githubusercontent.com/mrutunjay-kinagi/dont-be-claudeless/main/scripts/status-line.sh"

echo "📥 Fetching status-line script..."
curl -s -L "$REPO_URL" -o "$TARGET_DIR/status-line.sh"

# 3. Apply operational permissions
chmod +x "$TARGET_DIR/status-line.sh"

# 4. Check/Inject configurations into global settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

if [ ! -f "$SETTINGS_FILE" ] || [ ! -s "$SETTINGS_FILE" ]; then
    echo '{"statusLine": {"type": "command", "command": "~/.claude/scripts/status-line.sh"}}' > "$SETTINGS_FILE"
else
    # Simple injection check using jq if available, otherwise prompt manual update
    if command -v jq &> /dev/null; then
        TMP_JSON=$(mktemp)
        jq '.statusLine = {"type": "command", "command": "~/.claude/scripts/status-line.sh"}' "$SETTINGS_FILE" > "$TMP_JSON"
        mv "$TMP_JSON" "$SETTINGS_FILE"
    else
        echo "⚠️ Note: Please manually add the statusLine block to your $SETTINGS_FILE file."
    fi
fi

echo "✅ Success! Fire up 'claude' to experience the Smart Zone framework!"
