#!/usr/bin/env python3
"""Validate mintpy.prep_nisar against a real NISAR GUNW sample product.

Runs the GDAL-free parsing layer (frequency resolution, required-path
discovery, metadata extraction) against the downloaded sample GUNW and writes
a Markdown validation log. The log is the manual evidence cited by the
upstream unit-test PR: it confirms that the synthetic h5py fixtures in
``tests/test_prep_nisar.py`` match the real file's schema.

Run with a MintPy environment that has GDAL, e.g.::

    /path/to/MintPy/.venv/bin/python run_validation.py
"""

import glob
import os

import h5py

from mintpy import prep_nisar

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(HERE, "data")
REPORT_DIR = os.path.join(HERE, "reports")

# The synthetic fixtures assume these radarGrid datasets exist in a real GUNW.
EXPECTED_RADARGRID = "science/LSAR/GUNW/metadata/radarGrid"


def find_gunw():
    files = sorted(glob.glob(os.path.join(DATA_DIR, "*GUNW*.h5")))
    if not files:
        raise SystemExit(
            "No GUNW sample found in data/. Run ./download_gunw.sh first."
        )
    return files[0]


def list_radargrid(gunw):
    with h5py.File(gunw, "r") as ds:
        grp = ds.get(EXPECTED_RADARGRID)
        if grp is None:
            return []
        return sorted(grp.keys())


def main():
    os.makedirs(REPORT_DIR, exist_ok=True)
    gunw = find_gunw()

    lines = []
    lines.append("# NISAR GUNW real-data validation log\n")
    lines.append(f"- Sample file: `{os.path.basename(gunw)}`")
    size_mb = os.path.getsize(gunw) / 1e6
    lines.append(f"- Size: {size_mb:.1f} MB\n")

    # 1) radarGrid datasets present in the real file (issue #1485 sanity)
    rg = list_radargrid(gunw)
    lines.append("## radarGrid datasets present\n")
    lines.append("```")
    lines.extend(f"- {name}" for name in rg)
    lines.append("```")
    has_ref = "referenceSlantRange" in rg
    lines.append(
        f"\n- `referenceSlantRange` present: **{has_ref}** "
        f"(reader depends on this — issue #1485)"
    )
    lines.append(f"- bare `slantRange` present: **{'slantRange' in rg}**\n")

    # 2) frequency resolution against the real file
    freq = prep_nisar._resolve_frequency(gunw, None, "HH")
    lines.append("## frequency resolution\n")
    lines.append(f"- `_resolve_frequency(auto, HH)` -> `{freq}`\n")

    # 3) required-path discovery for each stack type
    lines.append("## required-path discovery\n")
    for stack_type in ["ifgram", "ion", "tropo", "set"]:
        missing = prep_nisar._missing_required_paths([gunw], stack_type, "HH", freq)
        status = "OK" if not missing else f"MISSING {len(missing)}"
        lines.append(f"- {stack_type}: {status}")
        for _f, path in missing:
            lines.append(f"    - {path}")
    lines.append("")

    # 4) metadata extraction (the #1485 target)
    meta, bounds = prep_nisar.extract_metadata([gunw])
    lines.append("## extract_metadata\n")
    lines.append("```")
    for key in [
        "EPSG", "X_UNIT", "UTM_ZONE", "WAVELENGTH", "ORBIT_DIRECTION",
        "POLARIZATION", "PLATFORM", "STARTING_RANGE", "CENTER_LINE_UTC",
        "ALOOKS", "RLOOKS", "LENGTH", "WIDTH", "X_STEP", "Y_STEP",
        "HEIGHT", "EARTH_RADIUS",
    ]:
        if key in meta:
            lines.append(f"{key} = {meta[key]}")
    lines.append("```")
    lines.append(f"\n- bounds: {bounds}")

    report = "\n".join(lines) + "\n"
    out = os.path.join(REPORT_DIR, "validation.md")
    with open(out, "w") as fh:
        fh.write(report)

    print(report)
    print(f"\nWritten: {out}")


if __name__ == "__main__":
    main()
