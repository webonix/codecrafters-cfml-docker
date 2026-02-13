#!/bin/sh
set -e

LUCLI_JAR="${LUCLI_JAR:-/opt/lucli.jar}"
cd "$(dirname "$0")/.."

# Parse -p "prompt" and set PROMPT for main.cfm; do not pass -p to LuCLI (it treats it as an option)
REMAINING=""
while [ $# -gt 0 ]; do
  if [ "$1" = "-p" ] && [ -n "$2" ]; then
    export PROMPT="$2"
    shift 2
  else
    REMAINING="${REMAINING:+$REMAINING }$1"
    shift
  fi
done
set -- $REMAINING

exec java -jar "$LUCLI_JAR" app/main.cfm "$@"
