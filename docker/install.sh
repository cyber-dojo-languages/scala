#!/bin/sh -eu

# Installs the newest stable Scala 3 release on top of the JDK this image
# already has. The compiler is a JVM program, so the distribution is the
# whole of it: a launcher script and a jar.

apk add --update bash
apk add --virtual=build-dependencies curl wget ca-certificates

# github redirects the releases/latest URL to the tag of the newest release,
# so the version is read from where it is redirected to. That asks nothing of
# the API, which rate limits by IP and would make a build depend on how busy
# the runner's neighbours had been.
#
# curl reports the redirect target itself, so no header has to be parsed.
# busybox grep, which is the grep here, has no long options anyway.
readonly LATEST_URL=$(curl --silent --output /dev/null \
  --write-out '%{redirect_url}' \
  https://github.com/scala/scala3/releases/latest)
readonly SCALA_VERSION="${LATEST_URL##*/tag/}"

if [ -z "${SCALA_VERSION}" ]; then
  echo 'ERROR: could not resolve the newest stable scala release' >&2
  exit 1
fi

readonly ZIP="scala3-${SCALA_VERSION}.zip"
wget "https://github.com/scala/scala3/releases/download/${SCALA_VERSION}/${ZIP}"
unzip -q "${ZIP}" -d /tmp/scala3
mv "/tmp/scala3/scala3-${SCALA_VERSION}" "${SCALA_HOME}"

# The distribution's other launcher, scala, is scala-cli, which resolves
# dependencies over the network. A kata has no network, so a run reaching for
# it would stall rather than compile. Its jar is the larger part of this
# image, and it is removed in the same layer that unpacks it, since a later
# layer deleting a file does not make an image any smaller. Removing the
# launcher too leaves "scala: not found", which says what has happened;
# leaving it behind without its jar would not.
rm "${SCALA_HOME}/libexec/scala-cli.jar"
rm "${SCALA_HOME}/bin/scala" "${SCALA_HOME}/bin/scala.bat"
rm "${ZIP}"

# The standard library, which every compiled Scala program needs on its
# classpath to run. The distribution keeps it among the compiler's own
# dependencies, under a path naming the version; copying it here gives a test
# framework image, and the cyber-dojo.sh reading it, one stable place to name.
mkdir /scala
cp "${SCALA_HOME}/maven2/org/scala-lang/scala3-library_3/${SCALA_VERSION}/scala3-library_3-${SCALA_VERSION}.jar" /scala/
cp "${SCALA_HOME}/maven2/org/scala-lang/scala-library/${SCALA_VERSION}/scala-library-${SCALA_VERSION}.jar" /scala/

# Read by check_version.sh and by the images built on this one, so that all of
# them state the version this image holds rather than repeating a number
# written down somewhere else.
echo "{\"scala\":\"${SCALA_VERSION}\"}" > /versions.json

apk del build-dependencies
rm -rf /tmp/* /var/cache/apk/*
