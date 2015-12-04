#!/usr/bin/env bash
find . -iname \*.elm | entr npm run make
