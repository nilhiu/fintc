import sys
import os


FINTC_HOME = os.getenv("FINTC_HOME", "/var/lib/fintc")
FINTC_HASHES_FILE = os.path.join(FINTC_HOME, "hashes")


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


def main(cmd, path):
    match cmd.lower():
        case "init":
            print("init command detected")
        case "verify":
            print("verify command detected")
        case "update":
            print("update command detected")
        case "delete":
            print("delete command detected")
        case _:
            print(f"[error]: unknown command '{cmd}'")
            print_help()
            sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        if len(sys.argv) == 2 and sys.argv[1].lower() == "help":
            print_help()
            sys.exit(0)

        print("[error]: command or file/directory wasn't provided")
        sys.exit(usage_str())

    main(sys.argv[1], sys.argv[2])
