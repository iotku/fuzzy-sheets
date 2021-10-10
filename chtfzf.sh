#!/usr/bin/env bash
# chtfzf.sh
# by iotku
# license: wtfpl
# Requirements: curl, fzf

# Docs: use -t flag to launch in a new tmux window
#   - ``chtfzf sync`` to cache main list for faster access

set -euf -o pipefail
CACHE_DIR="${HOME}/.local/share/chtfzf"
openMode="bash"

function main {
    # Read Command Line Arguments
    for i in "$@"; do
        case "$i" in
            -t) openMode="tmux";;
            sync) syncSheetList;;
            query) shift; query $*;;
            preview) shift; cachePreview "$*";;
            *) ;; # Do nothing if no matches
        esac
    done

    # Use Search through main list.
    if [ -f "$CACHE_DIR/main.list" ]; then
        # Use cached list if it exists
        search=$(grep -v ":list" "$CACHE_DIR/main.list" | fzf --preview="${BASH_SOURCE[0]} preview '{}'")
    else
        search=$(curl -sg "cht.sh/:list" | grep -v ":list" | fzf --preview="${BASH_SOURCE[0]} preview '{}'")
    fi

    # Direct match without /
    if [[ "${search: -1}" != "/" ]]; then
        openSheet "$search"
        exit
    fi

    path="$search"
    # Read :lists to go deeper
    while [[ "${search: -1}" == "/" ]]; do
        search=$(curl -sg "cht.sh/$path:list" | grep -v ":list" | fzf --preview="${BASH_SOURCE[0]} preview "$path{}"")
        path="$path$search"
    done

    openSheet "$path"
}

function openSheet {
    # Exit if empty string
    if [[ "$1" == "" ]]; then exit; fi
    case "$openMode" in
        tmux) tmux neww bash -c "curl -sg "cht.sh/$*" | less -R";;
        bash) curl -sg "cht.sh/$*" | less -R;;
        *) echo "Unknown openMode, set -t to use tmux, or no args to use bash directly"
    esac
}

function query {
    # Use Search through main list.
    if [ -f "$CACHE_DIR/main.list" ]; then
        # Use cached list if it exists
        search=$(grep -v ":list" "$CACHE_DIR/main.list" | fzf --query="$*" --preview="${BASH_SOURCE[0]} preview '{}'")
    else
        search=$(curl -sg "cht.sh/:list" | grep -v ":list" | fzf --query="$*" --preview="${BASH_SOURCE[0]} preview '{}'")
    fi

    read -rp "query: " queryInput
    queryInput=$(tr ' ' '+' <<< "$queryInput")
    if [[ "${search: -1}" != "/" ]]; then
        openSheet "$(echo -ne "$search~$queryInput\n$search/$queryInput" | fzf --preview="${BASH_SOURCE[0]} preview '{}'")"
    else
        openSheet "$(echo -ne "$search$queryInput\n$search~$queryInput" | fzf  --preview="${BASH_SOURCE[0]} preview '{}'")"
    fi

    exit
}

function syncSheetList {
    [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR"
    printf "Saving main.list to %s\nDon't forget to sync in the future :)\n" "$CACHE_DIR"
    curl "cht.sh/:list" > "$CACHE_DIR/main.list"
    printf "done.\n"
    exit
}

function cachePreview {
    # Hopefully avoid really bad situations
    if [[ "$*" == "" ]]; then exit; fi
    if [[ "$*" == "/" ]]; then exit; fi

    # Just use curl directly if we don't have a cache directory (haven't done sync yet)
    if [ ! -d "$CACHE_DIR" ]; then
       curl -sg "cht.sh/$*"
       exit
    fi

    # Exists in cache
    if [ -f "$CACHE_DIR/$*.sheet" ]; then
        cat "$CACHE_DIR/$*.sheet"
        exit
    fi

    # Make subdirectory structure to match preview
    SUB_DIR="$(dirname "$CACHE_DIR/$*.sheet")"
    [ ! -d  "$SUB_DIR" ] && mkdir -p "$SUB_DIR"
    # sheet with status code as last line
    sheet="$(curl -sg -w "%{http_code}" "cht.sh/$*")"
    statusCode="$(tail -n1 <<< "$sheet")"
    sheet="$(sed '$d' <<< "$sheet")" # Remove status code from output
    if [[ "$statusCode" == "200" ]]; then
        tee "$CACHE_DIR/$*.sheet" <<< "$sheet"
    else
        # Don't cache error page
        printf "Sorry, cht.sh returned non 200 status code (error):\n%s" "$sheet"
    fi
    exit
}

main $@ # Pass CLI args to main 
