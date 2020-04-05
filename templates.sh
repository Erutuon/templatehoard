#! /usr/bin/env bash

if (( $# == 0 )); then
	echo "At least one argument is required.";
    exit -1;
fi

for arg in "$@"; do
	if [[ ! -f "$arg" ]]; then
		echo "All parameters must be filepaths; $arg is not.";
		exit -1;
	fi
done

. ~/git/common.sh

DUMP_DIR=$HOME/www/static/dump/$DUMP_DATE
TEMPLATE_NAMES=$DUMP_DIR/template_names.txt
REDIRECT_DATA=~/template_redirects/$DUMP_DATE.json

mkdir -p $DUMP_DIR || { echo Failed to create dump directory; exit -1; }

cd $HOME/enwikt-dump-rs;

cat "$@" | ~/bin/lua lua/add_template_redirects.lua "%s.cbor" $REDIRECT_DATA > $TEMPLATE_NAMES || { echo Failed to create template names file, $TEMPLATE_NAMES; exit -1; }

cd $DUMP_DIR;

$HOME/bin/wiktionary-data dump-parsed-templates \
	--input $PAGES_ARTICLES \
	--templates $TEMPLATE_NAMES \
    --namespaces main,reconstruction,appendix \
	--format cbor;
