# Peak-2-Peak: Thermal Gradient Analysis in SQL

Vertical temperature gradient analysis of oil-filled transformers, rebuilt in PostgreSQL.

> Placeholder README. Sections marked TODO get written once the analysis is validated.

## Overview

Four transformers were monitored in Newfoundland from January to June 2026. Each unit carries a
16-thermistor vertical array reading the oil temperature from the bottom of the oil column to the
top at 0.25 inch spacing. This project models that data in PostgreSQL and quantifies the vertical
thermal gradient using analytical SQL.

The work was first done in Python and pandas. This version rebuilds it in SQL to demonstrate
schema design, bulk ingestion and analytical queries against a real dataset.

TODO: one paragraph on the headline finding once reproduced in SQL.

## Finding

TODO: short outcome-framed summary. Lead with the number. The pandas result to reproduce is the
mean vertical gradient per transformer in degrees C per inch.

## Approach

Structured along staging then model then analysis lines, the standard analytics-engineering
layering, implemented in plain SQL rather than a framework.

- Raw JSON lands whole in a staging table, one object per row.
- SQL transforms staging into a normalised model of transformers, sensors and readings.
- Analytical queries compute the gradients, deltas and time-of-day patterns.

## Tech stack

- PostgreSQL, running in Docker for reproducibility (version pinned in `docker-compose.yml`)
- SQL for all transformation and analysis
- Bash loader script for bulk ingest via COPY

## Structure

```
peak2peak-sql/
  docker-compose.yml     reproducible Postgres instance
  .env.example           template for local credentials
  sql/
    01_schema.sql        staging table plus the three modelled tables
    02_load.sql          transform staging into readings
    03_analysis/         analytical queries, numbered
  scripts/
    load.sh              loop over the raw files, COPY each
  data/                  raw JSON (gitignored, not shipped)
  README.md
```

## Running it

TODO: fill in once the compose file and loader exist. Rough shape:

1. copy `.env.example` to `.env` and set a local password
2. `docker compose up -d` to start Postgres
3. run `sql/01_schema.sql` to build the tables
4. run `scripts/load.sh` to ingest the raw data
5. run `sql/02_load.sql` to transform staging into readings
6. run the queries in `sql/03_analysis/`

## Data

The raw thermistor data is IFD client IP and is not included in this repository. The schema,
loader and queries are shown in full. Sample or anonymised data available on request.

## Notes

British and NZ spelling throughout.
