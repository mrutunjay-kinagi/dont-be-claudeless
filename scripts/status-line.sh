#!/bin/bash
# Claude Code – Monochrome Dark Status Line
# Save to: ~/.claude/scripts/status-line.sh
# chmod +x ~/.claude/scripts/status-line.sh

# 1. Read full JSON from stdin
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# 2. Parse telemetry fields with guaranteed fallbacks
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "AI"' | tr '[:lower:]' '[:upper:]')
PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOKENS_USED=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
LIMIT_5H=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty')
DIR=$(basename "$(echo "$INPUT" | jq -r '.workspace.current_dir // "."')")

# Ensure variables are integers
PCT_INT=${PCT:-0}
[[ ! "$PCT_INT" =~ ^[0-9]+$ ]] && PCT_INT=0
TOKENS_INT=${TOKENS_USED:-0}
[[ ! "$TOKENS_INT" =~ ^[0-9]+$ ]] && TOKENS_INT=0

# 3. Fast native Bash token formatting (e.g., 42500 -> 42.5k)
if [ "$TOKENS_INT" -ge 1000 ]; then
    INTEGRAL=$(( TOKENS_INT / 1000 ))
    FRACTION=$(( (TOKENS_INT % 1000) / 100 ))
    if [ "$FRACTION" -eq 0 ]; then
        TOKENS_K="${INTEGRAL}k"
    else
        TOKENS_K="${INTEGRAL}.${FRACTION}k"
    fi
else
    TOKENS_K="${TOKENS_INT}"
fi

# 4. Format cost safely
COST_FMT=$(printf '%.2f' "$COST" 2>/dev/null || echo "0.00")

# 5. Build 10-step context bar
FILLED=$(( PCT_INT / 10 ))
[ "$FILLED" -gt 10 ] && FILLED=10
EMPTY=$(( 10 - FILLED ))
[ "$EMPTY" -lt 0 ] && EMPTY=0

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

# 6. ANSI colors
TEXT="\033[38;5;250m"
MUTED="\033[38;5;241m"
ALERT="\033[7;38;5;250m"
RESET="\033[0m"

# 7. SMART / DUMB window toggle
if [ "$PCT_INT" -lt 50 ]; then
    ZONE="${MUTED}[${TEXT}SMART${MUTED}]${RESET}"
else
    ZONE="${ALERT}[!! DUMB !!]${RESET}"
fi

# 8. Rate limit segment
RATE_SEG=""
if [ -n "$LIMIT_5H" ]; then
    LIMIT_INT=$(printf '%.0f' "$LIMIT_5H" 2>/dev/null || echo "0")
    RATE_SEG=" ${MUTED}[${TEXT}RATE: ${LIMIT_INT}%${MUTED}]${RESET}"
fi

# 9. Render
echo -e "${MUTED}[${TEXT}${MODEL} | ${DIR}${MUTED}]${RESET} ${MUTED}[${TEXT}CTX: ${BAR} ${TOKENS_K}${MUTED}]${RESET} ${MUTED}[${TEXT}\$${COST_FMT}${MUTED}]${RESET}${RATE_SEG} ${ZONE}"
