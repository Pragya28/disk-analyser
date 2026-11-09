.PHONY: build test fixture

build:
	go build -o bin/diskscan ./cmd/diskscan

test:
	go test ./...

fixture:
	bash scripts/fixture.sh