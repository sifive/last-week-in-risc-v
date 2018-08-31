#!/bin/bash

# FIXME: This should be configurable
FOLDER="$HOME/work/last-week-in-risc-v"

# Command-line argument handling
date="this friday"
branch=master
while [[ "$1" != "" ]]
do
  case "$1" in
  -*)
    echo "Unknown argument $1">&2
    exit 1
    ;;
  *)
    date="$@"
    while [[ "$1" != "" ]]
    do
        shift
    done
    ;;
  esac
done

note=lwirv-"$(date -d "$date" "+%Y-%m-%d")".md

if test -z branch
then
    branch=auto-"$(date -d "$date" "+%Y-%m-%d")"
fi

(
    cd "$FOLDER" || exit 1

    # Ensure we're up to date WRT the latest upstream master.
    git fetch --all --prune --verbose

    # Checks out the relevant branch, updating it if possible.
    git checkout $branch || git checkout origin/master -b $branch || exit 1
    git merge --ff-only origin/master || exit 1

    # Checks to see if there's an existing weekly note, creating one if there
    # isn't.
    if test ! -f "$note"
    then
      cat >$note <<EOF
# Last Week in RISC-V: $(date -d "$date" "+%A %B %e, %Y")
EOF
    fi

    # Fire up an editor to touch the notes as you see fit.
    vim "$note"

    # Commit and push the note.
    git commit -s "$note"
    git push origin $branch
) || exit 1
