#!/bin/bash

set -e

docker compose exec -T db psql -U stephen -d thermal-gradient -c "TRUNCATE staging"

for file in $(find data -name oil_level_data.json); do
    echo "Loading $file"
    jq -c '.[]' "$file" | docker compose exec -T db psql -U stephen -d thermal-gradient -c "COPY staging (input_data) FROM STDIN WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')"
done