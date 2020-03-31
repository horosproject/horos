#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"
copy_dir="$BUILT_PRODUCTS_DIR/DCMTK"

[ -d "${copy_dir}" ] && [ ! -f "${copy_dir}/.incomplete" ] && exit 0

mkdir -p "$install_dir"
mkdir -p "${copy_dir}"
touch "${copy_dir}/.incomplete"

args=()
export MAKEFLAGS="-j $(sysctl -n hw.ncpu)"

echo "${cmake_dir}"
cd "$cmake_dir"
make "${args[@]}" install

# Copy subset of applications to build directory
#
cp "${install_dir}/bin/dcmdump" "${copy_dir}"
cp "${install_dir}/bin/dcmpsprt" "${copy_dir}"
cp "${install_dir}/bin/dcmprscu" "${copy_dir}"
cp "${install_dir}/bin/dsr2html" "${copy_dir}"
cp "${install_dir}/bin/echoscu" "${copy_dir}"
cp "${install_dir}/share/dcmtk/dicom.dic" "${copy_dir}"

rm -f "$copy_dir/.incomplete"

exit 0
