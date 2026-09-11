#!/usr/bin/env bash
set -Eeu

readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The image resolves the newest stable scala when it is built and records it
# in /versions.json, so the expected version is read from the image rather
# than written down here. Writing it down here would pin the image to a
# release chosen when someone last edited this file.
readonly VERSIONS=$(docker run --rm -i ${IMAGE_NAME} sh -c 'cat /versions.json')
readonly VERSION_REGEX='"scala":"([0-9.]+)"'
if [[ ! ${VERSIONS} =~ ${VERSION_REGEX} ]]; then
  echo "VERSION ERROR: /versions.json has no scala property"
  echo "VERSION   FILE: ${VERSIONS}"
  exit 42
fi
readonly EXPECTED="${BASH_REMATCH[1]}"

# Asks the installed compiler, so the gate fails if the number recorded at
# build time is not the scala the image can actually run.
readonly ACTUAL=$(docker run --rm -i ${IMAGE_NAME} sh -c 'scalac -version 2>&1')

if echo "${ACTUAL}" | grep -q "${EXPECTED}"; then
  echo "VERSION CONFIRMED as ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
