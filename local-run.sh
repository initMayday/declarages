#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

eval $(luarocks path --tree=./deps --no-bin)
lua ./main.lua "$@"
