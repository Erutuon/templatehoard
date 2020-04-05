#! /usr/bin/env bash

cd ~/git/templatehoard-server
RUST_LOG=all ~/bin/server templatehoard >> ~/logs/server.out 2>> ~/logs/server.err
