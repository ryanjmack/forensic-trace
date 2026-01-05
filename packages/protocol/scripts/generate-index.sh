#!/bin/bash
set -e

# Context: Run from repo root or package root, this handles it.
cd "$(dirname "$0")/.."

SRC_DIR="src"
OUT_FILE="src/index.ts"

echo "// generated file. do not edit." > "$OUT_FILE"

# Find all .ts files (excluding index.ts), strip path/extension, and export
find "$SRC_DIR" -name "*.ts" ! -name "index.ts" -exec basename {} .ts \; | \
    sort | \
    xargs -I {} echo "export * from './{}';" >> "$OUT_FILE"
