#!/bin/bash
grim -g "$(slurp)" - | swappy -f - && wl-copy < "$(find ~/Pictures -type f -name '*.png' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2)"
