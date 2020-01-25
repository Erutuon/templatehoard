#! /usr/bin/env bash

. common.sh

SCRIPT=~/git/entry_index.lua
OUT_DIR=~/entry_index
ENWIKTIONARY_LUA_DIR=~/share/lua/5.3/enwiktionary
PROCESS_WITH_LUA=~/enwikt-dump-rs/target/release/process-with-lua

$PROCESS_WITH_LUA text \
    -i $PAGES_META_CURRENT \
    -n module \
    -e 'if page.title == "Module:languages/canonical names" then print(page.text) return false end return true' \
    > $ENWIKTIONARY_LUA_DIR/language_name_to_code.lua || { echo Error while finding Module:languages/canonical names; exit -1; }

mkdir -p $OUT_DIR
$PROCESS_WITH_LUA headers \
    -n main -n reconstruction -n appendix \
    -i $PAGES_ARTICLES \
    -s $SCRIPT \
    > $OUT_DIR/$DUMP_DATE.txt
