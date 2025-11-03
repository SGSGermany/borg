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
    echo "  $APP_NAME [OPTIONS]... check [::ARCHIVE]"
    echo
    echo "See also:"
    echo "  borg-check(1)"
    echo "  https://borgbackup.readthedocs.io/en/stable/usage/check.html"
}

action_info() {
    echo + "BORG_REPO=$BORG_REPO_INFO" >&2
}

action_exec() {
    cmd borg check -v --show-rc ${PROGRESS:+--progress} "$@"
    return $?
}
