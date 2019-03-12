#!/bin/bash

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

FILENAME="$1"

while read -r line; do
    pv=$(echo $line | cut -d';' -f1)
    pd=$(echo $line | cut -d';' -f2)
    echo "... $pv $pd ..."
    ./pd-builder.py -n "$pv" -d "$pd" --out "$DIR/out"
done < "$FILENAME"
