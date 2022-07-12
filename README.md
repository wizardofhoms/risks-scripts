
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

### Other enhancements

* The SSH tomb also comes with a special `ssh-add` executable script, so that if you get to have multiple SSH keypairs
in your `~/.ssh/` directory, all of them will be added when the identity is opened.

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

## New workflow

### General workflow

In order to perform everything from scratch, the process will consist in these commands:
* `risks format sdcard /dev/xvdi` to prepare the hush drive
* `risks format backup /dev/xvdj` to prepare the backup

Then, to generate a full identity
* `risks new identity "John Doe" john.doe@proton.me "1 year" /dev/xvdj` where "1 year" is the expiry of the GPG subkeys,
and "/dev/xvdj" is the path to the -unmounted but attached- backup drive.
Note that this will thus automatically perform a backup of the newly generated identity, as well as of the hush.img

Finally, to open the complete identity and its associated data stores (GPG/SSH/pass):
* `risks open identity John_Doe` (the identities are autocompleted when completion scripts are installed)

### Command: risks new identity

* The process is quite long, so don't panic ! It will end up at some point.
* You must NOT mount the hush partition when generating an identity. The script will do it.
* The GPG passphrase is generated and stored into a script variable, so you don't have access to it.
You only have to input the SSL key passphrase, at various steps. 
* Since the GPG passphrase is generated in a variable, the script also takes care of copying it at
various points in the clipboard. So when you are prompted with an interactive menu to enter it 
(when creating the tombs, for instance), just paste it as you would do normally.
* You also have, naturally, to input the hush partition and backup cryptsetup passphrases at some point.

### Command: risks new backup/tomb
* These commands are simpler, and the process is shorter. You still have to enter your passphrase at some point.

