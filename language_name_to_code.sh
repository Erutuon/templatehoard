#! /usr/bin/env bash

WORKING_DIR=$HOME/share/lua/5.3/enwiktionary
mkdir -p $WORKING_DIR
cd $WORKING_DIR

WIKI=enwiktionary

YEAR=$(date +%Y)
MONTH=$(date +%m)
if [ $(date +%d) -ge 20 ]; then
    DAY=20;
else
    DAY=01;
fi
DATE=$YEAR$MONTH$DAY

PAGES=/public/dumps/public/$WIKI/$DATE/$WIKI-$DATE-pages-meta-current.xml.bz2

$HOME/enwikt-dump-rs/target/release/process-with-lua text -n module -i $PAGES -e 'if page.title == "Module:languages/canonical names" then print(page.text) return false end return true' > language_name_to_code.lua
