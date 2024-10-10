#!/usr/bin/env bash

set -euo pipefail

[ "${DEBUG:-0}" -eq 1 ] && set -x

# ensure dir
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

OTP_VSN=$(erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().')
case ${OTP_VSN} in
    27*)
        VERSION="3.20.0-emqx-3"
        ;;
    26*)
        VERSION="3.20.0-emqx-1"
        ;;
    25*)
        VERSION="3.19.0-emqx-9"
        ;;
    *)
        echo "Unsupported Erlang/OTP version $OTP_VSN"
        exit 1
        ;;
esac

DOWNLOAD_URL='https://github.com/emqx/rebar3/releases/download'

download() {
    curl --silent --show-error -f -L "${DOWNLOAD_URL}/${VERSION}/rebar3" -o ./rebar3
}

# get the version number from the second line of the escript
# because command `rebar3 -v` tries to load rebar.config
# which is slow and may print some logs
version() {
    head -n 2 ./rebar3 | tail -n 1 | tr ' ' '\n' | grep -E '^.+-emqx-.+'
}

if [ -f 'rebar3' ] && [ "$(version)" = "$VERSION" ]; then
    exit 0
fi

download
chmod +x ./rebar3
