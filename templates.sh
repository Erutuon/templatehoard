#! /usr/bin/env bash

if (( $# == 0 )); then
	echo "At least one argument is required.";
fi

cd "$HOME/enwikt-dump-rs";

for arg in "$@"; do
	if [[ ! -f "$arg" ]]; then
		echo "All parameters must be filepaths; $arg is not.";
		exit -1;
	fi
done

DATE=20191220
WIKI=enwiktionary

DUMP_DIR="$HOME/www/static/dump/$DATE";

if [[ ! -d "$DUMP_DIR" ]]; then
    mkdir -p "$DUMP_DIR" || { echo Failed to create dump directory; exit -1; };
fi

FILENAME=template_names.txt;

cat "$@" | lua/add_template_redirects.lua > $DUMP_DIR/$FILENAME || { echo Failed to add redirects to $FILENAME; exit -1; };

cd "$DUMP_DIR";

"$HOME/bin/wiktionary-data" dump-parsed-templates --input "/public/dumps/public/$WIKI/$DATE/$WIKI-$DATE-pages-articles.xml.bz2" --templates "$FILENAME" \
    --namespaces main,reconstruction,appendix --format cbor;
