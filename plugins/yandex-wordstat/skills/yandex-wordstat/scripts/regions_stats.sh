#!/bin/bash
# Get regional search statistics from Yandex Wordstat

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Defaults
PHRASE=""
REGION_TYPE="all"
DEVICES="all"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --phrase|-p) PHRASE="$2"; shift 2 ;;
        --region-type|-t) REGION_TYPE="$2"; shift 2 ;;
        --devices|-d) DEVICES="$2"; shift 2 ;;
        *) printf "Unknown option: %s\n" "$1"; exit 1 ;;
    esac
done

if [[ -z "$PHRASE" ]]; then
    printf "Usage: regions_stats.sh --phrase \"search query\" [options]\n\n"
    printf "Options:\n"
    printf "  --phrase, -p       Search phrase (required)\n"
    printf "  --region-type, -t  Filter: cities, regions, all (default: all)\n"
    printf "  --devices, -d      Device filter: all, desktop, phone, tablet (default: all)\n\n"
    printf "Examples:\n"
    printf "  bash scripts/regions_stats.sh --phrase \"юрист дтп\"\n"
    printf "  bash scripts/regions_stats.sh --phrase \"юрист\" --region-type cities\n"
    exit 1
fi

load_config || exit 1

# Escape phrase for JSON
PHRASE_ESCAPED=$(json_escape "$PHRASE")

# Build JSON params
PARAMS="{\"phrase\":\"$PHRASE_ESCAPED\""

if [[ "$REGION_TYPE" != "all" ]]; then
    PARAMS="$PARAMS,\"regionType\":\"$REGION_TYPE\""
fi

if [[ "$DEVICES" != "all" ]]; then
    PARAMS="$PARAMS,\"devices\":[\"$DEVICES\"]"
fi

PARAMS="$PARAMS}"

printf "=== Yandex Wordstat: Regional Statistics ===\n"
printf "Phrase: %s\n" "$PHRASE"
printf "Region type: %s\n" "$REGION_TYPE"
printf "Devices: %s\n\n" "$DEVICES"
printf "Fetching data...\n"

result=$(wordstat_request "regions" "$PARAMS")

# Check for error
if echo "$result" | grep -q '"error"'; then
    printf "Error:\n%s\n" "$result"
    exit 1
fi

printf "\n=== Top 30 Regions ===\n\n"

printf "| Region ID | Count |\n"
printf "|-----------|-------|\n"

# Extract regions data - simple approach without sort (API returns in useful order)
count=0
while IFS= read -r entry && [[ $count -lt 30 ]]; do
    region_id=$(echo "$entry" | sed 's/.*"regionId":\([0-9]*\).*/\1/')
    cnt=$(echo "$entry" | sed 's/.*"count":\([0-9]*\).*/\1/')
    printf "| %s | %s |\n" "$region_id" "$(format_number "$cnt")"
    count=$((count + 1))
done < <(echo "$result" | grep -oE '"regionId":[0-9]+,"count":[0-9]+')

printf "\nNote: Use search_region.sh --name \"City\" to find region names\n"
