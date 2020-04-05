#! /usr/bin/env bash

. ~/git/common.sh

OUT_DIR=~/entry_redirects

cd ~/enwikt-dump-rs && mkdir -p $OUT_DIR && lua lua/redirects_in_namespaces.lua "" reconstruction appendix > $OUT_DIR/$DUMP_DATE.txt
