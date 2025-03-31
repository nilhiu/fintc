#!/usr/bin/env bash

set -euo pipefail

# FINTC_HOME is where all fintc files will reside (including file hashes)
FINTC_HOME=${FINTC_HOME:-"/var/lib/fintc"}
FINTC_HASHES_FILE=$FINTC_HOME/hashes
FINTC_HASHES=$(if [[ -f "$FINTC_HASHES_FILE" ]]; then cat $FINTC_HASHES_FILE; else echo ""; fi)

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
    echo "$hash" >> $FINTC_HASHES_FILE
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

# update_hash - updates the given file's hash
#
# Arguments:
#   file: the file whose hash to update
update_hash() {
    local file=$1
    local hash=$(b3sum $file)

    if ! grep $file $FINTC_HASHES_FILE &> /dev/null; then
        print_error "file '$file' not hashed."
        return
    fi

    sed -i "s!.*$file!$hash!" $FINTC_HASHES_FILE &> /dev/null
    print_info "file '$file' hash updated."
}

# delete_hash - deletes the given file's hash
#
# Arguments:
#   file: the file whose hash to delete
delete_hash() {
    local file=$1
    local hash=$(b3sum $file)

    if ! grep $file $FINTC_HASHES_FILE &> /dev/null; then
        print_error "file '$file' not hashed."
        return
    fi

    sed -i "\!$file!d" $FINTC_HASHES_FILE &> /dev/null
    print_info "file '$file' hash deleted."
}

# run_on - runs a given function/program on file(s)
#
# Arguments:
#   file/dir: the file or directory to run the function/program on
#   func: the function to run on each file
run_on() {
    local file=$1
    local func=$2

    if [[ -d $file ]]; then
        local files=$(find $file -type f -exec realpath {} \;)
        for f in $files; do
            if [[ -f $f ]]; then
                $func $f
            fi
        done
    elif [[ -f $file ]]; then
        $func $(realpath $file)
    fi
}

ensure_dep b3sum

if [[ $# -ne 2 ]]; then
    print_usage
    exit 1
fi

mkdir -p "$FINTC_HOME"
touch $FINTC_HASHES_FILE

case ${1,,} in
    init)
        run_on $2 hash_file
        ;;
    verify)
        run_on $2 verify_file
        ;;
    update)
        run_on $2 update_hash
        ;;
    delete)
        run_on $2 delete_hash
        ;;
    *)
        print_error "fintc command not recognized"
        print_usage
        exit 1
        ;;
esac
