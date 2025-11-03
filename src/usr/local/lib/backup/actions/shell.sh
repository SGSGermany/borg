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
    echo "  $APP_NAME [OPTIONS]... shell"
}

action_info() {
    echo + "BACKUP_CONFIG=$BACKUP_CONFIG" >&2
    echo + "BORG_REPO=$BORG_REPO_INFO" >&2
    echo + "BACKUP_PATH=$BACKUP_PATH_INFO" >&2
    echo + "BACKUP_RESTORE=$BACKUP_RESTORE_INFO" >&2
}

action_exec() {
    export BACKUP_CONFIG
    export BACKUP_PATH
    export BACKUP_RESTORE

    cmd bash -i
    return $?
}
