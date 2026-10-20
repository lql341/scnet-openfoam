#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for script in "$root"/scripts/*.sh "$root"/scripts/*.sbatch; do
    bash -n "$script"
done

if grep -RInE '/public/home/|/home/[A-Za-z0-9_.-]+/' \
    "$root"/README* "$root"/references \
    "$root"/scripts/openfoam_*.sh "$root"/scripts/openfoam_*.sbatch; then
    echo "private absolute path found" >&2
    exit 1
fi

echo "repository validation passed"
