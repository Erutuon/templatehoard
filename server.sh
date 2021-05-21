#! /usr/bin/env bash

DUMP_DATE=20201120
RUST_LOG=all ~/bin/server --cbor ~/www/static/dump/$DUMP_DATE --redirects ~/template_redirects/$DUMP_DATE.json --static ~/git/templatehoard-server/static --port $PORT >> ~/logs/server.out 2>> ~/logs/server.err
