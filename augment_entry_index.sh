#! /usr/bin/env bash

. ~/git/common.sh

mkdir -p ~/augmented_entry_index && \
    lua ~/git/augment_entry_index.lua ~/entry_index/$DUMP_DATE.txt ~/entry_redirects/$DUMP_DATE.txt \
        > augmented_entry_index/$DUMP_DATE.txt