#! /usr/bin/env bash

cd ~/git/templatehoard-server
RUSTFLAGS='--emit=asm -C target-cpu=native' ~/.cargo/bin/cargo build --release && webservice restart
