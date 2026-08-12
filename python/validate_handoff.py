# validate_handoff.py

import pandas as pd

df = pd.read_csv('exports/readings_15mins.csv',
                 parse_dates=['interval_15min'],
                 dtype={'device_serial': str})

wide = df.pivot_table(index=['device_serial','interval_15min'], columns='position_index', values='avg_temp')

wide['gradient'] = (wide[8] - wide[0]) / 2.0
result = wide.groupby('device_serial')['gradient'].mean()

expected = {
    '0002180': 1.57,
    '0002181': 1.24,
    '0002184': 1.08,
    '0002190': 1.73,
}

for serial, expected_grad in expected.items():
    actual = result[serial]
    assert abs(actual - expected_grad) < 0.05, f"{serial}: expected ~{expected_grad}, got {actual:.2f}"
    print(f"{serial}: {actual:.2f} OK")

print("Handoff validated: SQL export reproduces the pandas gradients.")