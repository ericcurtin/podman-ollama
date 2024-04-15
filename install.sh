#!/bin/bash

set -e -o pipefail

install_dnf() {
  if sed "s/\s/\n/g" /proc/cmdline | grep -q -m1 "^ostree="; then
    if rpm-ostree install podman 2>&1 | grep -v "already provided"; then
      echo 'Reboot to complete podman driver install.'
    fi
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

# This is a downstream version of the ollama install script, until podman
# related patches get reviewed
URL="raw.githubusercontent.com/ericcurtin/podman-ollama/s/ollama-install.sh"
curl -fsSL "https://$URL" | OLLAMA_CONTAINER_MANAGER="podman" sh

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

