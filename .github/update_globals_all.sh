#!/usr/bin/env bash
find src -name "*.lua" -print0 | xargs -0 .github/update_globals.sh

