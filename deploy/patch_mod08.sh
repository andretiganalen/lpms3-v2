#!/bin/sh
# MOD-08: ganti seluruh logo/favicon LPMS dengan logo Len 2023 (aset di deploy/brand).
# Berkas .gz dihapus agar tidak ikut tersaji (Rails melayani .gz bila ada).
set -e
B=/tmp/brand
A=/app/public/assets
rep() { # <sumber> <target>
  cp "$B/$1" "$2"
  rm -f "$2.gz"
}
rep favicon.ico /app/public/favicon.ico
rep favicon.ico "$A/favicon-939cbdbd3b0f071269abd28ddfcb2f922d6257ce6ef70ba4941ea1708a564ab3.ico"
rep favicon.ico "$A/development/favicon-5c0a15296d9daa540fc98f630ef68158448711084bcca8547b659fba8c2a36c4.ico"
rep apple-touch-icon-120x120.png "$A/apple-touch-icon-120x120-7cc127b22515cb03208e0cd2ab29c30545d6c1d232a8d68058c751bf29626354.png"
rep apple-touch-icon-120x120.png "$A/development/apple-touch-icon-120x120-f98f40c61fd7f46807edffe6074456f858de5bade31cc306748be49936cb411b.png"
rep logo-wide.png "$A/logo_openproject-0ac721deb10b0ac88e34c3a066dc8ce283e9d2601c805ae71fc8dc9548fc0582.png"
rep logo-wide.png "$A/styleguide/logo_openproject-0ac721deb10b0ac88e34c3a066dc8ce283e9d2601c805ae71fc8dc9548fc0582.png"
rep logo-wide.png "$A/logo_openproject_white_big-2c6d79fa03613154cf6bd67c622dbae5b93ed3199e0e7332d96b6f8ec21f85a1.png"
rep logo-wide.png "$A/logo-white-bg-ua-1524d9ac40e1bc2f0e6d3cf499704cc40318e0ff3e46e2678cb91e9f3fadd426.png"
rep logo-wide.png "$A/logo-black-bg-ua-3ac60ba3fde04b597a904611d9295ad7705d6d55d4fd77441e5307d8cded70ae.png"
rep logo-wide.png "$A/bim/logo_openproject_bim_big-ae08f4c5907fd0e0808cc2b7e82250f739034815e2760791b5716e5a4604f01c.png"
rep logo-wide.png "$A/bim/logo_openproject_bim_big_coloured-233fba69d6f39a54c58e503399e30f4615ff579235dcd8f3de7b50c92288b795.png"
rep logo-narrow.svg "$A/logo_openproject_narrow-b109a77c87bd36817399515b9b09c508e8beaba76a57f2c40fd484d8aa25fa15.svg"
rep icon-logo.svg "$A/icon_logo-955af4346e973d13afd9f5a3d0d4c63f8002be1125bcd41d8036ff67ee1cdd51.svg"
rep icon-logo-white.svg "$A/icon_logo_white-8e3e74afd4629f3f6fed8e229bbc0dfd926fc196d8b8d0f7bf3be3eca9574fb7.svg"
# Pemeriksaan: tidak ada aset logo LPMS yang tersisa dengan isi lama.
for f in favicon-939cbdbd3b0f071269abd28ddfcb2f922d6257ce6ef70ba4941ea1708a564ab3.ico logo_openproject-0ac721deb10b0ac88e34c3a066dc8ce283e9d2601c805ae71fc8dc9548fc0582.png; do
  cmp -s "$B/$( [ "${f##*.}" = ico ] && echo favicon.ico || echo logo-wide.png )" "$A/$f" || { echo "MOD-08 gagal: $f"; exit 1; }
done
echo "MOD-08 selesai"
