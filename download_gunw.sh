#!/usr/bin/env bash
# Download the JPL NISAR GUNW sample product (~252 MB, no Earthdata Login).
# Idempotent: skips the download if the target file already exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"

GRANULE="NISAR_L2_PR_GUNW_001_030_A_019_002_2000_SH_20081012T060911_20081012T060925_20081127T061000_20081127T061014_D00404_N_F_J_001"
BASE="https://nisar.asf.earthdatacloud.nasa.gov/NISAR-SAMPLE-DATA/GUNW/${GRANULE}"
URL="${BASE}/${GRANULE}.h5"
OUT="${DATA_DIR}/${GRANULE}.h5"

mkdir -p "${DATA_DIR}"

if [[ -f "${OUT}" ]]; then
    echo "Already present: ${OUT}"
    echo "Size: $(du -h "${OUT}" | cut -f1)"
    exit 0
fi

echo "Downloading NISAR GUNW sample (~252 MB)..."
echo "  ${URL}"
curl -fL --retry 3 --retry-delay 5 -o "${OUT}.part" "${URL}"
mv "${OUT}.part" "${OUT}"

echo "Done: ${OUT}"
echo "Size: $(du -h "${OUT}" | cut -f1)"
