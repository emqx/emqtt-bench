#!/usr/bin/env bash

set -euo pipefail

# intended to run on MacOS only
if [ $(uname -o) != 'Darwin' ]; then
    echo 'Not macOS, exiting';
    exit 0;
fi

RELX_OUTPUT_DIR="_build/emqtt_bench/rel/"
# Find the tar.gz file created by relx
TAR_GZ_FILE=$(realpath $(find "${RELX_OUTPUT_DIR}" -name "*.tar.gz" | tail -1))

if [ -z "$TAR_GZ_FILE" ]; then
    echo "No tar.gz file found in ${RELX_OUTPUT_DIR}"
    exit 1
fi

echo "Found tar.gz: $TAR_GZ_FILE"

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d -p $PWD)
trap "rm -rf $TEMP_DIR" EXIT

echo "Extracting to temporary directory: $TEMP_DIR"
tar -C "$TEMP_DIR" -xzf "$TAR_GZ_FILE"

# Create zip from extracted contents
ZIP_PACKAGE_PATH="${TAR_GZ_FILE%%.tar*}.zip"
echo "Creating zip: $ZIP_PACKAGE_PATH"

cd "$TEMP_DIR"
zip -qr "$ZIP_PACKAGE_PATH" .

echo "Zip file created successfully"

if [[ "${APPLE_ID:-0}" == 0 || "${APPLE_ID_PASSWORD:-0}" == 0 || "${APPLE_TEAM_ID:-0}" == 0 ]]; then
    echo "Apple ID is not configured, skipping notarization."
    exit 0
fi

# notarize the package
# if fails, check what went wrong with this command:
# xcrun notarytool log \
    #   --apple-id "${APPLE_ID}" \
    #   --password "${APPLE_ID_PASSWORD}" \
    #   --team-id "${APPLE_TEAM_ID}" <submission-id>
echo 'Submitting the package for notarization to Apple (normally takes about a minute)'
notarytool_output="$(xcrun notarytool submit \
                                           --apple-id "${APPLE_ID}" \
                                           --password "${APPLE_ID_PASSWORD}" \
                                           --team-id "${APPLE_TEAM_ID}" "${ZIP_PACKAGE_PATH}" \
                                           --no-progress \
                                           --wait)"
echo "$notarytool_output"
echo "$notarytool_output" | grep -q 'status: Accepted' || {
    echo 'Notarization failed';
    exit 1;
}

