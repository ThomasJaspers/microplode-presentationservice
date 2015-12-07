#!/usr/bin/env bash
find elm -iname \*.elm | entr npm run make
