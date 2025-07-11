#!/usr/bin/env bash

# intended to run on MacOS only
# signs runtime libraries found in $RELX_TEMP_DIR

# required variables:
# APPLE_DEVELOPER_IDENTITY: "Developer ID Application: <company name> (<hex id>)"
# APPLE_DEVELOPER_ID_BUNDLE: base64-encoded content of apple developer id certificate bundle in pksc12 format
# APPLE_DEVELOPER_ID_BUNDLE_PASSWORD: password used when exporting the bundle

# note: 'bundle' in apple terminology is 'identity'

set -euo pipefail

if [ $(uname) != 'Darwin' ]; then
    echo 'Not macOS, exiting';
    exit 0;
fi

if [[ "${APPLE_DEVELOPER_ID_BUNDLE:-0}" == 0 || "${APPLE_DEVELOPER_ID_BUNDLE_PASSWORD:-0}" == 0 ]]; then
    echo "Apple developer certificate is not configured, skip signing"
    exit 0
fi

PKSC12_FILE="$HOME/developer-id-application.p12"
printf '%s' "${APPLE_DEVELOPER_ID_BUNDLE}" | base64 --decode > "${PKSC12_FILE}"

KEYCHAIN="emqtt-bench-$(date +%s).keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"

trap cleanup EXIT

function cleanup {
    set +e
    security delete-keychain "${KEYCHAIN}" 2>/dev/null
}

security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN}"
security set-keychain-settings "${KEYCHAIN}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN}"
security import "${PKSC12_FILE}" -P "${APPLE_DEVELOPER_ID_BUNDLE_PASSWORD}" -t cert -f pkcs12 -k "${KEYCHAIN}" -T /usr/bin/codesign
security set-key-partition-list -S "apple-tool:,apple:,codesign:" -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN}"
if [ "$(sw_vers -productVersion | cut -d'.' -f1)" -ge 15 ]; then
  openssl pkcs12 -in "${PKSC12_FILE}" -clcerts -nokeys -out certificate.crt --passin "pass:${APPLE_DEVELOPER_ID_BUNDLE_PASSWORD}"
  security verify-cert -k "${KEYCHAIN}" -c certificate.crt
else
  security verify-cert -k "${KEYCHAIN}" -c "${PKSC12_FILE}"
fi
security find-identity -p codesigning "${KEYCHAIN}"

# add new keychain into the search path for codesign, otherwise the stuff does not work
keychains=$(security list-keychains -d user)
keychain_names=();
for keychain in ${keychains}; do
    basename=$(basename "${keychain}")
    keychain_name=${basename::${#basename}-4}
    keychain_names+=("${keychain_name}")
done
security -v list-keychains -s "${keychain_names[@]}" "${KEYCHAIN}"

for f in \
    asn1rt_nif.so \
    beam.smp \
    crypto.so \
    crypto_callback.so \
    dyn_erl \
    epmd \
    erl \
    erl_call \
    erl_child_setup \
    erlexec \
    escript \
    heart \
    inet_gethost \
    libmsquic*.dylib \
    libquicer_nif*.dylib \
    libquicer_nif.so \
    otp_test_engine.so \
    run_erl \
    to_erl \
    ; do
    find "${RELX_TEMP_DIR}" -name "$f" -exec codesign -s "${APPLE_DEVELOPER_IDENTITY}" -f --verbose=4 --timestamp --options=runtime {} \;
done

cleanup
