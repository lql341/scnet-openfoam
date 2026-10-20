---
name: scnet-openfoam
description: Build and validate OpenFOAM on SCNet compute nodes with isolated toolchains, scheduler evidence and short numerical smoke tests.
---

# SCNet OpenFOAM

Use this application skill for OpenFOAM builds and validation on SCNet. Read
[references/validation.md](references/validation.md) before submitting work.

## Operating rules

- Never compile OpenFOAM on the agent workstation.
- Prefer `scnet-hpc` OpenAPI for queue discovery, submit, status, wait and cancel.
- Use SSH only for bounded script upload and log/source diagnosis.
- Resolve source, ThirdParty, commit, queue and run directory before submission.
- Give every run a unique directory. Do not overwrite existing results.
- GCC11 and GCC16 must not share source trees, `buildroot`, `platforms`,
  `lnInclude` or mutable ThirdParty directories.
- Treat `Allwmake` as one signal, not the verdict.

## Required evidence

Require all of the following before reporting a successful build:

1. `allwmake_rc=0`;
2. `foamInstallationTest` exit code zero and success output;
3. executable `icoFoam`;
4. no real `error:`, `fatal error`, `CMake Error` or missing-command markers;
5. scheduler state `COMPLETED` and platform exit status zero.

Then run `blockMesh`, a short `icoFoam` tutorial and a repeated installation
test in the same accepted installation. Save logs and exit codes under a new
validation directory.

## Known v2606 compatibility facts

The Kunshan validation found that the site compiler/OpenMPI combination needs
the serial libstdc++ PSTL backend flag
`-D_PSTL_PAR_BACKEND_SERIAL` because the available old TBB is incompatible with
the GCC11/GCC16 PSTL headers. GCC16 Scotch C sources need `-std=gnu17`.
Optional components requiring a newer CMake may fail without invalidating the
OpenFOAM core; classify those failures separately.

These facts are site evidence, not a universal guarantee for every cluster.
