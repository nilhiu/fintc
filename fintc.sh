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

# print_fatal - prints a fatal message and exits
#
# Arguments:
#   message: the message to print
print_fatal() {
    echo "[fatal]: $1"
    exit 1
}

# print_error - prints a error message
#
# Arguments:
#   message: the message to print
print_error() {
    echo "[error]: $1"
}

# print_info - prints a info message
#
# Arguments:
#   message: the message to print
print_info() {
    echo "[info]: $1"
}

# ensure_dep - checks if a required dependancy is installed
#
# Arguments:
#   dependancy: the name of the dependancy to check
ensure_dep() {
    if ! command -v $1 &> /dev/null; then
        print_fatal "required dependancy '$1' isn't installed."
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
        if [[ ${line##* } = $file ]]; then
            print_error "file '$file' is already hashed."
            if [[ "${line%% *}" != "${hash%% *}" ]]; then
                print_info "hash mismatch. not updating..."
            fi
            return
        fi
    done <<< "$FINTC_HASHES"

    print_info "file '$file' hashed"
    echo "$hash" >> "$FINTC_HOME/hashes"
}

# verify_file - verifies the given files hash with the saved one
#
# Arguments:
#   file: the file to verify
verify_file() {
    local file=$1
    local hash=$(b3sum $file)

    while read line; do
        if [[ "${line##* }" = "$file" ]]; then
            if [[ "${line%% *}" != "${hash%% *}" ]]; then
                print_error "file '$file' hash mismatch."
            fi
            return
        fi
    done <<< "$FINTC_HASHES"

    print_error "file '$file' not hashed"
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

# verify_cmd - corresponds to the `fintc verify` command
#
# Arguments:
#   file/dir: the file or directory to run the command on
verify_cmd() {
    if [[ -d $1 ]]; then
        local dir=$1
        local files=$(find $dir -type f -exec realpath {} \;)
        for item in $files; do
            if [[ -f $item ]]; then
                verify_file $item
            fi
        done
    elif [[ -f $1 ]]; then
        local file=$(realpath $1)
        verify_file $file
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
        verify_cmd $2
        ;;
    update)
        echo "update command detected"
        ;;
    delete)
        echo "delete command detected"
        ;;
    *)
        print_error "fintc command not recognized"
        print_usage
        exit 1
        ;;
esac
