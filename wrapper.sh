#!/usr/bin/env bash

eval $(luarocks path --tree=/usr/share/declarages/deps --no-bin)
lua /usr/share/declarages/main.lua "$@"
