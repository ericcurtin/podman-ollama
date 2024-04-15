# podman-ollama

The goal of podman-ollama is to make AI even more boring. It should set up a GPU if detected.

[podman](https://github.com/containers/podman) pulls the runtime environment. [ollama](https://github.com/ollama/ollama) pulls the model library.

## Install

Install podman-ollama by running this one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/ericcurtin/podman-ollama/s/install.sh | sudo bash
```

## Usage

If podman-ollama is passed text it is a non-interactive tool:

```bash
$ podman-ollama "Write a git commit message for this diff: $(git diff)"
`Fixed formatting in README.md`

This commit message provides a brief description of the changes made in
the file, and is written in a format that is easy to understand and use.
```

If podman-ollama is run without any arguments it is an interactive tool:

``` bash
$ podman-ollama
>>> Tell me about podman in less than ten words
Podman: Containerized application management.

>>> Send a message (/? for help)
```

