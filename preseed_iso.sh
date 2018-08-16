#!/bin/bash

set -e

if [ "$#" -ne 3 ]; then
    echo "usage: $0 SOURCE_ISO_PATH PRESEED_CFG TARGET_ISO_PATH" 1>&2
    exit 1
fi

source_path="$1"
preseed_cfg="$2"
target_path="$3"

# gzip path can't be called GZIP, because when run, gzip treats an ENV var
# named GZIP as extra CLI args. This is so you can pass compression levels into
# programs that use gzip. The fact that you can pass anything beyond the
# compression settings is a very *interesting* "feature."
for name in BSDTAR CPIO GZIP_ MD5SUM XORRISO; do
    if [ -z "${!name}" ]; then
        echo "$0: must define $name ENV var" 1>&2
        exit 2
    fi
done

extract_dir="$(mktemp -d)"
function cleanup_extract_dir {
    chmod +w -R "$extract_dir"
    rm -rf "$extract_dir"
}
trap cleanup_extract_dir EXIT

md5sum_path="$extract_dir/md5sum.txt"

set -o xtrace

# Extract the ISO
"$BSDTAR" -C "$extract_dir" -xf "$source_path"

set +o xtrace
install_path=$(find "$extract_dir" -type d -name 'install.*')
initrd="$install_path/initrd.gz"
set -o xtrace

# Inject preseed.cfg
chmod +w -R "$install_path"
"$GZIP_" -d "$initrd"
echo "$preseed_cfg" | "$CPIO" -H newc -o -A -F "${initrd%.gz}"
"$GZIP_" "${initrd%.gz}"
chmod -w -R "$install_path"

# Fix md5sum.txt
touch "$md5sum_path"
chmod +w "$md5sum_path"
# shellcheck disable=SC2094
find "$extract_dir" -type f ! -path "$md5sum_path" \
    -exec "$MD5SUM" "{}" \; > "$md5sum_path"
chmod -w "$md5sum_path"

# Rebuild ISO
$XORRISO -as mkisofs -o "$target_path" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot \
    -boot-load-size 4 -boot-info-table "$extract_dir"
