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

cleanup() {
  rm -rf "$TMP" &
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
if [ -z "$1" ]; then
  TMP="$(mktemp -d)"
  trap cleanup EXIT
  FROM="$TMP/podman-ollama"
  URL="raw.githubusercontent.com/ericcurtin/podman-ollama/s/podman-ollama"
  curl -fsSL -o "$FROM" "https://$URL"
fi

install -m755 "$FROM" $BINDIR/podman-ollama

