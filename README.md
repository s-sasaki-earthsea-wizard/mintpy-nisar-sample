# mintpy-nisar-sample

Real-data validation harness for the NISAR GUNW metadata reader in
[MintPy](https://github.com/insarlab/MintPy) (`src/mintpy/prep_nisar.py`).

This is a **sibling project** to a MintPy fork: it lives inside the fork tree
but is a fully independent git repository, excluded from the fork history via
`.git/info/exclude` (same pattern as the benchmark sibling). Nothing here is
part of the upstream contribution — it is the *evidence* that backs it.

## Why this exists

The upstream unit-test PR (`tests/test_prep_nisar.py`) exercises the
GDAL-free parsing layer against **synthetic** GUNW HDF5 fixtures built with
`h5py`. Those fixtures encode our assumptions about the NISAR GUNW schema
(dataset paths, dtypes, byte-string encoding, `referenceSlantRange`, ...).

This harness downloads a **real** NISAR GUNW sample product and runs the same
reader against it, so we can confirm the synthetic fixtures match the real
file layout — and record the result as a manual validation log to cite in the
PR.

## The sample product

- JPL official NISAR Sample Data Suite, GUNW L2, HDF5, ~252 MB.
- Surrogate data: JAXA ALOS-1 PALSAR (2008), L-band. Format and metadata are
  fully NISAR-compatible (`science/LSAR/GUNW/...`).
- **No Earthdata Login required** — the sample bucket serves a public
  presigned URL.
- It is a single interferogram (ref 2008-10-12 / sec 2008-11-27): enough to
  validate single-product parsing, not a full `smallbaselineApp` time series.

## Usage

```bash
./download_gunw.sh              # fetch the ~252 MB sample into ./data/
python run_validation.py        # run prep_nisar readers, write validation log
```

`run_validation.py` needs a MintPy install with GDAL. Point it at the fork's
environment, e.g.:

```bash
/path/to/MintPy/.venv/bin/python run_validation.py
```

## Layout

- `download_gunw.sh` — fetch the sample product (idempotent; skips if present).
- `run_validation.py` — run `prep_nisar` readers against the real file and
  emit `reports/validation.md`.
- `data/` — downloaded `.h5` products (untracked).
- `reports/validation.md` — committed validation evidence (tracked; the sample
  product is deterministic so the report is machine-independent).
