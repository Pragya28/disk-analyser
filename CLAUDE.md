# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`diskscan` is a Go disk analyser (Coding Challenge #145). The repo currently holds only `ROADMAP.md`, which is the source of truth for scope, phase order and the planned package layout. No Go code, `go.mod` or Makefile exists yet; check the roadmap's phase checkboxes for progress.

## How to work here

This is a learn-Go-as-you-go project. The user writes all Go code. Explain concepts and discuss the implementation, draw workflow diagrams where useful, then review what the user wrote. Do not write Go implementations unless asked. Non-Go files (shell scripts, Makefile, CI workflows, docs, config) can be written directly.

## Planned commands (Phase 0, not yet created)

- `make build`: `go build -o bin/diskscan ./cmd/diskscan`
- `make test`: `go test ./...`; single test: `go test ./internal/treemap -run TestName`
- `make fixture`: rebuilds the `testroot` fixture tree (shell script, macOS/Linux)

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
