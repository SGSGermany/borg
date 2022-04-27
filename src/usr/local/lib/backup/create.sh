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
    echo "  $APP_NAME [--config CONFIG] create [--comment COMMENT] [ARCHIVE]"
    echo
    echo "See also:"
    echo "  borg-create(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/create.html"
}

action_info() {
    echo + "BORG_REPO=${BORG_REPO@Q}" >&2
}

action_exec() {
    local BORG_PARAMS=( -v --stats --show-rc )
    local BORG_ARGS=()
    local BORG_STATUS=0

    export BORG_PASSCOMMAND="/usr/local/bin/borg-pass"

    # read command line options
    local ARCHIVE=""
    local COMMENT=""

    while [ $# -gt 0 ]; do
        if [ "$1" == "--comment" ]; then
            if [ -z "${2:-}" ]; then
                echo "Invalid \`$APP_NAME create\` options: Missing required argument 'COMMENT' for option '--comment'" >&2
                return 1
            fi

            COMMENT="$2"
            shift 2
        elif [ -z "$ARCHIVE" ]; then
            ARCHIVE="$1"
            shift
        else
            echo "Invalid \`$APP_NAME create\` option: $1" >&2
            return 1
        fi
    done

    # options
    BORG_PARAMS+=( --compression "lz4" )

    # backup paths
    for BORG_CREATE_PATH in "${BORG_CREATE_PATHS[@]}"; do
        BORG_ARGS+=( "./${BORG_CREATE_PATH##/}" )
    done

    # file and directory exclusion
    BORG_ARGS+=( --exclude-caches --exclude-nodump )
    for BORG_CREATE_EXCLUDE in "${BORG_CREATE_EXCLUDE[@]}"; do
        BORG_ARGS+=( --exclude "sh:./${BORG_CREATE_EXCLUDE##/}" )
    done

    # pass command line options
    if [ -n "$ARCHIVE" ]; then
        BORG_CREATE_ARCHIVE="$ARCHIVE"
    fi

    if [ -n "$COMMENT" ]; then
        BORG_PARAMS+=( --comment "$COMMENT" )
    fi

    # create backup
    cmd borg create "${BORG_PARAMS[@]}" \
        "$BORG_REPO"::"$BORG_CREATE_ARCHIVE" \
        "${BORG_ARGS[@]}" \
        || { BORG_STATUS=$?; true; }

    return $BORG_STATUS
}
