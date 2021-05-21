#! /usr/bin/env bash

cd ~/git/templatehoard-server
RUSTFLAGS='--emit=asm' ~/.cargo/bin/cargo build --release
