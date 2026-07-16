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

This project uses its **own** isolated virtualenv (`.venv/`), separate from
the fork's GPU venv. numpy is pinned to the 1.x series in `requirements.txt`
so the system GDAL Python bindings (compiled against NumPy 1.x) import
without the NumPy 2.x `_ARRAY_API` ABI warning. Set it up once:

```bash
# 1. isolated env + the parent MintPy fork (editable), resolved with numpy<2
uv venv --python 3.12 .venv
uv pip install -r requirements.txt -e ..

# 2. expose the system GDAL Python bindings (pip GDAL can't build here);
#    Debian/Ubuntu ships them under the system interpreter.
ln -sfn "$(python3 -c 'import osgeo, os; print(os.path.dirname(osgeo.__file__))')" \
    .venv/lib/python3.12/site-packages/osgeo
```

Then run the validation:

```bash
./download_gunw.sh                 # fetch the ~252 MB sample into ./data/
.venv/bin/python run_validation.py # run prep_nisar readers, write the log
```

A clean run prints nothing on stderr and writes `reports/validation.md`.

## Layout

- `requirements.txt` — PyPI deps for the isolated `.venv` (numpy pinned <2).
- `download_gunw.sh` — fetch the sample product (idempotent; skips if present).
- `run_validation.py` — run `prep_nisar` readers against the real file and
  emit `reports/validation.md`.
- `data/` — downloaded `.h5` products (untracked).
- `.venv/` — isolated validation env (untracked; recreate from the steps above).
- `reports/validation.md` — committed validation evidence (tracked; the sample
  product is deterministic so the report is machine-independent).
