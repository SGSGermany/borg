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
    echo "  $APP_NAME [--config CONFIG] restore ::ARCHIVE [PATH]..."
    echo
    echo "See also:"
    echo "  borg-extract(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/extract.html"
}

action_info() {
    echo + "BORG_REPO=${BORG_REPO@Q}" >&2
}

action_exec() {
    local BORG_PARAMS=()
    local BORG_STATUS=0

    export BORG_REPO="$BORG_REPO"
    export BORG_PASSCOMMAND="/usr/local/bin/borg-pass"

    cmd cd "$BORG_RESTORE"

    cmd borg extract "${BORG_PARAMS[@]}" "$@" \
        || { BORG_STATUS=$?; true; }

    return $BORG_STATUS
}
