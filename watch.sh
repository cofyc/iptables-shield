#!/bin/bash

if [ "$1" == "" ]; then
    echo "fatal: no acl file provided"
    exit 1
fi

if [ ! -e "$1" ]; then
    echo "fatal: acl file '$1' does not exist"
    exit 2
fi


file=$1

# It's too complicated to use inotify on all situations (especially with symbolic links).
# So we simply check acl contents periodically.
CACHE=/tmp/cache.acl
CACHE_TMP=/tmp/cache.acl.tmp
while true; do
    if [ -f "$file" ]; then
        if ! diff -u ${CACHE} $file >/dev/null 2>&1; then
            cp $file ${CACHE}
            /shield.sh ${CACHE}
        fi
    elif [ -d "$file" ]; then
        cd $file
        cat $(ls .) > ${CACHE_TMP}
        if ! diff -u ${CACHE} ${CACHE_TMP} >/dev/null 2>&1; then
            mv ${CACHE_TMP} ${CACHE}
            /shield.sh ${CACHE}
        fi
    else
        echo "unsupported type '$file'"
        exit 1
    fi
    sleep 1
done
