#!/bin/sh

STARTPWD="$(pwd)"
cd -- "$(dirname -- "$0")" || exit 1
BASEDIR="$(pwd)"
cd -- "$STARTPWD"

PATAGREP_DIR="$BASEDIR"
. "$PATAGREP_DIR/patagrep.lib.sh"
patagrep "$@";
