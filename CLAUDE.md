# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`diskscan` is a Go disk analyser (Coding Challenge #145, module `github.com/Pragya28/diskscan`). `ROADMAP.md` is the source of truth for scope, phase order and the package layout; check its phase checkboxes for progress. Phase 0 scaffolding is in place: `go.mod`, an empty package per `internal/` dir (each just a `doc.go`), a stub `cmd/diskscan/main.go`, `Makefile`, `scripts/fixture.sh`, `docs/baseline.txt` and `.github/workflows/ci.yml`. There is no real logic yet.

## How to work here

This is a learn-Go-as-you-go project. The user writes all Go code. Explain concepts and discuss the implementation, draw workflow diagrams where useful, then review what the user wrote. Do not write Go implementations unless asked. Non-Go files (shell scripts, Makefile, CI workflows, docs, config) can be written directly.

## Commands

- `make build`: `go build -o bin/diskscan ./cmd/diskscan`
- `make test`: `go test ./...`; single test: `go test ./internal/treemap -run TestName`
- `make fixture`: deletes and rebuilds the git-ignored `testroot/` (the challenge tree plus `oldproject/`, `readonly/` and a `loop` symlink; macOS/Linux shell). Includes a `chmod 000` dir, so `rm -rf testroot` alone fails; use the script.
- `docs/baseline.txt` holds reference `du -sk`, `df -h` and APFS numbers (`testroot` is 34 entries from `find`, 107532 KB from `du -sk`) to compare scanner output against.
- CI (`.github/workflows/ci.yml`) runs `go build` and `go test` on macOS only; add `ubuntu-latest` in Phase 15 and `windows-latest` in Phase 14, when their `internal/platform` files exist.

## Architecture (from the roadmap)

- `internal/platform/` is the only OS-specific code (`darwin.go`, `windows.go`, `linux.go` behind one interface): `AllocatedSize`, `FileID`, `MoveToTrash`, `FreeSpace`, `ProtectedPaths`. Everything else must stay OS-neutral.
- Pipeline: `scan` (read-only walker, `Lstat` + `ReadDir`, never follows symlinks, bounded worker pool, progress over a channel) feeds `measure` (rollups, percentages, hard-link dedup by `dev:ino`) feeds `treemap` (pure squarified layout, table-driven tests) and `ui` (Bubble Tea).
- Cleanup path: `rules` (reclaimable-folder data per OS) feeds `stage` (staged set, no double counting) feeds `clean` (review, re-check `exists + same dev:ino + same kind` before each item, move to Trash, report). The scan phase must never modify the filesystem.
- Reported sizes are always labelled allocated (blocks * 512) vs apparent; the two differ for sparse files and APFS.
- Safety: resolve symlinks to real paths before checking protected or outside-root paths; failed deletions are never counted as reclaimed.
- Deliverable: one binary per OS, `diskscan <path>`, plus `--json` for headless use by the user's storage monitor script (`smart_storage_monitor.sh`, outside this repo).

## Conventions

- macOS is developed and tested first, then Windows, then Linux.
- Do not run build, lint, test or other shell commands without asking, and ask before creating a git branch (see global rules).
