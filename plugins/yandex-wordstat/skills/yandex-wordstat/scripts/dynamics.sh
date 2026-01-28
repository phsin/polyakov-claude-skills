#!/bin/bash
# Get search volume dynamics from Yandex Wordstat

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Defaults
PHRASE=""
PERIOD="monthly"
FROM_DATE=""
TO_DATE=""
REGIONS=""
DEVICES="all"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --phrase|-p) PHRASE="$2"; shift 2 ;;
        --period) PERIOD="$2"; shift 2 ;;
        --from-date|-f) FROM_DATE="$2"; shift 2 ;;
        --to-date|-t) TO_DATE="$2"; shift 2 ;;
        --regions|-r) REGIONS="$2"; shift 2 ;;
        --devices|-d) DEVICES="$2"; shift 2 ;;
        *) printf "Unknown option: %s\n" "$1"; exit 1 ;;
    esac
done

if [[ -z "$PHRASE" ]]; then
    printf "Usage: dynamics.sh --phrase \"search query\" [options]\n\n"
    printf "Options:\n"
    printf "  --phrase, -p    Search phrase (required)\n"
    printf "  --period        Grouping: daily, weekly, monthly (default: monthly)\n"
    printf "  --from-date, -f Start date YYYY-MM-DD (default: 1 year ago)\n"
    printf "  --to-date, -t   End date YYYY-MM-DD (default: today)\n"
    printf "  --regions, -r   Region IDs, comma-separated (optional)\n"
    printf "  --devices, -d   Device filter: all, desktop, phone, tablet (default: all)\n\n"
    printf "Examples:\n"
    printf "  bash scripts/dynamics.sh --phrase \"юрист дтп\" --from-date 2025-01-01\n"
    printf "  bash scripts/dynamics.sh --phrase \"юрист\" --period weekly --from-date 2025-06-01\n"
    exit 1
fi

# Set default from_date if not provided (1 year ago)
if [[ -z "$FROM_DATE" ]]; then
    # Try different date commands for cross-platform compatibility
    FROM_DATE=$(date -v-1y +%Y-%m-%d 2>/dev/null || date -d "1 year ago" +%Y-%m-%d 2>/dev/null || echo "2025-01-01")
fi

load_config || exit 1

# Escape phrase for JSON
PHRASE_ESCAPED=$(json_escape "$PHRASE")

# Build JSON params
PARAMS="{\"phrase\":\"$PHRASE_ESCAPED\",\"period\":\"$PERIOD\",\"fromDate\":\"$FROM_DATE\""

if [[ -n "$TO_DATE" ]]; then
    PARAMS="$PARAMS,\"toDate\":\"$TO_DATE\""
fi

if [[ -n "$REGIONS" ]]; then
    PARAMS="$PARAMS,\"regions\":[$REGIONS]"
fi

if [[ "$DEVICES" != "all" ]]; then
    PARAMS="$PARAMS,\"devices\":[\"$DEVICES\"]"
fi

PARAMS="$PARAMS}"

printf "=== Yandex Wordstat: Dynamics ===\n"
printf "Phrase: %s\n" "$PHRASE"
printf "Period: %s\n" "$PERIOD"
printf "From: %s\n" "$FROM_DATE"
[[ -n "$TO_DATE" ]] && printf "To: %s\n" "$TO_DATE"
[[ -n "$REGIONS" ]] && printf "Regions: %s\n" "$REGIONS"
printf "Devices: %s\n\n" "$DEVICES"
printf "Fetching data...\n"

result=$(wordstat_request "dynamics" "$PARAMS")

# Check for error
if echo "$result" | grep -q '"error"'; then
    printf "Error:\n%s\n" "$result"
    exit 1
fi

printf "\n=== Results ===\n\n"

printf "| Date | Count | Share |\n"
printf "|------|-------|-------|\n"

# Extract dynamics data
echo "$result" | grep -o '{"date":"[^"]*","count":[0-9]*,"share":[0-9.]*}' | while IFS= read -r entry; do
    dt=$(echo "$entry" | grep -o '"date":"[^"]*"' | sed 's/"date":"//' | tr -d '"')
    cnt=$(echo "$entry" | grep -o '"count":[0-9]*' | sed 's/"count"://')
    share=$(echo "$entry" | grep -o '"share":[0-9.]*' | sed 's/"share"://')
    share_pct=$(awk "BEGIN {printf \"%.2f\", $share * 100}")

    printf "| %s | %s | %s%% |\n" "$dt" "$(format_number "$cnt")" "$share_pct"
done

printf "\n"
