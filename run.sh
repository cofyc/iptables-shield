#!/bin/sh

if [ "$1" == "" ]; then
    echo "fatal: no acl file provided"
    exit 1
fi

if [ ! -e "$1" ]; then
    echo "fatal: acl file '$1' does not exist"
    exit 2
fi

function run() {
    local file=$1
    if [ -f "$file" ]; then
        /shield.sh $file
    elif [ -d "$file" ]; then
        cd $file
        ls . | sort | xargs -r cat | /shield.sh
    else
        echo "unsupported type '$file'"
        exit 1
    fi
}

run $1
inotifywait -m -e modify,create,delete $1 2>/dev/null | while read -r line; do
    echo "run.sh: $line"
    run $1
done
