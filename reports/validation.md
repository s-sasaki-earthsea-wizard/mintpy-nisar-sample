# NISAR GUNW real-data validation log

- Sample file: `NISAR_L2_PR_GUNW_001_030_A_019_002_2000_SH_20081012T060911_20081012T060925_20081127T061000_20081127T061014_D00404_N_F_J_001.h5`
- Size: 264.2 MB

## radarGrid datasets present

```
- alongTrackUnitVectorX
- alongTrackUnitVectorY
- elevationAngle
- groundTrackVelocity
- heightAboveEllipsoid
- hydrostaticTroposphericPhaseScreen
- incidenceAngle
- losUnitVectorX
- losUnitVectorY
- parallelBaseline
- perpendicularBaseline
- projection
- referenceSlantRange
- referenceZeroDopplerAzimuthTime
- secondarySlantRange
- secondaryZeroDopplerAzimuthTime
- slantRangeSolidEarthTidesPhase
- wetTroposphericPhaseScreen
- xCoordinates
- yCoordinates
```

- `referenceSlantRange` present: **True** (reader depends on this — issue #1485)
- bare `slantRange` present: **False**

## frequency resolution

- `_resolve_frequency(auto, HH)` -> `frequencyA`

## required-path discovery

- ifgram: OK
- ion: OK
- tropo: OK
- set: OK

## extract_metadata

```
EPSG = 32611
X_UNIT = meters
UTM_ZONE = 11N
WAVELENGTH = 0.2360571
ORBIT_DIRECTION = Ascending
POLARIZATION = HH
PLATFORM = ALOS
STARTING_RANGE = 727292.133148024
CENTER_LINE_UTC = 22158.658223
ALOOKS = 17
RLOOKS = 7
LENGTH = 1555
WIDTH = 1136
X_STEP = 80.0
Y_STEP = -80.0
HEIGHT = 747000
EARTH_RADIUS = 6371008.8
```

- bounds: [365520.0, 3789260.0, 456320.0, 3913580.0]
