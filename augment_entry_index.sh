#! /usr/bin/env bash

YEAR=$(date +%Y)
MONTH=$(date +%m)
if [ $(date +%d) -ge 20 ]; then
    DAY=20;
else
    DAY=01;
fi
DATE=$YEAR$MONTH$DAY

mkdir -p ~/augmented_entry_index && lua ~/git/augment_entry_index.lua ~/entry_index/$DATE.txt ~/entry_redirects/$DATE.txt > augmented_entry_index/$DATE.txt