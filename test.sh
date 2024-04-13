#!/bin/bash

set -ex -o pipefail

if [ -n "$GITHUB_SHA" ]; then
  COMMIT="$(git show $GITHUB_SHA)"
else
  COMMIT="$(git show HEAD)"
fi

./podman-ollama "Review this change, point out any issues: $COMMIT"

