#! /usr/bin/env bash

. common.sh

mkdir -p ~/augmented_entry_index && lua ~/git/augment_entry_index.lua ~/entry_index/$DATE.txt ~/entry_redirects/$DATE.txt > augmented_entry_index/$DATE.txt