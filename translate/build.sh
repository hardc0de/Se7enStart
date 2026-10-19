#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -ne 0 ]; then
    echo 'Usage: build.sh (builds translations without restarting Plasma)' >&2
    exit 2
fi
exec python3 "$script_dir/messages.py" build
