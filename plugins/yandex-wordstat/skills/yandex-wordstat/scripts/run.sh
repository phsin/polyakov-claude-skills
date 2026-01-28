#!/bin/bash
# Runner script for Yandex Wordstat tools
# Usage: source scripts/run.sh <command> [args...]
# Or: . scripts/run.sh <command> [args...]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_wordstat() {
    local cmd="$1"
    shift

    case "$cmd" in
        quota)
            source "$SCRIPT_DIR/quota.sh"
            ;;
        top|top_requests)
            source "$SCRIPT_DIR/top_requests.sh" "$@"
            ;;
        dynamics)
            source "$SCRIPT_DIR/dynamics.sh" "$@"
            ;;
        regions|regions_stats)
            source "$SCRIPT_DIR/regions_stats.sh" "$@"
            ;;
        tree|regions_tree)
            source "$SCRIPT_DIR/regions_tree.sh"
            ;;
        search|search_region)
            source "$SCRIPT_DIR/search_region.sh" "$@"
            ;;
        help|*)
            printf "Yandex Wordstat CLI\n\n"
            printf "Usage: source scripts/run.sh <command> [args...]\n\n"
            printf "Commands:\n"
            printf "  quota          - Check API connection\n"
            printf "  top            - Get top search phrases\n"
            printf "  dynamics       - Get search volume over time\n"
            printf "  regions        - Get regional statistics\n"
            printf "  tree           - Show common region IDs\n"
            printf "  search         - Search region by name\n\n"
            printf "Examples:\n"
            printf "  source scripts/run.sh quota\n"
            printf "  source scripts/run.sh top --phrase \"купить телефон\"\n"
            printf "  source scripts/run.sh dynamics --phrase \"test\" --from-date 2025-01-01\n"
            printf "  source scripts/run.sh regions --phrase \"test\"\n"
            printf "  source scripts/run.sh search --name \"Москва\"\n"
            ;;
    esac
}

# If script is sourced with arguments, run immediately
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ $# -gt 0 ]]; then
    run_wordstat "$@"
fi
