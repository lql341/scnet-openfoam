#!/usr/bin/env bash
# Check an accepted installation from a clean shell, twice for idempotency,
# and from a job-unique read-only hard-link relocation tree.
# Required: FOAM_INSTALL_ROOT and OPENFOAM_RUN_ROOT.
#SBATCH --job-name=scnet_foam_post
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00
set -euo pipefail

: "${FOAM_INSTALL_ROOT:?set the accepted OpenFOAM tree}"
: "${OPENFOAM_RUN_ROOT:?set a writable validation root}"
job_id="${SLURM_JOB_ID:-manual-$$}"
post="$OPENFOAM_RUN_ROOT/post-${job_id}"
reloc="$post/openfoam-relocated"
mkdir -p "$post"

run_test() {
    local label=$1 root=$2
    bash -c "cd '$root' && source etc/bashrc && foamInstallationTest" \
        >"$post/${label}.log" 2>&1
    grep -q "Done" "$post/${label}.log"
}

run_test clean-install "$FOAM_INSTALL_ROOT"
run_test idempotent-1 "$FOAM_INSTALL_ROOT"
run_test idempotent-2 "$FOAM_INSTALL_ROOT"
cp -al "$FOAM_INSTALL_ROOT" "$reloc"
run_test relocation "$reloc"

printf 'clean_install=passed\n'
printf 'idempotency=passed\n'
printf 'relocation=passed\n'
