#!/usr/bin/env bash
# Run a short cavity tutorial against an accepted installation.
# Required: FOAM_INSTALL_ROOT and OPENFOAM_RUN_ROOT.
#SBATCH --job-name=scnet_foam_smoke
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=00:30:00
set -o pipefail

: "${FOAM_INSTALL_ROOT:?set the accepted OpenFOAM tree}"
: "${OPENFOAM_RUN_ROOT:?set a writable validation root}"
toolchain="${FOAM_TOOLCHAIN:-gcc11}"
job_id="${SLURM_JOB_ID:-manual-$$}"
foam="$FOAM_INSTALL_ROOT"
case_root="$OPENFOAM_RUN_ROOT/validation/cavity-${toolchain}-${job_id}"
source_case="$foam/tutorials/incompressible/icoFoam/cavity/cavity"

module purge
case "$toolchain" in
    gcc11)
        module load openmpi/5.0.11
        if [ -n "${GCC11_PREFIX:-}" ]; then
            export PATH="$GCC11_PREFIX/bin:$PATH"
            export LD_LIBRARY_PATH="$GCC11_PREFIX/lib64:${LD_LIBRARY_PATH:-}"
            export OMPI_CC="$GCC11_PREFIX/bin/gcc"
            export OMPI_CXX="$GCC11_PREFIX/bin/g++"
            export OMPI_FC="$GCC11_PREFIX/bin/gfortran"
        fi
        ;;
    gcc16)
        module load compiler/dtk/26.04 openmpi/5.0.11
        ;;
    *)
        echo "unsupported FOAM_TOOLCHAIN=$toolchain" >&2
        exit 2
        ;;
esac

cd "$foam"
source etc/bashrc
export WM_MPLIB=SYSTEMOPENMPI
export FOAM_EXTRA_CXXFLAGS="-D_PSTL_PAR_BACKEND_SERIAL"
mkdir -p "$case_root"
cp -a "$source_case"/. "$case_root"
sed -i 's/^endTime[[:space:]]*0.5;/endTime         0.05;/' \
    "$case_root/system/controlDict"
cd "$case_root"

set +e
blockMesh > blockMesh.log 2>&1
blockmesh_rc=$?
icoFoam > icoFoam.log 2>&1
icofoam_rc=$?
foamInstallationTest > installation-repeat.log 2>&1
repeat_rc=$?
set -e

printf 'blockMesh_rc=%s\n' "$blockmesh_rc"
printf 'icoFoam_rc=%s\n' "$icofoam_rc"
printf 'installation_repeat_rc=%s\n' "$repeat_rc"
test "$blockmesh_rc" -eq 0
test "$icofoam_rc" -eq 0
test "$repeat_rc" -eq 0
grep -q "End" icoFoam.log
exit 0
