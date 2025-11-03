# Borg
# A container to create backups using Borg.
#
# Copyright (c) 2022  SGS Serious Gaming & Simulations GmbH
#
# This work is licensed under the terms of the MIT license.
# For a copy, see LICENSE file or <https://opensource.org/licenses/MIT>.
#
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

action_help() {
    echo "Usage:"
    echo "  $APP_NAME [OPTIONS]... create [CREATE_OPTIONS]... [ARCHIVE]"
    echo
    echo "Action options:"
    echo "  -n, --dry-run              do not create a backup archive"
    echo "      --comment COMMENT      add a comment text to the archive"
    echo "      --timestamp TIMESTAMP  manually specify the archive creation date/time"
    echo "                             (UTC, yyyy-mm-ddThh:mm:ss format)"
    echo
    echo "See also:"
    echo "  borg-create(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/create.html"
}

action_info() {
    echo + "BORG_REPO=$BORG_REPO_INFO" >&2
    echo + "BACKUP_PATH=$BACKUP_PATH_INFO" >&2
}

action_exec() {
    local BORG_PARAMS=( -v --show-rc ${PROGRESS:+--progress} --stats )
    local BORG_ARGS=()

    # read command line options
    local ARCHIVE=""

    while [ $# -gt 0 ]; do
        if [ "$1" == "-n" ] || [ "$1" == "--dry-run" ]; then
            BORG_PARAMS+=( "$1" )
            shift
        elif [ "$1" == "--comment" ] || [ "$1" == "--timestamp" ]; then
            if [ -z "${2:-}" ]; then
                echo "Invalid \`$APP_NAME create\` options: Missing required argument for option '$1'" >&2
                return 1
            fi

            BORG_PARAMS+=( "$1" "$2" )
            shift 2
        elif [ -z "$ARCHIVE" ]; then
            ARCHIVE="$1"
            shift
        else
            echo "Invalid \`$APP_NAME create\` option: $1" >&2
            return 1
        fi
    done

    # other options
    BORG_PARAMS+=( --compression "lz4" )

    # backup paths
    for BORG_CREATE_PATH in "${BORG_CREATE_PATHS[@]}"; do
        BORG_ARGS+=( "./${BORG_CREATE_PATH##/}" )
    done

    # file and directory exclusion
    BORG_ARGS+=( --exclude-caches --exclude-nodump )
    for BORG_CREATE_EXCLUDE in "${BORG_CREATE_EXCLUDE[@]}"; do
        [[ "$BORG_CREATE_EXCLUDE" =~ ^[a-z]{2}: ]] \
            || BORG_CREATE_EXCLUDE="sh:./${BORG_CREATE_EXCLUDE##/}"
        BORG_ARGS+=( --exclude "$BORG_CREATE_EXCLUDE" )
    done

    # create backup
    cmd cd "$BACKUP_PATH"

    cmd borg create "${BORG_PARAMS[@]}" \
        ::"${ARCHIVE:-$BORG_CREATE_ARCHIVE}" \
        "${BORG_ARGS[@]}"
    return $?
}
