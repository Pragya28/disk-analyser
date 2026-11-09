# diskscan: Roadmap (Coding Challenge #145, Disk Analyser)

Challenge: [Coding Challenge #145 - Disk Analyser](https://codingchallenges.substack.com/p/coding-challenge-145-disk-analyser) by John Crickett

Decisions so far
- Language: Go. Terminal UI with Bubble Tea first, optional browser view (`--serve`) last.
- Platforms: macOS first (develop and test here), then Windows (PowerShell), then Linux.
- Inspiration: the existing storage monitor (`smart_storage_monitor.sh`). diskscan becomes its drill-down and replaces its `rm -rf` cleanup.
- Deliverable: one executable per OS, `diskscan <path>`, plus `--json` for headless use.

## Layout

```
cmd/diskscan/          entry point, flags
internal/scan/         walker, concurrency, progress events
internal/measure/      rollups, percentages, hard-link dedup
internal/treemap/      squarified layout (pure, unit-tested)
internal/ui/           Bubble Tea models and views
internal/rules/        reclaimable folder rules per OS (data)
internal/stage/        staged set, dedup totals
internal/clean/        review, re-checks, trash, report
internal/platform/     darwin.go, windows.go, linux.go behind one interface
```

Platform interface (the only OS-specific code):
- `AllocatedSize(info) int64`
- `FileID(info) (dev, id uint64, ok bool)`
- `MoveToTrash(path) error`
- `FreeSpace(path) (free, total int64, err error)`
- `ProtectedPaths() []string`

## Phase 0: Setup
- [ ] `go mod init`, repo, `internal/` layout above, `Makefile` or `Taskfile`
- [ ] `make fixture` builds the challenge `testroot` (macOS and Linux shell)
- [ ] Extra fixtures: symlink loop, file swapped for a directory, read-only dir
- [ ] Record `du -sk`, `df -h` and `diskutil apfs list` numbers for later comparison
- [ ] GitHub Actions matrix: macos-latest, windows-latest, ubuntu-latest running `go test ./...`

## Phase 1: Scan (Step 1)
- [ ] Walker using `Lstat` and `ReadDir` only, strictly read-only
- [ ] Non-fatal warnings (permission denied) collected with path; scan continues
- [ ] Item count matches `find testroot | wc -l` (allow for `locked/`)
- [ ] Before/after `shasum` check shows no change

## Phase 2: Measure (Step 2)
- [ ] Per file: allocated bytes (`Stat_t.Blocks * 512` on macOS/Linux) and apparent bytes
- [ ] Per directory: allocated, apparent, file count, newest descendant mtime
- [ ] Percent of parent and of whole scan per node
- [ ] Toggle disk usage / apparent size, always labelled
- [ ] `sparse.img`: about 1 GB apparent, about 0 allocated

## Phase 3: Correctness and speed (Step 3)
- [ ] Hard-link dedup by `dev:ino`; keep every name in file count
- [ ] Never follow symlinks; list them as links with zero size
- [ ] Bounded worker pool (goroutines) walking directories in parallel
- [ ] Live progress (items, bytes) via a channel into the UI
- [ ] `media` totals about 50 MB; `/usr` and home scans land close to `du -sk`
- [ ] Do not cross mount points by default (like `du -x`)

## Phase 4: Treemap layout (Step 4)
- [ ] Squarified layout as a pure function with table-driven tests
- [ ] Nested directories with a header row or border
- [ ] "Smaller items" group for rectangles below a minimum cell size
- [ ] Area ratios: `video.bin` about 5x `photo1.bin`, about 20x `photo2.bin`
- [ ] Hard link is not drawn as a second large rectangle
- [ ] Render with half-block characters for 2x vertical resolution; colour fills

## Phase 5: Navigation (Step 5)
- [ ] Selection with clear highlight; keyboard and mouse
- [ ] Open directory as root; breadcrumb and back
- [ ] Re-layout on `WindowSizeMsg`; no gaps or overlaps
- [ ] Breadcrumb jumps to top in one action

## Phase 6: Inspector (Step 6)
- [ ] Path, allocated, apparent, mtime, file count
- [ ] Size relative to parent ("40 MB, 80% of testroot/media")
- [ ] Largest children list; selecting one moves the selection

## Phase 7: Age view (Step 7)
- [ ] Bands (under 1 month, under 1 year, over 1 year) and legend
- [ ] Directory age from newest descendant
- [ ] `oldproject` test: old, then new after adding a fresh file and rescanning

## Phase 8: Largest files (Step 8)
- [ ] Ranked list by allocated size, scoped to the open directory
- [ ] Selecting an entry highlights it in the treemap
- [ ] Minimum size and minimum age filters
- [ ] Expected order on `testroot`: video.bin, big.js, archive.bin, cache.db

## Phase 9: Reclaimable detection (Step 9)
- [ ] Rules table in `internal/rules` (data, per OS)
- [ ] macOS: `~/Library/Caches`, Xcode DerivedData, brew cache, pnpm store, npm cache
- [ ] Everywhere: `node_modules`, `target`, `build`, `dist`, `.next`, `__pycache__`
- [ ] Mark in treemap; reclaimable total equals the sum of marked items
- [ ] Nothing staged or deleted in this phase

## Phase 10: Staging (Step 10)
- [ ] Mark and unmark; staged items look different
- [ ] Total without double counting (nested items, hard links)
- [ ] Current free space beside predicted free space (macOS: APFS container figure, labelled)
- [ ] Run the challenge's 15 MB, about 36 MB, unchanged, +40 MB sequence

## Phase 11: Review and safety (Step 11)
- [ ] Review screen with per-item removal and cancel
- [ ] Protected paths and outside-root paths refused (resolve symlinks via real path first)
- [ ] Re-check before each item: exists, same `dev:ino`, same kind
- [ ] Skip changed items and report why
- [ ] Run the `rm` and file-swapped-for-directory test

## Phase 12: Trash and report (Step 12)
- [ ] `MoveToTrash` on macOS via Finder (so "Put Back" works)
- [ ] Failed items reported as failed, never counted as reclaimed
- [ ] Rescan affected paths, refresh totals
- [ ] Report "moved to Trash" and "free space change" as separate numbers
- [ ] Read-only directory test; empty Trash and rescan test

## Phase 13: Storage monitor integration
- [ ] `diskscan scan <path> --json` writes the scan result for the monitor
- [ ] Fix the monitor's top-folders list (skip the `~/Library` total row) or read it from diskscan
- [ ] Report links to the folder that grew
- [ ] Replace both `rm -rf ~/Library/Caches/*` calls with a "review cleanup" notification
- [ ] Fix the noise filter so a persistently critical disk still alerts
- [ ] Do not trigger cleanup on spikes alone

## Phase 14: Windows (PowerShell)
- [ ] `AllocatedSize` via `GetCompressedFileSizeW`; `FileID` via file index and volume serial
- [ ] Treat junctions and reparse points like symlinks (no following)
- [ ] `\\?\` long path handling; per-drive roots
- [ ] Recycle Bin via `IFileOperation`; protected paths (`C:\Windows`, `C:\Program Files`)
- [ ] Rules for `%LOCALAPPDATA%` caches and `%TEMP%`
- [ ] CI on windows-latest, then one manual run on a real machine (Recycle Bin)
- [ ] Build `diskscan.exe` with `GOOS=windows`; test in Windows Terminal and PowerShell

## Phase 15: Linux
- [ ] freedesktop Trash (`files/` plus `.trashinfo`, per-volume `.Trash-<uid>`); refuse with a clear message where no Trash exists
- [ ] Skip `/proc`, `/sys`, `/dev`; do not cross mounts
- [ ] Protected paths: `/`, `/usr`, `/bin`, `/etc`, `/boot`, `/var`, `/lib`, resolved through symlinks
- [ ] Rules per distro family: apt, dnf, pacman caches; Snap and Flatpak
- [ ] Label allocated size vs free space on btrfs and ZFS
- [ ] Test Ubuntu, Fedora and Alpine in Docker; skip `/mnt/c` under WSL by default

## Phase 16 (optional): Browser view
- [ ] `diskscan --serve` embeds a React page with `go:embed`
- [ ] Bind to `127.0.0.1`; random per-run token; validate `Host` and `Origin`
- [ ] Same engine and same safety checks as the terminal UI
- [ ] Canvas treemap with hover and smooth zoom

## Release
- [ ] GoReleaser: macOS, Windows and Linux builds
- [ ] Homebrew tap, then Scoop or winget
- [ ] README with demo GIF, scan-time benchmark vs `du`, notes on APFS and allocated size
- [ ] Add to the Coding Challenges Shared Solutions repo

## Going further (from the challenge)
- [ ] Save and reopen scans; compare two scans (pairs well with the monitor's history)
- [ ] Search by name; rescan one folder; duplicate detection; "Empty Trash" with review
