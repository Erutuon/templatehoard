#! /usr/bin/env bash

# /public/dumps/public/enwiktionary/*1220/*redirect.sql*

DATE=20200101
WIKI=enwiktionary
DUMP_DIR=/public/dumps/public/

cd $HOME/enwikt-dump-rs

get_decompressed() {
    if (( $# != 1 )); then
        echo 'Wrong number of arguments.'
        return 1
    fi
    
    LOCALNAME=$DATE-$1
    
    if [[ ! -f $LOCALNAME ]]; then
        FILEPATH=$DUMP_DIR/$WIKI/$DATE/$WIKI-$DATE-$1.gz
        if [[ ! -f $FILEPATH ]]; then
            echo $FILEPATH not found.
            return 1
        fi
        gunzip -c $FILEPATH > $LOCALNAME
        ln -sf $LOCALNAME $1
    fi
    
    return 0
}

if ! ( get_decompressed page.sql && get_decompressed redirect.sql ); then
    echo Failed to get decompressed files.
    exit -1;
fi

$HOME/bin/lua -ltemplate_redirects -lcjson -e 'print(cjson.encode(template_redirects))' > $HOME/enwikt-dump-rs/template_redirects.json
