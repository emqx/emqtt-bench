#!/usr/bin/env bash

set -euo pipefail

cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

UNAME="$(uname -s)"
case "$UNAME" in
    Darwin)
        DIST='macos'
        VERSION_ID="$(sw_vers | grep 'ProductVersion' | cut -d':' -f 2 | cut -d'.' -f1 | tr -d ' \t')"
        SYSTEM="${DIST}${VERSION_ID}"
        ;;
    Linux)
        # /etc/os-release on amazon linux 2 contains both rhel and centos strings
        if grep -q -i 'amzn' /etc/*-release; then
            DIST='amzn'
            VERSION_ID="$(sed -n '/^VERSION_ID=/p' /etc/os-release | sed -r 's/VERSION_ID=(.*)/\1/g' | sed 's/"//g')"
        elif grep -q -i 'rhel' /etc/*-release; then
            DIST='el'
            VERSION_ID="$(rpm --eval '%{rhel}')"
        else
            DIST="$(sed -n '/^ID=/p' /etc/os-release | sed -r 's/ID=(.*)/\1/g' | sed 's/"//g')"
            VERSION_ID="$(sed -n '/^VERSION_ID=/p' /etc/os-release | sed -r 's/VERSION_ID=(.*)/\1/g' | sed 's/"//g')"
        fi
        SYSTEM="$(echo "${DIST}${VERSION_ID}" | sed -r 's/([a-zA-Z]*)-.*/\1/g')"
        ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)
        ARCH='amd64'
        ;;
    aarch64)
        ARCH='arm64'
        ;;
    arm*)
        ARCH=arm
        ;;
esac

if [ -z ${BUILD_WITHOUT_QUIC+x} ]; then
    QUIC="-quic";
else
    QUIC=""
fi

VSN="$(grep -E ".+vsn.+" _build/emqtt_bench/lib/emqtt_bench/ebin/emqtt_bench.app | cut -d '"' -f2)"
BASE=$(find ./_build/emqtt_bench/rel/emqtt_bench -name "*.tar.gz" | tail -1)
cp "$BASE" "./emqtt-bench-${VSN}-${SYSTEM}-${ARCH}${QUIC}.tar.gz"
