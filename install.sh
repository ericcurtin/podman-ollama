#!/bin/bash

set -e -o pipefail

install_dnf() {
  if grep -q ostree= /proc/cmdline; then
    rpm-ostree install podman
  elif command -v dnf > /dev/null; then
    dnf -y install podman
  elif command -v yum > /dev/null; then
    yum -y install podman
  fi
}

install_apt() {
  DEBIAN_FRONTEND=noninteractive apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get -y install podman -q
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 0
fi

. /etc/os-release

case $ID in
  centos|rhel|rocky|fedora|amzn) install_dnf ;;
  debian|ubuntu) install_apt ;;
esac

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

