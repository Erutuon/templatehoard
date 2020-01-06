#! /usr/bin/env bash

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

cd $HOME/git

$HOME/enwikt-dump-rs/target/release/process-with-lua headers -n main -n reconstruction -n appendix -i $PAGES -s entry_index.lua > entry_index.txt
