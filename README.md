
# R.I.S.K.S

This is a fork of the repository for the scripts used in [R.I.S.K.S.](https://19hundreds.github.io/risks-workflow/)

## Added functionality

Note that this fork has changed the shebang line to `#!/usr/bin/env zsh`, therefore requiring `zsh` to work.
Also, in the `risq` script, the `mpw` command has been changed for its new brother `spectre`. Works the same.

### Commands

Given the cumbersome process exposed on the [R.I.S.K.S.](https://19hundreds.github.io/risks-workflow/) website, for
creating the various identities and associated datastores, this fork has bundled _most_ of the functionality into new
commands:

* `risks new`:
* `backup`      - Create a new backup of the current data, including currently active identities
* `tomb`        - Create a new tomb for a given identity, with a given name
* `identity`    - All-in-one command to create an identity GPG/SSH/pass and automatic backup of it.

* `risks format`:
* `sdcard <path>`   - Overwrites, cleans, cryptsetups and filesytem formats an SDCARD to be used as hush
* `backup <path>`   - Overwrites, cleans, cryptsetups and filesytem formats a USB drive to be used as backup 

* `risks slam`: Similar to `tomb slam`, closes all active identities and unmounts the hush partition

Note that all new commands require different positional arguments, which are documented in usage.

### Completions

* `_risks` completion file:
* Completion for all subcommands
* File completion for device paths (eg. `/dev/xvdi`) needed by `format backup/sdcard` or `new identity` commands 
* Detailed completion messaging for commands like `risks new identity`, which require several arguments.
* Identity name completion, based on the directory where convience backup (public keys) are stored.
* Automatic completion of `hush` for `risks ro|rw|mount|umount` commands

* `_risq` completion file:
* Adds completion bridging for pass subcommands

## Install one-liners

For `_risks` in `VaultVM` (used as standalone here, adapt the paths if used as AppVM):

```bash
# Command script
sudo cp QubesIncoming/joe-dvq/risks /usr/local/bin/risks && sudo chmod +x /usr/local/bin/risks
# Completions
sudo mkdir -p /usr/local/share/zsh/site-functions
sudo cp QubesIncoming/joe-dvq/_risks /usr/local/share/zsh/site-functions/_risks
```

For `risq` script in AppVM (eg. joe-dvq):

```bash
# Command script
sudo cp QubesIncoming/joe-dvq/risq /usr/local/bin/risq && sudo chmod +x /usr/local/bin/risq
# Completions
sudo mkdir -p /usr/local/share/zsh/site-functions
sudo cp QubesIncoming/joe-dvq/_risq /usr/local/share/zsh/site-functions/_risq
```

