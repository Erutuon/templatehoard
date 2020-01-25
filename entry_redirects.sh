#! /usr/bin/env bash

YEAR=$(date +%Y)
MONTH=$(date +%m)
if [ $(date +%d) -ge 20 ]; then
    DAY=20;
else
    DAY=01;
fi
DATE=$YEAR$MONTH$DAY

OUT_DIR=~/entry_redirects

cd ~/enwikt-dump-rs && mkdir -p $OUT_DIR && lua lua/redirects_in_namespaces.lua "" reconstruction appendix > $OUT_DIR/$DATE.txt
