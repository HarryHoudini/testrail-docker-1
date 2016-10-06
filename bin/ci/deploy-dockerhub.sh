#!/bin/bash

# THIS IS MEANT TO BE RUN BY CI

set -e

# Usage: retry MAX CMD...
# Retry CMD up to MAX times. If it fails MAX times, returns failure.
# Example: retry 3 docker push "mozilla/testrail:$TAG"
function retry() {
    max=$1
    shift
    count=1
    until "$@"; do
        count=$((count + 1))
        if [[ $count -gt $max ]]; then
            return 1
        fi
        echo "$count / $max"
    done
    return 0
}

# configure docker creds
retry 3 docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

# docker tag and push git branch to dockerhub
if [ -n "$1" ]; then
    [ "$1" == master ] && TAG=latest || TAG="$1"
    docker tag testrail:build "mozilla/testrail:$TAG" ||
        (echo "Couldn't tag testrail:build as mozilla/testrail:$TAG" && false)
    retry 3 docker push "mozilla/testrail:$TAG" ||
        (echo "Couldn't push mozilla/testrail:$TAG" && false)
    echo "Pushed mozilla/testrail:$TAG"
fi
