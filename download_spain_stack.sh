#!/usr/bin/env bash
# Download a real NISAR L2 GUNW beta stack (track 159, ascending, frame 022;
# central Spain, EPSG 32630) plus a Copernicus GLO-30 DEM mosaic for it.
#
# The 7 granules form a gap-free nearest-neighbor 12-day chain:
#   2025-10-28 .. 2026-01-20 (8 acquisition dates).
#
# Requirements:
#   - Earthdata Login credentials in ~/.netrc (machine urs.earthdata.nasa.gov)
#   - curl, gdalbuildvrt, gdal_translate
#   - ~15 GB free disk space
set -euo pipefail

cd "$(dirname "$0")"
GUNW_DIR="data/spain_159A022"
DEM_DIR="data/dem_spain"
mkdir -p "$GUNW_DIR" "$DEM_DIR"

# --------------------------------------------------------------------------
# 1. NISAR GUNW beta granules (ASF Earthdata Cloud, auth required)
# --------------------------------------------------------------------------
GRANULES=(
NISAR_L2_PR_GUNW_003_159_A_022_004_2000_SH_20251028T051542_20251028T051612_20251109T051542_20251109T051613_X05010_N_F_J_001
NISAR_L2_PR_GUNW_004_159_A_022_005_2000_SH_20251109T051542_20251109T051613_20251121T051543_20251121T051613_X05010_N_F_J_001
NISAR_L2_PR_GUNW_005_159_A_022_006_2000_SH_20251121T051543_20251121T051613_20251203T051544_20251203T051614_X05010_N_F_J_001
NISAR_L2_PR_GUNW_006_159_A_022_007_2000_SH_20251203T051544_20251203T051614_20251215T051544_20251215T051614_X05010_N_F_J_001
NISAR_L2_PR_GUNW_007_159_A_022_008_2000_SH_20251215T051544_20251215T051614_20251227T051545_20251227T051615_X05010_N_F_J_001
NISAR_L2_PR_GUNW_008_159_A_022_009_2000_SH_20251227T051545_20251227T051615_20260108T051545_20260108T051615_X05010_N_F_J_001
NISAR_L2_PR_GUNW_009_159_A_022_010_2000_SH_20260108T051545_20260108T051615_20260120T051546_20260120T051616_X05010_N_F_J_001
)
COOKIES="$(mktemp)"
trap 'rm -f "$COOKIES"' EXIT
for g in "${GRANULES[@]}"; do
    out="${GUNW_DIR}/${g}.h5"
    [ -f "$out" ] && { echo "exists: ${g}.h5"; continue; }
    echo ">>> ${g}.h5"
    curl -sSf -n -L -b "$COOKIES" -c "$COOKIES" -o "${out}.part" \
        "https://nisar.asf.earthdatacloud.nasa.gov/NISAR/NISAR_L2_GUNW_BETA_V1/${g}/${g}.h5"
    mv "${out}.part" "$out"
done

# --------------------------------------------------------------------------
# 2. Copernicus GLO-30 DEM tiles (public S3 bucket, no auth)
#    Scene bounds: lon [-4.885, -0.575], lat [38.948, 42.136]
# --------------------------------------------------------------------------
for lat in N38 N39 N40 N41 N42; do
    for lon in W005 W004 W003 W002 W001; do
        name="Copernicus_DSM_COG_10_${lat}_00_${lon}_00_DEM"
        out="${DEM_DIR}/${name}.tif"
        [ -f "$out" ] && continue
        echo ">>> ${name}"
        curl -sf -o "${out}.part" \
            "https://copernicus-dem-30m.s3.amazonaws.com/${name}/${name}.tif"
        mv "${out}.part" "$out"
    done
done

# --------------------------------------------------------------------------
# 3. Mosaic + crop the DEM to the scene footprint
# --------------------------------------------------------------------------
gdalbuildvrt -q "${DEM_DIR}/dem_mosaic.vrt" "${DEM_DIR}"/Copernicus_DSM_COG_10_*.tif
gdal_translate -q -projwin -5.0 42.2 -0.5 38.9 -co COMPRESS=DEFLATE \
    "${DEM_DIR}/dem_mosaic.vrt" "${DEM_DIR}/dem_spain.tif"

echo "Done. GUNW stack: ${GUNW_DIR}/ (7 files), DEM: ${DEM_DIR}/dem_spain.tif"
