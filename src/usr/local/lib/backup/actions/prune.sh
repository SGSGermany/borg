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
    echo "  $APP_NAME [OPTIONS]... prune [PRUNE_OPTIONS]... [ARCHIVE_PATTERN]"
    echo
    echo "Action options:"
    echo "  -n, --dry-run     do not change repository"
    echo "      --save-space  work slower, but using less space"
    echo
    echo "See also:"
    echo "  borg-prune(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/prune.html"
}

action_info() {
    echo + "BORG_REPO=$BORG_REPO_INFO" >&2
}

action_exec() {
    local BORG_PARAMS=( -v --show-rc --stats --list )

    # providing no retention policy means keeping everything
    # prunes no actual archives, but removes old checkpoints
    if [ "${#BORG_PRUNE_KEEPS[@]}" -eq 0 ]; then
        BORG_PRUNE_KEEPS=( --keep-last 1000000000 )
    fi

    # read command line options
    local ARCHIVE_PATTERN=""

    while [ $# -gt 0 ]; do
        if [ "$1" == "-n" ] || [ "$1" == "--dry-run" ] || [ "$1" == "--save-space" ]; then
            BORG_PARAMS+=( "$1" )
            shift
        elif [ -z "$ARCHIVE_PATTERN" ]; then
            ARCHIVE_PATTERN="$1"
            shift
        else
            echo "Invalid \`$APP_NAME prune\` option: $1" >&2
            return 1
        fi
    done

    # prune archives using configured retention policy
    cmd borg prune "${BORG_PARAMS[@]}" \
        --glob-archives "${ARCHIVE_PATTERN:-${BORG_PRUNE_PATTERN:-*}}" \
        "${BORG_PRUNE_KEEPS[@]}"
    return $?
}
