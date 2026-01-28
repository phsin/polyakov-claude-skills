#!/bin/bash
# Search for region by name

SEARCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name|-n) SEARCH="$2"; shift 2 ;;
        *) printf "Unknown option: %s\n" "$1"; exit 1 ;;
    esac
done

if [[ -z "$SEARCH" ]]; then
    printf "Usage: search_region.sh --name \"city name\"\n\n"
    printf "Examples:\n"
    printf "  bash scripts/search_region.sh --name \"Москва\"\n"
    printf "  bash scripts/search_region.sh --name \"Казань\"\n"
    exit 1
fi

printf "Searching for: %s\n\n" "$SEARCH"

# Hardcoded common regions
REGIONS="225|Россия
159|Казахстан
187|Украина
149|Беларусь
3|Центральный ФО
17|Северо-Западный ФО
40|Приволжский ФО
52|Уральский ФО
59|Сибирский ФО
73|Южный ФО
26|Дальневосточный ФО
1|Москва и область
213|Москва
10716|Московская область
2|Санкт-Петербург
54|Екатеринбург
65|Новосибирск
43|Казань
35|Краснодар
47|Нижний Новгород
39|Ростов-на-Дону
51|Самара
172|Уфа
56|Челябинск
66|Омск
11|Пермь
14|Воронеж
38|Волгоград
37|Саратов
195|Тюмень"

# Search (case-insensitive)
matches=$(echo "$REGIONS" | grep -i "$SEARCH" || true)

if [[ -z "$matches" ]]; then
    printf "No regions found matching \"%s\"\n\n" "$SEARCH"
    printf "Try running regions_tree.sh to see all common regions\n"
else
    printf "Found:\n\n"
    printf "| ID | Name |\n"
    printf "|----|------|\n"
    echo "$matches" | while IFS='|' read -r id name; do
        [[ -n "$id" ]] && printf "| %s | %s |\n" "$id" "$name"
    done
fi
