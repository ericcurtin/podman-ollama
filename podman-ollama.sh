#/bin/bash

set -e -o pipefail

PRE=""

cleanup() {
  $PRE podman rm -f ollama
}

trap cleanup EXIT

ADD=
if [ -e "/dev/dri" ]; then
  ADD="--device /dev/dri"
fi

POST="latest"
if [ -e "/dev/kfd" ]; then
  ADD="$ADD --device /dev/kfd"
  POST="rocm"
fi

$PRE podman run -d $ADD --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama docker.io/ollama/ollama:$POST
if [ -n "$1" ]; then
  $PRE podman exec -it ollama ollama run llama2 "$1"
else
  $PRE podman exec -it ollama ollama run llama2
fi

