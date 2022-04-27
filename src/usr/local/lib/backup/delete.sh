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
    echo "  $APP_NAME [--config CONFIG] delete [::ARCHIVE [ARCHIVE]...]"
    echo
    echo "See also:"
    echo "  borg-delete(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/delete.html"
}

action_info() {
    echo + "BORG_REPO=${BORG_REPO@Q}" >&2
}

action_exec() {
    local BORG_DELETE_PARAMS=( -v --stats --show-rc )
    local BORG_DELETE_STATUS=0

    local BORG_COMPACT_PARAMS=( -v --show-rc )
    local BORG_COMPACT_STATUS=0

    export BORG_REPO="$BORG_REPO"
    export BORG_PASSCOMMAND="/usr/local/bin/borg-pass"

    # delete archive(s)
    cmd borg delete "${BORG_DELETE_PARAMS[@]}" "$@" \
        || { BORG_DELETE_STATUS=$?; true; }

    [ $BORG_DELETE_STATUS -lt 2 ] || return $BORG_DELETE_STATUS

    # compact repo
    if [ $# -eq 0 ] || { [ $# -eq 1 ] && [ "$1" == "::" ]; }; then
        return
    fi

    cmd borg compact "${BORG_COMPACT_PARAMS[@]}" \
        || { BORG_COMPACT_STATUS=$?; true; }

    return $(( BORG_COMPACT_STATUS > BORG_DELETE_STATUS ? BORG_COMPACT_STATUS : BORG_DELETE_STATUS ))
}
