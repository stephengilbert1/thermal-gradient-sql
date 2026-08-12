# Variables so credentials aren't repeated in every line
DB_USER = stephen
DB_NAME = thermal-gradient
PSQL = docker compose exec -T db psql -U $(DB_USER) -d $(DB_NAME)
DATA ?= data/sample

.PHONY: up sample schema load transform validate export analyze all clean

up:
	docker compose up -d

sample:
	python scripts/generate_sample_data.py

schema:
	$(PSQL) -f /sql/01_schema.sql

load:
	./scripts/load.sh $(DATA)

transform:
	$(PSQL) -f /sql/02_load.sql

validate:
	$(PSQL) -f /sql/tests/validation.sql

analyze:
	$(PSQL) -f /sql/03_analysis/01_gradient_validation.sql

export:
	$(PSQL) -f /sql/04_export.sql


all: up sample schema load transform validate export
	@echo "Pipeline complete."

clean:
	docker compose down -v