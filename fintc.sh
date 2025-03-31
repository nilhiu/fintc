#!/usr/bin/env bash

set -euo pipefail

# FINTC_HOME is where all fintc files will reside (including file hashes)
FINTC_HOME=${FINTC_HOME:-"/var/lib/fintc"}

# print_usage - prints the usage text of fintc
print_usage() {
    cat << EOF
Usage: fintc <command> <file/dir>

Commands:
    init   - initialize the given file/directory's integrity hash
    check  - check integrity of the given file/directory
    update - update the hash(es) of the given file/directory
    delete - delete the hash(es) of the given file/directory
EOF
}

# ensure_dep - checks if a required dependancy is installed
#
# Arguments:
#   dependancy: the name of the dependancy to check
ensure_dep() {
    if ! command -v $1 &> /dev/null; then
        echo "[fatal]: required dependancy '$1' isn't installed."
        exit 1
    fi
}

ensure_dep b3sum

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

case ${1,,} in
    init)
        echo "init command detected"
        ;;
    check)
        echo "check command detected"
        ;;
    update)
        echo "update command detected"
        ;;
    delete)
        echo "delete command detected"
        ;;
    *)
        echo "[error]: fintc command not recognized"
        print_usage
        exit 1
        ;;
esac
