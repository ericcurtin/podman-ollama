#!/bin/bash

set -e -o pipefail

available() {
  command -v $1 >/dev/null
}

install_dnf() {
  if sed "s/\s/\n/g" /proc/cmdline | grep -q -m1 "^ostree="; then
    RPM_OSTREE="true"
    if rpm-ostree install podman 2>&1 | grep -v "already provided"; then
      echo 'Reboot to complete podman install.'
    fi
  elif available dnf; then
    dnf -y install podman
  elif available yum; then
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

check_gpu() {
  if available "lspci" && lspci -d '10de:' | grep -q 'NVIDIA'; then
    NVIDIA="true"
  fi

  if available "lshw" && $SUDO lshw -c display -numeric | grep -q 'vendor: .* \[10DE\]'; then
    NVIDIA="true"
  fi
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 0
fi

. /etc/os-release

RPM_OSTREE="false"
case $ID in
  centos|rhel|autosd|rocky|fedora|fedora-asahi-remix|amzn) install_dnf ;;
  debian|ubuntu) install_apt ;;
esac

NVIDIA="false"
check_gpu

if ! $NVIDIA && ! $RPM_OSTREE; then
  # This is a downstream version of the ollama install script, until podman
  # related patches get reviewed:
  # https://github.com/ollama/ollama/pulls/ericcurtin
  URL="raw.githubusercontent.com/ericcurtin/podman-ollama/s/ollama-install.sh"
  curl -fsSL "https://$URL" | OLLAMA_CONTAINER_MANAGER="podman" sh
fi

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

