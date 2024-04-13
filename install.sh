#!/bin/bash

set -e -o pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 0
fi

for BINDIR in /usr/local/bin /usr/bin /bin; do
  echo $PATH | grep -q $BINDIR && break || continue
done

FROM="podman-ollama"
DELETE="false"
if [ -z "$1" ]; then
  DELETE="true"
  TEMP="$(mktemp -d)"
  FROM="$TEMP/podman-ollama"
  curl -fsSL -o "$FROM" https://raw.githubusercontent.com/ericcurtin/podman-ollama/main/podman-ollama
fi

install -m755 "$FROM" $BINDIR/podman-ollama

if $DELETE; then
  rm -rf "$TEMP"
fi

