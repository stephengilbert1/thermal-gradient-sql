"""Generate synthetic thermistor data structurally identical to the real files.

Writes fake oil_level_data.json files into data/sample/<month>/<serial>/ so the
existing loader and SQL pipeline run on them unchanged. The synthetic data has a
realistic vertical gradient and reproduces the 0002181 inversion, so the whole
pipeline including the correction can be demonstrated without the confidential data.
"""

import json
import math
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --- Config ---------------------------------------------------------------

SERIALS = ["0002180", "0002181", "0002184", "0002190"]
INVERTED_SERIAL = "0002181"          # installed upside down, generate reversed
N_THERMISTORS = 16
SUBMERGED_TOP = 8                    # positions 0..8 in oil, 9..15 airspace

START = datetime(2026, 1, 1, tzinfo=timezone.utc)
DAYS = 14                            # two weeks is plenty for every query
CADENCE_MIN = 15                     # one reading every 15 minutes

OUTPUT_ROOT = Path("data/sample")
FILENAME = "oil_level_data.json"

BASE_TEMP = 25.0                     # baseline bottom-of-oil temperature
PER_POSITION_STEP = 0.35            # C added per position up the submerged range
DAILY_SWING = 3.0                   # amplitude of the daily ambient wobble
NOISE = 0.1                          # small per-reading jitter


# --- Temperature model ----------------------------------------------------

def make_temperature_array(base):
    """Return a 16-element profile: rises through the oil, flattens in airspace.

    Replace this with your own version if you wrote one. This reference
    implementation ramps positions 0..SUBMERGED_TOP then holds flat above.
    """
    temps = []
    for pos in range(N_THERMISTORS):
        effective = min(pos, SUBMERGED_TOP)        # cap so airspace flattens
        t = base + effective * PER_POSITION_STEP
        t += random.uniform(-NOISE, NOISE)         # small measurement jitter
        temps.append(round(t, 1))
    return temps


def base_temp_at(ts):
    """Baseline bottom temperature with a daily sinusoidal swing.

    Peaks mid-afternoon, dips before dawn, using the hour of day to drive a
    sine wave of amplitude DAILY_SWING around BASE_TEMP.
    """
    # shift so the peak lands around 15:00 and the trough around 03:00
    phase = (ts.hour - 9) / 24.0 * 2 * math.pi
    return BASE_TEMP + DAILY_SWING * math.sin(phase)


def build_object(serial, ts):
    """Build one reading object matching the real JSON schema."""
    base = base_temp_at(ts)
    temps = make_temperature_array(base)

    # The real 0002181 is installed upside down: its array arrives reversed.
    # Generate it that way so the load-step CASE correction has something real
    # to correct and the whole pipeline can be demonstrated.
    if serial == INVERTED_SERIAL:
        temps = list(reversed(temps))

    epoch = int(ts.timestamp())
    return {
        "deviceID": 123,
        "deviceSerial": serial,
        "peripheralID": 2003668,
        "peripheralHardwareID": "SYNTHETIC0000000000000000",
        "timestamp": epoch,
        "reportTimestamp": epoch + 600,
        "temperatures": temps,
    }


# --- File writing ---------------------------------------------------------

def month_folder(ts):
    """Folder name like '2026-Jan-Oil-Level-Reports' to match the real layout."""
    return f"{ts.year}-{ts.strftime('%b')}-Oil-Level-Reports"


def serial_folder(serial):
    """Folder name like '2180-oil-level-report' (abbreviated serial, as real)."""
    return f"{serial.lstrip('0')}-oil-level-report"


def generate():
    """Loop serials and timestamps, group by month, write one JSON array per file."""
    # buckets[(month_name, serial)] -> list of reading dicts
    buckets = {}

    end = START + timedelta(days=DAYS)
    for serial in SERIALS:
        ts = START
        while ts < end:
            key = (month_folder(ts), serial)
            buckets.setdefault(key, []).append(build_object(serial, ts))
            ts += timedelta(minutes=CADENCE_MIN)

    files_written = 0
    for (month, serial), objects in buckets.items():
        out_dir = OUTPUT_ROOT / month / serial_folder(serial)
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / FILENAME
        with open(out_path, "w") as f:
            json.dump(objects, f, indent=4)
        files_written += 1
        print(f"Wrote {len(objects):>5} readings to {out_path}")

    return files_written


if __name__ == "__main__":
    n = generate()
    print(f"Done. {n} synthetic files written under {OUTPUT_ROOT}.")