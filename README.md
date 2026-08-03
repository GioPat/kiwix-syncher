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

## Serving the ZIMs with kiwix-serve

`kiwix-serve` can be handed ZIM files directly, but that list is fixed when the
process starts — and this tool exists to change that list. Every rotation would
need a server restart.

An XML library solves it, because a library file can change while the server is
running:

```sh
kiwix-serve --library /library/zims.xml -M -p 8080
```

`-M` (`--monitorLibrary`) reloads on change; `SIGHUP` forces a reload with or
without it.

To keep the library in step, set `global.on_sync_complete`. It runs after any
cycle that added or replaced a ZIM, and is skipped on idle cycles:

```
on_sync_complete: "rm -f /library/zims.xml && kiwix-manage /library/zims.xml add /zims/*.zim";
```

Two things to get right:

- **Rebuild from empty.** `kiwix-manage add` appends, so without the `rm` the
  library keeps entries for the ZIMs the cycle just deleted.
- **One library file per syncher instance.** Several instances sharing a library
  would race on it. `kiwix-serve` accepts a semicolon separated list, so give
  each its own: `kiwix-serve --library "history.xml;maps.xml" -M`.

`kiwix-manage` ships in the container image. If you run the syncher outside a
container you need it on `PATH` yourself — it is part of
[kiwix-tools](https://download.kiwix.org/release/kiwix-tools/).

The hook is a plain shell command, so it is equally useful for notifications,
backups, or signalling a server you manage yourself.

## Container

### Use the pre built image

`docker run --volume config.cfg:/home/kiwix-monitor/config.cfg --volume zims-docker:/home/kiwix-monitor/zims giopat15/kiwix-syncher:0.1.0`

### Build it your own

First build it using linux (WSL2 on windows) using the commands above and then run the following:

`docker build -t kiwix-syncer .`

Make sure to mount the following volumes (Docker, Podman or Kubernetes):

- zims directory (check also the config `global.watching_directory`)
- `config.cfg` in `/home/kiwix-syncher/config.cfg`

## Current limitations and potential improvements

- Does not support zim deletion if you remove from the watch list.
- Does not spawn thread to monitor ZIM so the cooldown starts after the last ZIM is downloaded.
- Downloads are not resumable: a failed transfer is discarded and retried whole
  on the next cycle. It is no longer destructive, though — the ZIM already on
  disk is kept until the replacement is complete.
