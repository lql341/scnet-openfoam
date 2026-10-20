#!/usr/bin/env bash
# Probe compiler, MPI and serial-PSTL prerequisites on a compute node.
set -euo pipefail

: "${OPENFOAM_RUN_ROOT:?set a writable probe root}"
toolchain="${FOAM_TOOLCHAIN:-gcc11}"
probe="$OPENFOAM_RUN_ROOT/probe-${toolchain}-${SLURM_JOB_ID:-manual-$$}"
mkdir -p "$probe"
exec > >(tee "$probe/toolchain.log") 2>&1

module purge
case "$toolchain" in
    gcc11)
        module load openmpi/5.0.11
        if [ -n "${GCC11_PREFIX:-}" ]; then
            export PATH="$GCC11_PREFIX/bin:$PATH"
            export LD_LIBRARY_PATH="$GCC11_PREFIX/lib64:${LD_LIBRARY_PATH:-}"
            export CC="$GCC11_PREFIX/bin/gcc" CXX="$GCC11_PREFIX/bin/g++"
            export FC="$GCC11_PREFIX/bin/gfortran"
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

echo "host=$(hostname)"
echo "toolchain=$toolchain"
gcc --version | head -1
g++ --version | head -1
mpicc --showme:command 2>&1 || true
mpicxx --showme:command 2>&1 || true

cat > "$probe/mpi_probe.c" <<'EOF'
#include <mpi.h>
int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    MPI_Finalize();
    return 0;
}
EOF
cat > "$probe/pstl_probe.cpp" <<'EOF'
#include <algorithm>
#include <execution>
#include <numeric>
#include <vector>
int main() {
    std::vector<int> v(1024, 1);
    std::sort(std::execution::par, v.begin(), v.end());
    return std::accumulate(v.begin(), v.end(), 0) == 1024 ? 0 : 1;
}
EOF
cat > "$probe/mpi_cpp_probe.cpp" <<'EOF'
#include <algorithm>
#include <execution>
#include <mpi.h>
#include <vector>
int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    std::vector<int> v(32, 1);
    std::sort(std::execution::par, v.begin(), v.end());
    MPI_Finalize();
    return v[0] == 1 ? 0 : 1;
}
EOF

mpicc "$probe/mpi_probe.c" -o "$probe/mpi_probe"
g++ -std=c++17 -D_PSTL_PAR_BACKEND_SERIAL \
    "$probe/pstl_probe.cpp" -o "$probe/pstl_probe"
mpicxx -std=c++17 -D_PSTL_PAR_BACKEND_SERIAL \
    "$probe/mpi_cpp_probe.cpp" -o "$probe/mpi_cpp_probe"
"$probe/mpi_probe"
"$probe/pstl_probe"
"$probe/mpi_cpp_probe"
echo "probe_rc=0"
