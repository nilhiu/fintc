import sys
import os
from hashlib import sha256


FINTC_HOME = os.getenv("FINTC_HOME", "/var/lib/fintc")
FINTC_HASHES_FILE = os.path.join(FINTC_HOME, "hashes")

try:
    with open(FINTC_HASHES_FILE, "r") as f:
        FINTC_HASHES = f.read().splitlines()
except Exception:
    FINTC_HASHES = []


def usage_str():
    return f"Usage: {sys.argv[0]} <command> <file/dir>"


def print_help():
    print(usage_str())
    print(
        r"""
Commands:
    help   - displays this help message
    init   - initialize the given file/directory's integrity hash(es)
    verify - verify integrity of the given file/directory
    update - update the hash(es) of the given file/directory
    delete - delete the hash(es) of the given file/directory"""
    )


def apply_on_dir_recursivly(path, func):
    for root, _, files in os.walk(path):
        for f in files:
            func(os.path.realpath(os.path.join(root, f)))


def apply_on_path(path, func):
    if os.path.isdir(path):
        apply_on_dir_recursivly(path, func)
    elif os.path.isfile(path):
        func(os.path.realpath(path))
    else:
        raise Exception(f"given path '{path}' isn't file or directory")


def is_file_hashed(path):
    for h in FINTC_HASHES:
        if h.endswith(path):
            return True
    return False


def write_hashes_file():
    with open(FINTC_HASHES_FILE, "w") as f:
        f.write("\n".join(FINTC_HASHES))


def hash_file(path):
    if is_file_hashed(path):
        print(f"[error]: file '{path}' is already hashed")
        return

    with open(path, "rb") as f:
        content = f.read()
        hash = sha256(content).hexdigest()
        FINTC_HASHES.append(f"{hash}\t{path}")
        print(f"[info]: file '{path}' hashed ({hash[:8]})")


def verify_file(path):
    for h in FINTC_HASHES:
        if h.endswith(path):
            with open(path, "rb") as f:
                content = f.read()
                hash = sha256(content).hexdigest()
                if not h.startswith(hash):
                    print(f"[error]: file '{path}' hash mismatch")
                return

    print(f"[error]: file '{path}' is not hashed")


def update_file_hash(path):
    for i, h in enumerate(FINTC_HASHES):
        if h.endswith(path):
            with open(path, "rb") as f:
                content = f.read()
                hash = sha256(content).hexdigest()
                if h.startswith(hash):
                    print(f"[info]: file '{path}' hash unchanged")
                    return

                FINTC_HASHES[i] = f"{hash}\t{path}"
                print(f"[info]: file '{path}' hash updated ({hash[:8]})")

    print(f"[error]: file '{path}' is not hashed")


def main(cmd, path):
    match cmd.lower():
        case "init":
            apply_on_path(path, hash_file)
        case "verify":
            apply_on_path(path, verify_file)
            return  # skip hashes file write
        case "update":
            apply_on_path(path, update_file_hash)
        case "delete":
            print("delete command detected")
        case _:
            print(f"[error]: unknown command '{cmd}'")
            print_help()
            sys.exit(1)

    write_hashes_file()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        if len(sys.argv) == 2 and sys.argv[1].lower() == "help":
            print_help()
            sys.exit(0)

        print("[error]: command or file/directory wasn't provided")
        sys.exit(usage_str())

    main(sys.argv[1], sys.argv[2])
