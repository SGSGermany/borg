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
export LC_ALL=C
shopt -s nullglob

cmd() {
    echo + "$@"
    "$@"
    return $?
}

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$BUILD_DIR/container.env" ] && source "$BUILD_DIR/container.env" \
    || { echo "ERROR: Container environment not found" >&2; exit 1; }

readarray -t -d' ' TAGS < <(printf '%s' "$TAGS")

echo + "CONTAINER=\"\$(buildah from $BASE_IMAGE)\""
CONTAINER="$(buildah from "$BASE_IMAGE")"

echo + "MOUNT=\"\$(buildah mount $CONTAINER)\""
MOUNT="$(buildah mount "$CONTAINER")"

echo + "rsync -v -rl --exclude .gitignore ./src/ …/"
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

cmd buildah run "$CONTAINER" -- \
    chmod 755 \
        "/usr/local/bin/backup" \
        "/usr/local/bin/borg-pass"

cmd buildah run "$CONTAINER" -- \
    pacman -Syu --noconfirm

cmd buildah run "$CONTAINER" -- \
    pacman -Sy --noconfirm borg python-llfuse openssh

cmd buildah run "$CONTAINER" -- \
    pacman -Scc --noconfirm

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
    --annotation org.opencontainers.image.url="https://github.com/SGSGermany/borg" \
    --annotation org.opencontainers.image.authors="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.vendor="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.licenses="MIT" \
    --annotation org.opencontainers.image.base.name="$BASE_IMAGE" \
    --annotation org.opencontainers.image.base.digest="$(podman image inspect --format '{{.Digest}}' "$BASE_IMAGE")" \
    "$CONTAINER"

cmd buildah commit "$CONTAINER" "$IMAGE:${TAGS[0]}"
cmd buildah rm "$CONTAINER"

for TAG in "${TAGS[@]:1}"; do
    cmd buildah tag "$IMAGE:${TAGS[0]}" "$IMAGE:$TAG"
done
