# podman-ollama

The goal of podman-ollama is to make AI even more boring. It should set up a GPU if detected.

podman pulls the runtime environment.

ollama pulls the LLM.

## Install

At present this is tested on Linux, but we are open to macOS, Windows and other one-liners compatible with other OSes.

Install podman on your distro, on Fedora/CentOS Stream/RHEL this is:

```bash
dnf install podman
```

Install podman-ollama by running this one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/ericcurtin/podman-ollama/main/install.sh | sudo bash
```

## Usage

If podman-ollama is passed text it is a non-interactive tool:

```bash
$ podman-ollama "Write a git commit message for this diff: $(git diff)"
```

If podman-ollama is run without any arguments it is an interactive tool:

``` bash
$ podman-ollama
>>> Send a message (/? for help)
```

