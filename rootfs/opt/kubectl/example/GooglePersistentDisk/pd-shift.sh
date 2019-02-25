#!/bin/bash

# Read <FILENAME> (format "pvc;pd") and
# generate yaml files for volumes creation (pvc,pv and pd)

# @author Fabrice Jammes <fabrice.jammes@in2p3.fr>

set -e
# set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

OUT_DIR="$DIR/out"

mkdir -p "$OUT_DIR"

FILENAME="$1"

while read -r line; do
    pv=$(echo $line | cut -d';' -f1)
    pd=$(echo $line | cut -d';' -f2)
    echo "... $pv $pd ..."
    ./pd-builder.py -n "$pv" -d "$pd" --out "$OUT_DIR"
done < "$FILENAME"
