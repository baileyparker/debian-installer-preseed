#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "usage: $0 DOWNLOAD_PATH URL" 1>&2
    exit 1
fi

iso_path="$1"
iso_url="$2"

for name in GPG SHA512SUM WGET; do
    if [ -z "${!name}" ]; then
        echo "$0: must define $name ENV var" 1>&2
        exit 2
    fi
done

base_url=$(dirname "$iso_url")

sha512sums_url="$base_url/SHA512SUMS"
sha512sums_sign_url="$base_url/SHA512SUMS.sign"

download_dir=$(mktemp -d)
function cleanup_download_dir {
    rm -rf "$download_dir"
}
trap cleanup_download_dir EXIT

iso_download_path="$download_dir/$(basename "$iso_url")"
sha512sums_path="$download_dir/SHA512SUMS"
sha512sums_sign_path="$download_dir/SHA512SUMS.sign"

set -o xtrace


if [ "$VERIFY_DIGEST" -ne 0 ]; then
    $WGET -O "$sha512sums_path" "$sha512sums_url"

    if [ "$VERIFY_SIGNATURE" -ne 0 ]; then
        $WGET -O "$sha512sums_sign_path" "$sha512sums_sign_url"

        # Expects the Debian signing key to be in the keyring
        $GPG --verify "$sha512sums_sign_path"
    fi
fi

$WGET -O "$iso_download_path" "$iso_url"

if [ "$VERIFY_DIGEST" -ne 0 ]; then
    # sha512sum -c only works from the same directory as the digest was created
    pushd "$(dirname "$sha512sums_path")"
    $SHA512SUM -c "$sha512sums_path" --strict --ignore-missing
    popd
fi

mv "$iso_download_path" "$iso_path"
