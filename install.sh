#!/bin/bash

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

lshw_display() {
  $SUDO lshw -c display -numeric
}

check_gpu() {
  if available "lspci" && lspci -d '10de:' | grep -q 'NVIDIA'; then
    NVIDIA="true"
  elif available "lshw" && lshw_display | grep -q 'vendor: .* \[10DE\]'; then
    NVIDIA="true"
  fi
}

error() {
  echo "ERROR $*"
  exit 1
}

set -e -o pipefail

if [ "$(uname -s)" != "Linux" ]; then
  error 'This script is intended to run on Linux only.'
fi

if [ "$EUID" -ne 0 ]; then
  for BINDIR in $HOME/bin $HOME/.local/bin $HOME/bin; do
    echo $PATH | grep -q $BINDIR && break || continue
  done

  echo "rootless install, will install podman-ollama only, installing in: $BINDIR"
fi

. /etc/os-release

if [ "$EUID" -eq 0 ]; then
  RPM_OSTREE="false"
  case $ID in
    centos|rhel|autosd|rocky|fedora|fedora-asahi-remix|amzn) install_dnf ;;
    debian|ubuntu) install_apt ;;
  esac
fi

NVIDIA="false"
check_gpu

if [ "$EUID" -eq 0 ] && ! $RPM_OSTREE; then
  # This is a downstream version of the ollama install script, until podman
  # related patches get reviewed:
  # https://github.com/ollama/ollama/pulls/ericcurtin
  URL="raw.githubusercontent.com/ericcurtin/podman-ollama/s/ollama-install.sh"
  curl -fsSL "https://$URL" | OLLAMA_CONTAINER_MANAGER="podman" sh
fi

if [ -z "$BINDIR" ]; then
  for BINDIR in /usr/local/bin /usr/bin /bin; do
    echo $PATH | grep -q $BINDIR && break || continue
  done
fi

FROM="podman-ollama"
FROM_COMPLETE="podman-ollama-complete"
TO="$BINDIR/$FROM"
TO_COMPLETE="/etc/bash_completion.d/$FROM_COMPLETE"
if [ -z "$1" ]; then
  TMP="$(mktemp -d)"
  trap cleanup EXIT
  URL="raw.githubusercontent.com/ericcurtin/podman-ollama/s/$FROM"
  URL_COMPLETE="raw.githubusercontent.com/ericcurtin/podman-ollama/s/$FROM_COMPLETE"
  FROM="$TMP/$FROM"
  FROM_COMPLETE="$TMP/$FROM_COMPLETE"
  curl -fsSL -o "$FROM" "https://$URL"
  curl -fsSL -o "$FROM_COMPLETE" "https://$URL_COMPLETE"
fi

install -D -m755 "$FROM" "$TO"
install -D -m644 "$FROM_COMPLETE" "$TO_COMPLETE" || true

if [ "$EUID" -eq 0 ] && $RPM_OSTREE; then
  echo "rpm-ostree installs are not fully automated for NVIDIA GPUs, if using NVIDIA refer to:"
  echo
  echo "  https://raw.githubusercontent.com/ericcurtin/podman-ollama/main/ollama-install.sh"
  echo
  echo "and ensure packages are installed for:"
  echo
  echo "  nvidia-container-toolkit"
  echo "  nvidia-driver-latest-dkms"
  echo "  cuda-drivers"
  echo "  kernel-devel"
  echo "  kernel-headers"
  echo
  echo "and reboot"
fi

