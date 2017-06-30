#!/bin/sh

if [ "$1" == "" ]; then
    echo "fatal: no acl file provided"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "fatal: acl file '$1' does not exist or not a file"
    exit 2
fi

FILE=$1

/shield.sh $FILE 
while inotifywait -e modify $FILE; do
    /shield.sh $FILE 
done
