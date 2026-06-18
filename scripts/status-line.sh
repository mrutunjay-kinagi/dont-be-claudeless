#!/bin/bash
# 🤖 dont-be-claudeless — Status Line Telemetry Engine
# Enforces Matt Pocock's "Task, Don't Chat" Context Firewall

# 1. Read full multi-line JSON stream from Claude Code stdin
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# 2. Extract telemetry fields using jq with safety fallbacks
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "AI"' | tr '[:lower:]' '[:upper:]')
PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOKENS_USED=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
LIMIT_5H=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty')
DIR=$(basename "$(echo "$INPUT" | jq -r '.workspace.current_dir // "."')")

# Validate that percentage and token metrics are clean integers
PCT_INT=${PCT:-0}
[[ ! "$PCT_INT" =~ ^[0-9]+$ ]] && PCT_INT=0
TOKENS_INT=${TOKENS_USED:-0}
[[ ! "$TOKENS_INT" =~ ^[0-9]+$ ]] && TOKENS_INT=0

# 3. High-performance native Bash token formatting (e.g., 42500 -> 42.5k)
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

# 4. Safe formatting for floating point billing metrics
COST_FMT=$(printf '%.2f' "$COST" 2>/dev/null || echo "0.00")

# 5. Build 10-step horizontal progress bar
FILLED=$(( PCT_INT / 10 ))
[ "$FILLED" -gt 10 ] && FILLED=10
EMPTY=$(( 10 - FILLED ))
[ "$EMPTY" -lt 0 ] && EMPTY=0

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█";  done
for ((i=0; i<EMPTY; i++)); do  BAR="${BAR}░";  done

# 6. Monochrome Dark ANSI Color Codes
TEXT="\033[38;5;250m"      # Light Gray
MUTED="\033[38;5;241m"     # Dark Charcoal Gray
ALERT="\033[7;38;5;250m"   # Inverse Video (Alert Block)
RESET="\033[0m"            # Standard Clear

# 7. Matt Pocock Context Guard: Hard cutoff threshold at 50%
if [ "$PCT_INT" -lt 50 ]; then
    ZONE="${MUTED}[${TEXT}SMART${MUTED}]${RESET}"
else
    ZONE="${ALERT}[!! DUMB !!]${RESET}"
fi

# 8. Render optional tier subscriber quotas dynamically
RATE_SEG=""
if [ -n "$LIMIT_5H" ]; then
    LIMIT_INT=$(printf '%.0f' "$LIMIT_5H" 2>/dev/null || echo "0")
    RATE_SEG=" ${MUTED}[${TEXT}RATE: ${LIMIT_INT}%${MUTED}]${RESET}"
fi

# 9. Output formatted layout straight to terminal footer
echo -e "${MUTED}[${TEXT}${MODEL} | ${DIR}${MUTED}]${RESET} ${MUTED}[${TEXT}CTX: ${BAR} ${TOKENS_K}${MUTED}]${RESET} ${MUTED}[${TEXT}\$${COST_FMT}${MUTED}]${RESET}${RATE_SEG} ${ZONE}"
