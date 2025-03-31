#!/usr/bin/env bash

set -euo pipefail

# FINTC_HOME is where all fintc files will reside (including file hashes)
FINTC_HOME=${FINTC_HOME:-"/var/lib/fintc"}
FINTC_HASHES=$(if [[ -f "$FINTC_HOME/hashes" ]]; then cat "$FINTC_HOME/hashes"; else echo ""; fi)

# print_usage - prints the usage text of fintc
print_usage() {
    cat << EOF
Usage: fintc <command> <file/dir>

Commands:
    init   - initialize the given file/directory's integrity hash
    verify  - verify integrity of the given file/directory
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

# hash_file - hashes a file with BLAKE3 and places it into fintc's hashes
#
# Arguments:
#   file: the file you want to hash
hash_file() {
    local file=$1
    local hash=$(b3sum $file)

    while read line; do
        if [[ $(echo $line | awk '{ print $2 }') = $file ]]; then
            echo "[error]: file '$file' is already hashed."
            if [[ "${line%% *}" != "${hash%% *}" ]]; then
                echo "[info]: hash mismatch. not updating..."
            fi
            return
        fi
    done <<< "$FINTC_HASHES"

    echo "[info]: file '$file' hashed"
    echo "$hash" >> "$FINTC_HOME/hashes"
}

# init_cmd - grabs hashes of the file(s) given
#
# Arguments:
#   file/dir: the file or directory to hash
init_cmd() {
    if [[ -d $1 ]]; then
        local dir=$1
        local files=$(find $dir -type f -exec realpath {} \;)
        for item in $files; do
            if [[ -f $item ]]; then
                hash_file $item
            fi
        done
    elif [[ -f $1 ]]; then
        local file=$(realpath $1)
        hash_file $file
    fi
}

ensure_dep b3sum

if [[ $# -ne 2 ]]; then
    print_usage
    exit 1
fi

mkdir -p "$FINTC_HOME"
touch "$FINTC_HOME/hashes"

case ${1,,} in
    init)
        init_cmd $2
        ;;
    verify)
        echo "verify command detected"
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
