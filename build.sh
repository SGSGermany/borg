#!/bin/bash
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

set -eu -o pipefail
export LC_ALL=C.UTF-8

[ -v CI_TOOLS ] && [ "$CI_TOOLS" == "SGSGermany" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS' not set or invalid" >&2; exit 1; }

[ -v CI_TOOLS_PATH ] && [ -d "$CI_TOOLS_PATH" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS_PATH' not set or invalid" >&2; exit 1; }

source "$CI_TOOLS_PATH/helper/common.sh.inc"
source "$CI_TOOLS_PATH/helper/container.sh.inc"
source "$CI_TOOLS_PATH/helper/container-archlinux.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

readarray -t -d' ' TAGS < <(printf '%s' "$TAGS")

echo + "CONTAINER=\"\$(buildah from $(quote "$BASE_IMAGE"))\"" >&2
CONTAINER="$(buildah from "$BASE_IMAGE")"

echo + "MOUNT=\"\$(buildah mount $(quote "$CONTAINER"))\"" >&2
MOUNT="$(buildah mount "$CONTAINER")"

pkg_install "$CONTAINER" \
    borg \
    python-llfuse \
    openssh

echo + "rsync -v -rl --exclude .gitignore ./src/ …/" >&2
rsync -v -rl --exclude '.gitignore' "$BUILD_DIR/src/" "$MOUNT/"

cmd buildah run "$CONTAINER" -- \
    chmod 700 \
        "/root" \
        "/root/.cache" \
        "/root/.cache/borg" \
        "/root/.config" \
        "/root/.config/borg" \
        "/root/.ssh" \
        "/root/borg" \
        "/root/borg/backup" \
        "/root/borg/mount" \
        "/root/borg/repo" \
        "/root/borg/restore"

VERSION="$(pkg_version "$CONTAINER" borg)"

cleanup "$CONTAINER"

cmd buildah config \
    --env BORG_VERSION="$VERSION" \
    "$CONTAINER"

cmd buildah config \
    --volume "/root/.cache/borg" \
    --volume "/root/.config/borg" \
    --volume "/root/.ssh" \
    --volume "/root/borg/backup" \
    --volume "/root/borg/repo" \
    --volume "/root/borg/restore" \
    "$CONTAINER"

cmd buildah config \
    --workingdir "/root/borg/backup" \
    --cmd '[ "backup", "create" ]' \
    "$CONTAINER"

cmd buildah config \
    --annotation org.opencontainers.image.title="Borg" \
    --annotation org.opencontainers.image.description="A container to create backups using Borg." \
    --annotation org.opencontainers.image.version="$VERSION" \
    --annotation org.opencontainers.image.url="https://github.com/SGSGermany/borg" \
    --annotation org.opencontainers.image.authors="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.vendor="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.licenses="MIT" \
    --annotation org.opencontainers.image.base.name="$BASE_IMAGE" \
    --annotation org.opencontainers.image.base.digest="$(podman image inspect --format '{{.Digest}}' "$BASE_IMAGE")" \
    "$CONTAINER"

con_commit "$CONTAINER" "${TAGS[@]}"
