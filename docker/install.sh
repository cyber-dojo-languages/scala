#!/bin/sh
set -e

# The bash shell is required by Scala utilities
apk add --no-cache bash

# Install build dependencies
apk add --no-cache --virtual=.dependencies tar wget

wget -O- "http://downloads.lightbend.com/scala/2.12.4/scala-2.12.4.tgz" \
    | tar xzf - -C /usr/local --strip-components=1

# Remove build dependencies
apk del --no-cache .dependencies
