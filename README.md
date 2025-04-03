# fintc

fintc, short for **F**ile **INT**egrity **C**hecker, is a simple script that, as the name
implies, checks integrity of files.

Currently, there are two implementations: **Bash** and **Python**. The biggest
difference between them are that the Python version uses **SHA256**, instead of
**BLAKE3**, and has colored output.

## Usage

Firstly, get the scripts on your machine:

```sh
git clone https://github.com/nilhiu/fintc
```

For the Python version you will just need `python3` installed. For the Bash
version you will need `b3sum` installed.

By default, fintc saves its hashes in `/var/lib/fintc`. If you want to change
that behavior, set the `FINTC_HOME` environment variable to where you want
the hashes to be stored, like `$HOME/.fintc`.

Both implementations provide the same commands:

- `init`: initializes the hash(es) of the given file or directory.
- `verify`: verifies the hash(es) of the given file or directory.
- `update`: updates the hash(es) of the given file or directory.
- `delete`: deletes the hash(es) of the given file or directory.

The operations on directories happen recursively: starting at the given path,
it walks through the directory tree hashing any file it encounters.

So, to provide some examples: use `init` to initialize hashes

```sh
./fintc.sh init /var/log
# Or initialize a hash
./fintc.sh init /var/log/pacman.log
```

Use `verify` to verify that the files are unchanged

```sh
./fintc.sh verify /var/log
# You can also verify a singular file
./fintc.sh verify /var/log/pacman.log
```

Use `update` to update the hash of a file

```sh
# Either update every file in a directory...
./fintc.sh update /var/log
# ...Or a single one
./fintc.sh update /var/log/pacman.log
```

When you don't want to keep some hashes, use `delete`

```sh
./fintc.sh delete /var/log/pacman.log
# You can also delete hashes for every file under a directory
./fintc.sh delete /var/log
```

If you want to use the Python variant, just change `./fintc.sh` to
`python fintc.py`, or `python3 fintc.py`.

## Installing

### Linux/macOS

On Linux or macOS, you will have to copy one of the scripts into `/usr/bin/`,
or to `$HOME/.local/bin/` if you have it in your PATH. Also, don't forget to
add execution privileges to the script: `chmod u+x fintc.{sh,py}`.

If installing the Python script, you will need to add the following to the
top of the Python script:

```py
#!/usr/bin/env python3
```

You can also then rename the script to remove the `.sh` or `.py` file extension.

### Windows

On Windows, you will only be able to install the Python version, unless you're
using WSL. To install it, either move the Python script into a folder which is
already in your PATH, or add fintc's folder to your PATH.

Afterward, you will be able to run `fintc.py` anywhere in your terminal.

## Acknowledgements

The foundational idea and project structure for fintc is based on the challenge
outlined by roadmap.sh's
[File Integrity Checker](https://roadmap.sh/projects/file-integrity-checker).
This project serves as one, or two, possible implementations for it.
