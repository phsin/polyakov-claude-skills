#!/bin/bash
# Check Yandex Wordstat API connection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config || exit 1

printf "Checking Wordstat API connection...\n\n"

# Test with a simple regions request
response=$(wordstat_request "regions" '{"phrase":"тест"}')

if echo "$response" | grep -q '"regions"'; then
    printf "✓ Wordstat API: OK\n\n"

    # Count regions in response
    region_count=$(echo "$response" | grep -o '"regionId"' | wc -l | tr -d ' ')
    printf "Test query 'тест' returned data for %s regions\n" "$region_count"
else
    printf "✗ Wordstat API: Error\n"
    printf "%s\n" "$response"
    exit 1
fi

printf "\n=== API Limits ===\n"
printf "%s\n" "- Rate limit: 10 requests/second"
printf "%s\n" "- Daily quota: 1000 requests"
printf "\n=== Available endpoints ===\n"
printf "%s\n" "- /v1/topRequests - top search phrases"
printf "%s\n" "- /v1/dynamics   - search volume over time"
printf "%s\n" "- /v1/regions    - regional distribution"
printf "\n✓ Token is valid and API is accessible.\n"
