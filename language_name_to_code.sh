#! /usr/bin/env bash

WORKING_DIR=$HOME/share/lua/5.3/enwiktionary
mkdir -p $WORKING_DIR
cd $WORKING_DIR

. common.sh

$HOME/enwikt-dump-rs/target/release/process-with-lua text -n module -i $PAGES_META_CURRENT -e 'if page.title == "Module:languages/canonical names" then print(page.text) return false end return true' > language_name_to_code.lua
