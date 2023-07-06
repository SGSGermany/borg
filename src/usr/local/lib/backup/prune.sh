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
    echo "  $APP_NAME [OPTIONS]... prune [ARCHIVE_PATTERN]"
    echo
    echo "See also:"
    echo "  borg-prune(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/prune.html"
}

action_info() {
    echo + "BORG_REPO=$BORG_REPO_INFO" >&2
}

action_exec() {
    if [ "${#BORG_PRUNE_KEEPS[@]}" -eq 0 ]; then
        # don't prune any actual archives, but still remove old checkpoints
        BORG_PRUNE_KEEPS=( --keep-last 1000000000 )
    fi

    local BORG_PRUNE_PARAMS=( -v --stats --list --show-rc )
    local BORG_PRUNE_STATUS=0

    local BORG_COMPACT_PARAMS=( -v --show-rc )
    local BORG_COMPACT_STATUS=0

    export BORG_REPO="$BORG_REPO"
    export BORG_PASSCOMMAND="/usr/local/bin/borg-pass"

    # use custom archive name pattern
    [ $# -eq 0 ] || BORG_PRUNE_PATTERN="$1"

    # prune archives
    cmd borg prune "${BORG_PRUNE_PARAMS[@]}" \
        --glob-archives "${BORG_PRUNE_PATTERN:-*}" \
        "${BORG_PRUNE_KEEPS[@]}" \
        || { BORG_PRUNE_STATUS=$?; true; }

    [ $BORG_PRUNE_STATUS -lt 2 ] || return $BORG_PRUNE_STATUS

    # compact repo
    cmd borg compact "${BORG_COMPACT_PARAMS[@]}" \
        || { BORG_COMPACT_STATUS=$?; true; }

    return $(( BORG_COMPACT_STATUS > BORG_PRUNE_STATUS ? BORG_COMPACT_STATUS : BORG_PRUNE_STATUS ))
}
