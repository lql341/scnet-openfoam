#!/usr/bin/env bash
# Build OpenFOAM v2606 in a job-unique source/build tree.
# Required: OPENFOAM_SOURCE_ROOT, OPENFOAM_THIRDPARTY_ROOT,
# OPENFOAM_SRC_COMMIT and OPENFOAM_RUN_ROOT.
# Select with FOAM_TOOLCHAIN=gcc11 or gcc16.
#SBATCH --job-name=scnet_foam_build
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=03:00:00
set -o pipefail

: "${OPENFOAM_SOURCE_ROOT:?set the OpenFOAM Git source root}"
: "${OPENFOAM_THIRDPARTY_ROOT:?set the ThirdParty source root}"
: "${OPENFOAM_SRC_COMMIT:?set an immutable OpenFOAM commit}"
: "${OPENFOAM_RUN_ROOT:?set a writable unique-run root}"

toolchain="${FOAM_TOOLCHAIN:-gcc11}"
job_id="${SLURM_JOB_ID:-manual-$$}"
run="$OPENFOAM_RUN_ROOT/${toolchain}-${job_id}"
foam="$run/openfoam"
third="$run/ThirdParty-v2606"
buildroot="$run/buildroot"
log="$run/allwmake.log"
testlog="$run/foamInstallationTest.txt"

module purge
case "$toolchain" in
    gcc11)
        module load openmpi/5.0.11
        gcc_prefix="${GCC11_PREFIX:-}"
        if [ -n "$gcc_prefix" ]; then
            export PATH="$gcc_prefix/bin:$PATH"
            export LD_LIBRARY_PATH="$gcc_prefix/lib64:${LD_LIBRARY_PATH:-}"
            export CC="$gcc_prefix/bin/gcc" CXX="$gcc_prefix/bin/g++"
            export FC="$gcc_prefix/bin/gfortran"
            export OMPI_CC="$CC" OMPI_CXX="$CXX" OMPI_FC="$FC"
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

mkdir -p "$foam" "$third"
(cd "$OPENFOAM_SOURCE_ROOT" &&
    git archive --format=tar "$OPENFOAM_SRC_COMMIT") | tar -C "$foam" -xf -
tar -C "$OPENFOAM_THIRDPARTY_ROOT" -cf - sources/scotch etc | tar -C "$third" -xf -
test -f "$foam/Allwmake"
test -d "$third/sources/scotch"

cd "$foam"
source etc/bashrc
export PATH="$PWD/wmake:$PATH"
export WM_MPLIB=SYSTEMOPENMPI
export WM_THIRD_PARTY_DIR="$third"
export FOAM_THIRD_PARTY_BUILDROOT="$buildroot"
export FOAM_EXTRA_CXXFLAGS="-D_PSTL_PAR_BACKEND_SERIAL"
if [ "$toolchain" = gcc16 ]; then
    export WM_CFLAGS="$(wmake -show-cflags) -std=gnu17"
fi
mkdir -p "$buildroot"

{
    printf 'host=%s\n' "$(hostname)"
    printf 'job_id=%s\n' "$job_id"
    printf 'toolchain=%s\n' "$toolchain"
    printf 'gcc=%s\n' "$(gcc --version | head -1)"
    printf 'mpicc=%s\n' "$(mpicc --showme:command 2>/dev/null || true)"
    printf 'run=%s\n' "$run"
    printf 'FOAM_EXTRA_CXXFLAGS=%s\n' "$FOAM_EXTRA_CXXFLAGS"
    printf 'WM_CFLAGS=%s\n' "${WM_CFLAGS:-default}"
} | tee "$run/environment.txt"

set +e
./Allwmake -j "${SLURM_CPUS_PER_TASK:-8}" -s -q -l >"$log" 2>&1
allwmake_rc=$?
foamInstallationTest >"$testlog" 2>&1
install_rc=$?
set -e

printf 'allwmake_rc=%s\n' "$allwmake_rc" | tee "$run/result.txt"
printf 'installation_test_rc=%s\n' "$install_rc" | tee -a "$run/result.txt"
if [ -x "$FOAM_APPBIN/icoFoam" ]; then
    printf 'icoFoam=present\n' | tee -a "$run/result.txt"
else
    printf 'icoFoam=missing\n' | tee -a "$run/result.txt"
fi

if grep -Eiq "(error:|fatal error|CMake Error|command not found|No such file)" \
    "$log" "$testlog" 2>/dev/null; then
    echo "error_markers=present" | tee -a "$run/result.txt"
    exit 2
fi
if [ "$allwmake_rc" -ne 0 ] || [ "$install_rc" -ne 0 ] ||
   [ ! -x "$FOAM_APPBIN/icoFoam" ]; then
    exit 3
fi
echo "error_markers=absent" | tee -a "$run/result.txt"
exit 0
