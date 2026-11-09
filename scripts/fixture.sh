#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

chmod -R u+rwx testroot 2>/dev/null || true
rm -rf testroot

# --- challenge tree ---
mkdir -p testroot/docs testroot/media testroot/old testroot/locked
mkdir -p testroot/projects/webapp/src testroot/projects/webapp/node_modules/lib
mkdir -p testroot/projects/api/target testroot/.cache/app

head -c 5242880  /dev/urandom > testroot/docs/report.pdf
echo "some notes" > testroot/docs/notes.txt
head -c 41943040 /dev/urandom > testroot/media/video.bin
head -c 8388608  /dev/urandom > testroot/media/photo1.bin
head -c 2097152  /dev/urandom > testroot/media/photo2.bin
ln testroot/media/video.bin testroot/media/video-link.bin
ln -s ../media testroot/docs/media-link
echo "console.log('hi')" > testroot/projects/webapp/src/app.js
head -c 20971520 /dev/urandom > testroot/projects/webapp/node_modules/lib/big.js
head -c 1048576  /dev/urandom > testroot/projects/webapp/node_modules/lib/other.js
head -c 3145728  /dev/urandom > testroot/projects/api/target/api.bin
head -c 10485760 /dev/urandom > testroot/.cache/app/cache.db
head -c 15728640 /dev/urandom > testroot/old/archive.bin
touch -t 201901010000 testroot/old/archive.bin
truncate -s 1G testroot/sparse.img
echo "secret" > testroot/locked/hidden.txt

# --- later-step fixtures ---
mkdir -p testroot/oldproject
echo "old" > testroot/oldproject/a.txt
touch -t 201801010000 testroot/oldproject/a.txt testroot/oldproject
mkdir testroot/readonly
head -c 1048576 /dev/urandom > testroot/readonly/file.bin
chmod 555 testroot/readonly

# --- extra edge cases ---
ln -s . testroot/loop

chmod 000 testroot/locked
echo "testroot ready"
