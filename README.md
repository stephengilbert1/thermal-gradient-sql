# Vertical Temperature Gradient Analysis in SQL

Characterizing how oil temperature varies from bottom to top in oil-filled transformers, rebuilt in PostgreSQL from raw JSON telemetry. This is a SQL port of an earlier pandas analysis, done to develop analytical SQL against a real dataset.

## The finding

Oil temperature increases steadily from the bottom of the tank to the top across all four transformers. This is consistent with normal convective circulation. The size of the increase varies by transformer from roughly 1.1 to 1.7°C per inch of oil.

This SQL rebuild reproduces the per-transformer gradient figures from the original pandas analysis. Reproducing that result was the point. It is the proof the rebuild is faithful.

## Why SQL

The analysis already exists in pandas. This version rebuilds it in PostgreSQL to show the same result reached a different way. The parts a notebook workflow never touches are the interesting parts here. Modelling the data into proper tables. Loading a million rows off raw files. Doing the transformation and the analysis in SQL rather than a DataFrame.

## The data

Four transformers (0002180, 0002181, 0002184, 0002190), Jan-Jun 2026. Each has 16 thermistors, TX_00 at the bottom of the oil volume to TX_15 at the top, spaced 0.25" apart, logged as JSON. Roughly 924,000 readings, which explode to 14.8 million positioned rows once each 16-element array is unpacked.

Raw data is excluded from this repository due to confidentiality. The schema, loader and queries are shown in full. The pipeline is reproducible against equivalent data.

## One hardware issue corrected in the transform

**0002181** was physically installed with its sensor array upside down. This was confirmed on site. It shows up as the only transformer with a negative gradient where the other three are positive. It is corrected in the load step by flipping the position index for that unit only, so the modelled data is canonical and every downstream query treats all four transformers the same. The correction lives in one place rather than being repeated in every query.

## How it's put together

The project follows a staging then model then analysis layering. Raw JSON lands untouched, SQL transforms it into a clean relational model, and the analysis runs on that model.

1. **Schema** (`sql/01_schema.sql`). A staging table for raw JSON, then three modelled tables. `transformers` is the spine. `sensors` is a position to height lookup with a submerged flag. `readings` is the fact table, one row per sensor per timestamp, with foreign keys back to the other two.
2. **Ingest** (`scripts/load.sh`). Finds every source file, reshapes each pretty-printed JSON array into one object per line with `jq`, and streams it into staging with `COPY`.
3. **Transform** (`sql/02_load.sql`). Explodes each JSON temperature array into 16 positioned rows using `jsonb_array_elements WITH ORDINALITY`, converts the epoch timestamp, applies the 0002181 correction, and populates the model.
4. **Analysis** (`sql/03_analysis/`). Queries against the modelled tables. The gradient validation query joins readings to sensors to compute the per-transformer bottom-to-top gradient and reproduces the pandas result.

## Running it

Postgres runs in Docker so the whole thing is reproducible.

1. Copy `.env.example` to `.env` and set a password
2. `docker compose up -d` to start Postgres
3. `docker compose exec -T db psql -U <user> -d <db> -f /sql/01_schema.sql` to build the tables
4. `./scripts/load.sh` to ingest the raw data into staging
5. `docker compose exec -T db psql -U <user> -d <db> -f /sql/02_load.sql` to transform staging into the model
6. run the queries in `sql/03_analysis/`

## Structure

```
docker-compose.yml     reproducible Postgres instance
.env.example           template for local credentials
sql/
  01_schema.sql        staging table plus the three modelled tables
  02_load.sql          transform staging into the model
  03_analysis/         analytical queries
scripts/
  load.sh              reshape and load the raw files into staging
data/                  raw JSON, excluded from the repo
```

## Tools

PostgreSQL 18 in Docker. `jq` for the JSON reshape. Bash for the loader. That is the whole stack.

## Next

More analytical queries. Rate of change and moving averages using window functions. Inversion frequency broken down by time of day. A percentile view of when the gradient is steepest.
