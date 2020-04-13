#! /usr/bin/env bash

. ~/git/common.sh

OUT_DIR=~/entry_redirects

# main, appendix, reconstruction
cd ~/parse-mediawiki-sql && mkdir -p $OUT_DIR && cargo run --release --example redirects_by_namespace 0 100 118 > $OUT_DIR/$DUMP_DATE.txt
