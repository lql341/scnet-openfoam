# OpenFOAM validation model

This skill separates a one-time source/toolchain acceptance from routine
regression. The former may run the complete `Allwmake`; the latter reuses an
accepted installation.

## Isolation

Create a job-unique run directory containing a fresh source archive, a minimal
ThirdParty snapshot (`sources/scotch` and `etc`), a private buildroot, logs and
validation cases. Do not copy generated `build`, `platforms` or `lnInclude`
from another toolchain.

## Toolchain facts observed on Kunshan

- OpenFOAM v2606 requires a modern GCC; the system GCC 4.8.5 is unsuitable.
- OpenMPI 5.0.11 can be directed to GCC11 with `OMPI_CC`, `OMPI_CXX` and
  `OMPI_FC`.
- The available old TBB conflicts with the GCC11/GCC16 libstdc++ PSTL backend.
  `-D_PSTL_PAR_BACKEND_SERIAL` passed the MPI/PSTL probes and core builds.
- GCC16 Scotch 6.1.0 C sources need `-std=gnu17` for the incompatible function
  pointer diagnostics observed on that site.
- Old CMake can reject optional KAHIP/ADIOS2 components. Report those separately
  from core OpenFOAM success.

These are observations from one site and version, not a portability claim.

## Acceptance

Record:

- requested source commit and toolchain;
- run directory, queue and resource request;
- scheduler terminal state and platform exit status;
- `allwmake_rc`;
- `foamInstallationTest` exit code and output;
- executable `icoFoam`;
- actual error-marker scan;
- `blockMesh`, `icoFoam`, repeated installation test and `End` marker.

Do not publish private paths, credentials, node names or raw workload data in
public evidence. Keep detailed scheduler/job records in the private run log.
