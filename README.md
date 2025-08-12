# Kiwix ZIM Syncer

This software is intended to sync ZIM files from the remote ZIM repository. It supports a simple pattern system that allows to select the interesting ZIM files, then automatically keeps the most recent ones.

## Quickstart

### Requirements

It requires a Jai compiler > `0.2.016`

### Build

Build it: `jai build.jai - -very-release`

### Run

Setup a config.cfg: You can check an example in the `config.example.cfg` file for which you can set the cooldown period, the watched dir and the patterns.

And then run it.

## Container

First build it using linux (WSL2 on windows) using the commands above and then run the following:

`docker build -t kiwix-syncer .`

Make sure to mount the following volumes (Docker, Podman or Kubernetes):

- zims directory (check also the config `global.watching_directory`)
- `config.cfg` in `/home/kiwix-syncher/config.cfg`

## Current limitations and potential improvements

- Does not support zim deletion if you remove from the watch list.
- Does not spawn thread to monitor ZIM so the cooldown starts after the last ZIM is downloaded.
