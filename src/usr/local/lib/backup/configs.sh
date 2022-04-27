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
    echo "  $APP_NAME configs"
}

action_info() {
    :
}

action_exec() {
    find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 \
        -type f -name '*.env' \
        -printf '%P\n' \
        | sort
}
