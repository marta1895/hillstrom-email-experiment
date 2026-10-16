.PHONY: all extract validate transform load test

all: extract validate transform load

extract:
	python -m pipeline.extract

validate:
	python -m pipeline.validate

transform:
	python -m pipeline.transform

load:
	python -m pipeline.load

test:
	pytest
