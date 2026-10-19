#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -ne 1 ]; then
    echo 'Usage: plasmoidlocaletest.sh pl_PL.UTF-8' >&2
    exit 2
fi
command -v plasmoidviewer >/dev/null 2>&1 || { echo 'Install plasma-sdk (Plasma 6) to use plasmoidviewer.' >&2; exit 1; }
sh "$script_dir/build.sh"
LANG="$1" LANGUAGE="${1%%.*}" LC_TIME="$1" QML_DISABLE_DISK_CACHE=true exec plasmoidviewer -a "$script_dir/.." -l bottomedge -f horizontal
