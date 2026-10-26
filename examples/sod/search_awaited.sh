#!/bin/bash
# Run himalaya envelope searches in parallel and print the results in input order.
#
# Usage:
#   printf '%s\n' "after 2026-10-08 and body acme" "after 2026-10-23 and from hit-reply" \
#     | search_awaited.sh [-P jobs]
#
# One query per line on stdin; blank lines and lines starting with # are skipped.
# Each query gets a "### <query>  (Ns)" header, then its hit rows (newest first, at most 5),
# "(no hits)", or "SEARCH FAILED" with the error. A failed search never prints as empty.
# Default 8 at a time: Gmail allows about 15 IMAP connections per account.
# Written for the macOS system bash (3.2), so no wait -n or mapfile.
#
# Each query is checked against himalaya's filter grammar before it runs, because himalaya
# answers a malformed one ("fromm x", "bodyy x", "after 2026-13-45") with an empty table
# instead of an error, which reads exactly like a real absence.

# Print why a query is malformed and return 1; return 0 if it parses.
check_query() {
    set -f; set -- $1; set +f
    want=cond
    while [ $# -gt 0 ]; do
        if [ "$want" = cond ]; then
            if [ "$1" = not ]; then shift; continue; fi
            kw=$1 arg=${2:-}
            case "$kw" in
                date|before|after)
                    if [ "$(date -j -f %Y-%m-%d "$arg" +%Y-%m-%d 2>/dev/null)" != "$arg" ]; then
                        echo "bad date '$arg' after '$kw'"; return 1
                    fi ;;
                from|to|subject|body|flag)
                    if [ -z "$arg" ]; then echo "'$kw' has no pattern"; return 1; fi ;;
                *) echo "unknown condition '$kw'"; return 1 ;;
            esac
            if [ $# -lt 2 ]; then shift; else shift 2; fi
            want=op
        else
            case "$1" in
                and|or) shift; want=cond ;;
                *) echo "expected 'and' or 'or', got '$1'"; return 1 ;;
            esac
        fi
    done
    if [ "$want" != op ]; then echo "ends without a condition"; return 1; fi
}

if [ "${1:-}" = "--one" ]; then
    dir=$2 idx=$3 q=$4
    if ! why=$(check_query "$q"); then
        printf '### %s\nSEARCH FAILED (malformed query: %s)\n' "$q" "$why" > "$dir/$idx.out"
        exit 0
    fi
    start=$(date +%s)
    res=$(himalaya envelope list --page-size 5 --max-width 160 -- "$q" 2>"$dir/$idx.err")
    rc=$?
    secs=$(( $(date +%s) - start ))
    {
        printf '### %s  (%ss)\n' "$q" "$secs"
        if [ "$rc" -ne 0 ]; then
            printf 'SEARCH FAILED (exit %s): %s\n' "$rc" "$(grep -v ' WARN ' "$dir/$idx.err" | tail -1)"
        else
            hits=$(printf '%s\n' "$res" | grep '^| [0-9]')
            printf '%s\n' "${hits:-(no hits)}"
        fi
    } > "$dir/$idx.out"
    exit 0
fi

jobs=8
if [ "${1:-}" = "-P" ]; then jobs=$2; fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

grep -v -e '^[[:space:]]*$' -e '^#' > "$dir/queries"
n=$(wc -l < "$dir/queries" | tr -d ' ')

start=$(date +%s)
i=0
while IFS= read -r q; do
    i=$((i + 1))
    printf '%03d\0%s\0' "$i" "$q"
done < "$dir/queries" | xargs -0 -n 2 -P "$jobs" "$0" --one "$dir"

done_n=0
for f in "$dir"/*.out; do
    [ -e "$f" ] || continue
    cat "$f"
    done_n=$((done_n + 1))
done
printf '=== %s of %s searches ran, in %ss\n' "$done_n" "$n" "$(( $(date +%s) - start ))"
if [ "$done_n" -ne "$n" ]; then
    echo "SEARCH FAILED: $((n - done_n)) queries produced no output; rerun them one at a time"
fi
