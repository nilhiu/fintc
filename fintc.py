import sys
import os
from hashlib import sha256


#: The home directory for fintc. If `FINTC_HOME` environment variable isn't set
#: `/var/lib/fintc` is used.
FINTC_HOME = os.getenv("FINTC_HOME", "/var/lib/fintc")

#: The file path where fintc's hashes are stored.
FINTC_HASHES_FILE = os.path.join(FINTC_HOME, "hashes")

try:
    with open(FINTC_HASHES_FILE, "r") as f:
        #: The list of hashes read from `FINTC_HASHES_FILE`.
        FINTC_HASHES = f.read().splitlines()
except Exception:
    #: Defaults to an empty list if `FINTC_HASHES_FILE` can't be read.
    FINTC_HASHES = []

#: Are ANSI escape codes supported.
ANSI_SUPPORTED = sys.stdout.isatty() and os.getenv("TERM", "") != "dumb"

if ANSI_SUPPORTED:
    RED = "\033[91;1m"
    CYAN = "\033[96;1m"
    RESET = "\033[0m"
else:
    RED = CYAN = RESET = ""


def usage_str():
    return f"{CYAN}Usage:{RESET} {sys.argv[0]} <command> <path>"


def print_help():
    print(usage_str())
    print(
        rf"""
{CYAN}Commands:{RESET}
    {CYAN}help{RESET}   - displays this help message
    {CYAN}init{RESET}   - initialize integrity hash(es) for the given path
    {CYAN}verify{RESET} - verify integrity of the given path
    {CYAN}update{RESET} - update the hash(es) of the given path
    {CYAN}delete{RESET} - delete the hash(es) of the given path"""
    )


def print_error(msg):
    print(f"{RED}[error]:{RESET} {msg}")


def print_info(msg):
    print(f"{CYAN}[info]:{RESET} {msg}")


def apply_on_dir_recursively(path, func):
    """
    Apply the provided function on the given directory recusively.

    Args:
        path (str): path to a directory.
        func (Callable[[str],None]): function to apply on `path`.
    """
    for root, _, files in os.walk(path):
        for f in files:
            func(os.path.realpath(os.path.join(root, f)))


def apply_on_path(path, func):
    """
    Apply the provided function on the given path.

    Args:
        path (str): path to a file or directory.
        func (Callable[[str],None]): function to apply on `path`.

    Raises:
        Exception: if `path` is neither a file or directory.
    """
    if os.path.isdir(path):
        apply_on_dir_recursively(path, func)
    elif os.path.isfile(path):
        func(os.path.realpath(path))
    else:
        raise Exception(f"given path '{path}' isn't file or directory")


def is_file_hashed(path):
    """
    Check if the given file is hashed.

    Args:
        path (str): path to a file.
    """
    for h in FINTC_HASHES:
        if h.endswith(path):
            return True
    return False


def write_hashes_file():
    """
    Write the hashes saved in `FINTC_HASHES` to `FINTIC_HASHES_FILE`.
    """
    with open(FINTC_HASHES_FILE, "w") as f:
        f.write("\n".join(FINTC_HASHES))


def hash_file(path):
    """
    Save the hash of the given file.

    Args:
        path (str): path to a file.
    """
    if is_file_hashed(path):
        print_error(f"file '{path}' is already hashed")
        return

    with open(path, "rb") as f:
        content = f.read()
        hash = sha256(content).hexdigest()
        FINTC_HASHES.append(f"{hash}\t{path}")
        print_info(f"file '{path}' hashed ({hash[:8]})")


def verify_file(path):
    """
    Verify the saved hash of the given file.

    Args:
        path (str): path to a file.
    """
    for h in FINTC_HASHES:
        if h.endswith(path):
            with open(path, "rb") as f:
                content = f.read()
                hash = sha256(content).hexdigest()
                if not h.startswith(hash):
                    print_error(f"file '{path}' hash mismatch")
                return

    print_error(f"file '{path}' is not hashed")


def update_file_hash(path):
    """
    Update the saved hash of the given file.

    Args:
        path (str): path to a file.
    """
    for i, h in enumerate(FINTC_HASHES):
        if h.endswith(path):
            with open(path, "rb") as f:
                content = f.read()
                hash = sha256(content).hexdigest()
                if h.startswith(hash):
                    print_info(f"file '{path}' hash unchanged")
                    return

                FINTC_HASHES[i] = f"{hash}\t{path}"
                print_info(f"file '{path}' hash updated ({hash[:8]})")

    print_error(f"file '{path}' is not hashed")


def delete_file_hash(path):
    """
    Delete the saved hash of the given file.

    Args:
        path (str): path to a file.
    """
    for i, h in enumerate(FINTC_HASHES):
        if h.endswith(path):
            FINTC_HASHES.pop(i)
            print_info(f"file '{path}' hash deleted")
            return

    print_error(f"file '{path}' is not hashed")


def main(cmd, path):
    """
    Main method.

    Args:
        cmd (str): command to run.
        path (str): path to a file or directory to run the command on.
    """
    match cmd.lower():
        case "init":
            apply_on_path(path, hash_file)
        case "verify":
            apply_on_path(path, verify_file)
            return  # skip hashes file write
        case "update":
            apply_on_path(path, update_file_hash)
        case "delete":
            apply_on_path(path, delete_file_hash)
        case "help":
            print_help()
            return
        case _:
            print_error(f"unknown command '{cmd}'")
            print_help()
            sys.exit(1)

    write_hashes_file()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        if len(sys.argv) == 2 and sys.argv[1].lower() == "help":
            print_help()
            sys.exit(0)

        print_error("command or file/directory wasn't provided")
        sys.exit(usage_str())

    main(sys.argv[1], sys.argv[2])
