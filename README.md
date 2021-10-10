# fuzzy-sheets
FZF based client for cht.sh

Requirements: bash, curl, fzf

[![asciicast](https://asciinema.org/a/438252.svg)](https://asciinema.org/a/438252)

## Usage
Ensure chtfzf is marked executable (`chmod +x chtfzf.sh`) then run like any other shell script

    $ ./chtfzf.sh
    
or to send a text based query:

    $ ./chtfzf.sh query

## Options
    * -t              | Tmux Mode (sheet launches in new tmux window)
    * sync            | Cache main :list and enable preview caching
    * preview <sheet> | Preview a sheet (and cache it if sync has run)
    * query           | After selecting, launch a text input to query question (i.e. go/ "open a file")

## Tmux Launch binding
To launch fuzzy-sheets in a tmux window you can use the -t flag in your `tmux.conf` as such:

    bind-key i run-shell "tmux neww ~/git/fuzzy-sheets/chtfzf.sh -t"

This will launch fuzzy-sheets in a new window which will disappear after you quit fuzzy-sheets and bring you back to your last window.

Thanks to [ThePrimeagen](https://github.com/ThePrimeagen) for inspiration: https://www.youtube.com/watch?v=hJzqEAf2U4I
