#!/bin/bash

# Loads raw oil-level JSON into the staging table.
# Usage: ./scripts/load.sh [DATA_ROOT]

set -e

DATA_ROOT="${1:-data/sample}"
 
if [ ! -d "$DATA_ROOT" ]; then
    echo "Data root not found: $DATA_ROOT" >&2
    exit 1
fi
 
docker compose exec -T db psql -U stephen -d thermal-gradient -c "TRUNCATE staging"
 
count=0
for file in $(find "$DATA_ROOT" -name oil_level_data.json); do
    echo "Loading $file"
    jq -c '.[]' "$file" | docker compose exec -T db psql -U stephen -d thermal-gradient -c "COPY staging (input_data) FROM STDIN WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')"
    count=$((count + 1))
done
 
echo "Done. Loaded $count files from $DATA_ROOT."
 