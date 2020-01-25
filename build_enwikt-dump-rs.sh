#! /usr/bin/env bash

cd enwikt-dump-rs
RUSTFLAGS='--emit=asm -C target-cpu=native' $HOME/.cargo/bin/cargo build --release

