#!/bin/sh

set -e

# Add default command if needed.

if [ "${1:0:1}" = '-' ]; then
    set -- /run.sh "$@"
fi

exec "$@"
