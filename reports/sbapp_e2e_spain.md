# smallbaselineApp end-to-end on real NISAR GUNW beta data (central Spain)

**Date**: 2026-07-16
**MintPy code**: `insarlab/MintPy` upstream `main` @ `4fca754e` (no code changes)
**Environment**: this repo's isolated venv (`numpy<2`, MintPy installed editable)
**Harness**: `download_spain_stack.sh` + `templates/NisarSpain159A022.txt`

## Purpose

Stages 1/2 validated the `prep_nisar` loader in isolation. This run validates the
**full `smallbaselineApp.py` pipeline** on real NISAR mission data (L2 GUNW beta,
released via ASF 2026-02-27), i.e. `mintpy.load.processor = nisar` end to end.

## Data

- **NISAR_L2_GUNW_BETA_V1** (CMR reports 10,217 granules total as of 2026-07-16).
  GUNW beta products are nearest-neighbor 12-day pairs only, HH, 80 m posting.
- Frame selection: all granule titles were scanned via CMR and ranked by the
  longest gap-free chain of full-frame (`_N_F_J_`) products.
  **Track 159, ascending, frame 022** (central Spain, EPSG 32630) provides
  **7 sequential pairs / 8 dates, 2025-10-28 .. 2026-01-20** (~2 GB per granule,
  14 GB total). Most other dense frames are in Antarctica/Alaska.
- **DEM**: Copernicus GLO-30, 25 tiles (N38–N42 x W005–W001) mosaicked and
  cropped to the scene footprint (EPSG 4326 GeoTIFF).

## Result: full pipeline completes

All 18 steps ran to `Normal end of smallbaselineApp processing!` in
**32 min 33 s** wall time (data on a CIFS/NAS mount; scene 4392 x 4455,
19.6 M pixels x 7 pairs).

Steps exercised: load_data (prep_nisar: ifgramStack + ionStack + tropoStack +
setStack + geometryGeo + waterMask), modify_network, reference_point,
quick_overview, correct_unwrap_error (off), invert_network, correct_LOD,
correct_SET (off), correct_ionosphere, correct_troposphere (off), deramp (off),
correct_topography (DEM error), residual_RMS, reference_date, velocity,
geocode (skipped, already geocoded), google_earth, hdfeos5 (off).

### Quality numbers

| metric | value | comment |
|---|---|---|
| valid pixels (common mask) | 7,800,237 / 19,566,360 (39.9 %) | subswath ∩ water ∩ 7-pair overlap |
| mean spatial coherence per ifg | 0.644 – 0.737 | L-band 12-day, inland Spain |
| perpendicular baseline | -103.8 .. +38.4 m | NISAR tight orbital tube |
| temporal coherence | ≡ 1.000 | see caveat below |
| velocity over mask | median +10.0 cm/yr (p5/p95 -1.7/+17.2) | uncalibrated beta, no tropo/iono correction, 3-month span |

- `correct_LOD` correctly recognizes `PLATFORM = NISAR` ("No local oscillator
  drift correction is needed for NISAR").

### Ionosphere-stack path validated

With `mintpy.ionosphericDelay.method = split_spectrum`, `iono_split_spectrum.py`
consumed the GUNW-native `ionStack.h5` (built by `prep_nisar` from
`ionospherePhaseScreen`): inverted it to `ion.h5` (8 dates), re-referenced, and
produced `timeseries_ion.h5`, in 1 min 29 s. Ionospheric LOS displacement at the
last date over the mask: **median -2.9 cm, p5/p95 -10.9/+5.1 cm** — large enough
to matter for any velocity estimate at this time-series length.

## Caveats and findings

1. **Temporal coherence is degenerate for GUNW-only networks.** With only
   nearest-neighbor pairs, n_ifgs = n_dates - 1: the network is exactly
   determined, residuals are identically zero and temporal coherence is 1
   everywhere. `maskTempCoh` therefore filters nothing. Any quality masking for
   NISAR GUNW stacks must come from spatial coherence / connected components
   instead.
2. **`tropoStack.h5` / `setStack.h5` are produced but never consumed.**
   `prep_nisar` writes both, but no smallbaselineApp step reads them:
   `correct_troposphere` supports pyaps/gacos/opera/height_correlation only and
   `correct_SET` recomputes with pysolid. The GUNW-native correction layers are
   orphaned. (The velocity bias above is exactly where they would help.)
3. **`PROCESSOR` attribute is missing** from prep_nisar metadata (cf.
   `prep_aria` which sets it). The pipeline logs "processed by InSAR software:
   mintpy".
4. **Single-pair stacks crash `plot_network`** (`utils1.py` `read_text_file`:
   a one-row text file loads as a 1-D array and `txtContent[:, 1]` raises
   IndexError). Found with the single-pair JPL sample GUNW; generic MintPy bug,
   not NISAR-specific.
5. `load_data` wraps `prep_nisar` failures in a bare `except` that continues
   with "Assuming its result exists" — loader errors surface later as
   confusing downstream failures.

## Reproduce

```bash
./download_spain_stack.sh          # needs Earthdata login in ~/.netrc, ~15 GB
mkdir -p sbapp_spain && cd sbapp_spain
smallbaselineApp.py ../templates/NisarSpain159A022.txt
```
