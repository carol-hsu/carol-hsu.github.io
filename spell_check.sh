#!/usr/local/bin/bash

cat content/post/*.md | aspell list -t | sort -f | uniq > aspell-out | git diff aspell-out
