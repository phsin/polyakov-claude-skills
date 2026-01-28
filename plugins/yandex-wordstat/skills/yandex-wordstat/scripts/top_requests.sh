#!/bin/bash
# Get top search phrases from Yandex Wordstat

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Defaults
PHRASE=""
REGIONS=""
DEVICES="all"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --phrase|-p) PHRASE="$2"; shift 2 ;;
        --regions|-r) REGIONS="$2"; shift 2 ;;
        --devices|-d) DEVICES="$2"; shift 2 ;;
        *) printf "Unknown option: %s\n" "$1"; exit 1 ;;
    esac
done

if [[ -z "$PHRASE" ]]; then
    printf "Usage: top_requests.sh --phrase \"search query\" [options]\n\n"
    printf "Options:\n"
    printf "  --phrase, -p   Search phrase (required)\n"
    printf "  --regions, -r  Region IDs, comma-separated (optional)\n"
    printf "  --devices, -d  Device filter: all, desktop, phone, tablet (default: all)\n\n"
    printf "Examples:\n"
    printf "  bash scripts/top_requests.sh --phrase \"юрист по дтп\"\n"
    printf "  bash scripts/top_requests.sh --phrase \"юрист дтп\" --regions \"1,2\"\n"
    printf "  bash scripts/top_requests.sh --phrase \"\\\"!юрист !по !дтп\\\"\" --devices phone\n"
    exit 1
fi

load_config || exit 1

# Escape phrase for JSON
PHRASE_ESCAPED=$(json_escape "$PHRASE")

# Build JSON params
PARAMS="{\"phrase\":\"$PHRASE_ESCAPED\""

if [[ -n "$REGIONS" ]]; then
    PARAMS="$PARAMS,\"regions\":[$REGIONS]"
fi

if [[ "$DEVICES" != "all" ]]; then
    PARAMS="$PARAMS,\"devices\":[\"$DEVICES\"]"
fi

PARAMS="$PARAMS}"

printf "=== Yandex Wordstat: Top Requests ===\n"
printf "Phrase: %s\n" "$PHRASE"
[[ -n "$REGIONS" ]] && printf "Regions: %s\n" "$REGIONS"
printf "Devices: %s\n\n" "$DEVICES"
printf "Fetching data...\n"

result=$(wordstat_request "topRequests" "$PARAMS")

# Check for error
if echo "$result" | grep -q '"error"'; then
    printf "Error:\n%s\n" "$result"
    exit 1
fi

printf "\n=== Results ===\n\n"

# Extract totalCount
total_count=$(echo "$result" | grep -o '"totalCount":[0-9]*' | head -1 | sed 's/"totalCount"://')
printf "Total impressions: %s\n\n" "$(format_number "$total_count")"

# Parse and display results
printf "| # | Phrase | Impressions |\n"
printf "|---|--------|-------------|\n"

count=0
# Extract phrase-count pairs
echo "$result" | grep -o '{"phrase":"[^"]*","count":[0-9]*}' | head -50 | while IFS= read -r entry; do
    count=$((count + 1))

    phrase=$(echo "$entry" | grep -o '"phrase":"[^"]*"' | sed 's/"phrase":"//' | tr -d '"')
    shows=$(echo "$entry" | grep -o '"count":[0-9]*' | sed 's/"count"://')

    printf "| %d | %s | %s |\n" "$count" "$phrase" "$(format_number "$shows")"
done

printf "\n=== Associations ===\n\n"

# Extract associations if present
echo "$result" | grep -o '"associations":\[.*\]' | grep -o '{"phrase":"[^"]*","count":[0-9]*}' | head -10 | while IFS= read -r entry; do
    phrase=$(echo "$entry" | grep -o '"phrase":"[^"]*"' | sed 's/"phrase":"//' | tr -d '"')
    shows=$(echo "$entry" | grep -o '"count":[0-9]*' | sed 's/"count"://')
    printf "%s\n" "- $phrase ($(format_number "$shows"))"
done

printf "\n"
