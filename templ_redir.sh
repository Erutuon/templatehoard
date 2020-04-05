#! /usr/bin/env bash

. ~/git/common.sh

get_decompressed() {
    if (( $# != 1 )); then
        echo 'Wrong number of arguments.'
        return 1
    fi
    
    LOCAL_NAME=$DUMP_DATE-$1
    
    if [[ ! -f $LOCAL_NAME ]]; then
        FILEPATH=$DUMP_PREFIX-$1.gz
        if [[ ! -f $FILEPATH ]]; then
            echo $FILEPATH not found.
            return 1
        fi
        gunzip -c $FILEPATH > $LOCAL_NAME
        ln -sf $LOCAL_NAME $1
    fi
    
    return 0
}

cd ~/enwikt-dump-rs

if ! ( get_decompressed page.sql && get_decompressed redirect.sql ); then
    echo Failed to get decompressed files.
    exit -1;
fi

OUT_DIR=~/template_redirects
OUT_FILE=$OUT_DIR/$DUMP_DATE.json
mkdir -p $OUT_DIR && ~/bin/lua -ltemplate_redirects -lcjson -e 'print(cjson.encode(template_redirects))' > $OUT_FILE
