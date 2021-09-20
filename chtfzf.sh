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

function openSheet {
    case "$openMode" in
        tmux) tmux neww bash -c "curl -s "cht.sh/$*" | less -R";;
        bash) curl -s "cht.sh/$*" | less -R;;
        *) echo "Unknown openMode, set -t to use tmux, or no args to use bash directly"
    esac
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
       curl -s "cht.sh/$*"
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
    curl -s "cht.sh/$*" | tee "$CACHE_DIR/$*.sheet"
    exit
}

function main {
    for i in "$@"; do 
        case "$i" in 
            -t) openMode="tmux";;
            sync) syncSheetList;;
            preview) shift; cachePreview "$*";;
            *) ;; # Do nothing if no matches
        esac
    done
    # Use Search through main list.
    if [ -f "$CACHE_DIR/main.list" ]; then
        # Use cached list if it exists
        search=$(grep -v ":list" "$CACHE_DIR/main.list" | fzf --preview="${BASH_SOURCE[0]} preview "{}"")
    else
        search=$(curl -s "cht.sh/:list" | grep -v ":list" | fzf --preview="${BASH_SOURCE[0]} preview "{}"")
    fi

    # Direct match without /
    if [[ "${search: -1}" != "/" ]]; then
        openSheet "$search"
        exit
    fi

    path="$search"
    # Read :lists to go deeper
    while [[ "${search: -1}" == "/" ]]; do
        search=$(curl -s "cht.sh/$path:list" | grep -v ":list" | fzf --preview="${BASH_SOURCE[0]} preview "$path{}"")
        path="$path$search"
    done

    openSheet "$path"
}

main $@ # Pass CLI args to main 
