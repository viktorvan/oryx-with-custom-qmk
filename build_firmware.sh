#!/bin/bash

set -euo pipefail

# --- Configuration ---
layout_id="WlYYj"
layout_geometry="voyager"
firmware_version="24"

keyboard_directory="qmk_firmware/keyboards/zsa"
make_prefix="zsa/"

# --- Initialize and update QMK firmware submodule ---
echo "🔄 Updating QMK submodule..."
git submodule update --init --remote --depth=1
cd qmk_firmware
git checkout -B "firmware${firmware_version}" "origin/firmware${firmware_version}"
git submodule update --init --recursive
cd ..

# --- Build Docker image for QMK ---
echo "🐳 Building QMK Docker image..."
docker build -t qmk .

# --- Copy keymap into QMK directory ---
echo "📁 Copying keymap..."
rm -rf "${keyboard_directory}/${layout_geometry}/keymaps/${layout_id}"
mkdir -p "${keyboard_directory}/${layout_geometry}/keymaps"
cp -r "${layout_id}" "${keyboard_directory}/${layout_geometry}/keymaps/"

# --- Build firmware in Docker ---
echo "⚙️ Building firmware..."
docker run -v "$(pwd)/qmk_firmware:/root" --rm qmk /bin/sh -c "
  qmk setup zsa/qmk_firmware -b firmware${firmware_version} -y &&
  make ${make_prefix}${layout_geometry}:${layout_id}
"

# --- Locate the built firmware ---
echo "📦 Searching for output firmware file..."
firmware_file="./qmk_firmware/zsa_${layout_geometry}_${layout_id}.bin"

if [[ -f "$firmware_file" ]]; then
  echo "✅ Firmware built: $firmware_file"
  echo "📦 Moving to cwd"
  mv "$firmware_file" .
else
  echo "❌ Firmware file not found: $firmware_file"
  echo "Listing contents of qmk_firmware for debugging:"
  ls -lh ./qmk_firmware
  exit 1
fi

