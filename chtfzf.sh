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

function main {
    for i in "$@"; do 
        case "$i" in 
            -t) openMode="tmux";;
            sync) syncSheetList;;
            *) ;; # Do nothing if no matches
        esac
    done
    # Use Search through main list.
    if [ -f "$CACHE_DIR/main.list" ]; then
        # Use cached list if it exists
        search=$(grep -v ":list" "$CACHE_DIR/main.list" | fzf --preview="curl -s "cht.sh/{}"")
    else
        search=$(curl -s "cht.sh/:list" | grep -v ":list" | fzf --preview="curl -s "cht.sh/{}"")
    fi

    # Direct match without /
    if [[ "${search: -1}" != "/" ]]; then
        openSheet "$search"
        exit
    fi

    path="$search"
    # Read :lists to go deeper
    while [[ "${search: -1}" == "/" ]]; do
        search=$(curl -s "cht.sh/$path:list" | grep -v ":list" | fzf --preview="curl -s "cht.sh/$path{}"")
        path="$path$search"
    done

    openSheet "$path"
}

main $@ # Pass CLI args to main 
