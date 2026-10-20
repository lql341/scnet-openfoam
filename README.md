# scnet-openfoam

English | [中文](README_CN.md)

Current release: 0.1.0

Run OpenFOAM builds and short numerical smoke tests on SCNet compute nodes.
This application skill is intentionally remote-first: OpenFOAM compilation,
installation checks, tutorial execution and numerical validation belong on the
target compute node, not on the agent workstation.

The first implementation targets OpenFOAM v2606 with Slurm/OpenMPI and records
the constraints learned from a Kunshan `kseshell` validation. The scripts are
parameterized; they do not contain a maintainer's private remote path or job
result.

## One-sentence agent installation

Paste this into Codex:

> Use `$skill-installer` to install `scnet-openfoam` from the root of GitHub repository `lql341/scnet-openfoam` (path `.`, ref `main`), name it `scnet-openfoam`, do not overwrite an existing destination, then run `scripts/validate.sh` from the installed directory and report the absolute installation path; do not compile OpenFOAM or submit a cluster job during installation.

## Scope

This repository provides:

- isolated GCC11/GCC16 OpenFOAM v2606 build jobs;
- compiler, MPI and serial-PSTL probes;
- a short `blockMesh` + `icoFoam` cavity smoke test;
- post-build installation, idempotency and relocation checks;
- documentation of the acceptance gates and known failure modes.

It does not package OpenFOAM, install cluster modules, or claim that a queue or
compiler is available without a live cluster check.

## Required remote inputs

Set these variables in the submitted job environment:

```text
OPENFOAM_SOURCE_ROOT       Git checkout containing the requested OpenFOAM commit
OPENFOAM_THIRDPARTY_ROOT   ThirdParty checkout containing sources/scotch and etc
OPENFOAM_SRC_COMMIT        immutable OpenFOAM commit to archive
OPENFOAM_RUN_ROOT          writable root for unique run directories
```

Use `scnet-hpc` OpenAPI for queue discovery, submission, status, waiting and
cancellation. SSH is a secondary path for uploading scripts and bounded log
diagnosis. Never share `buildroot`, `platforms`, `lnInclude` or mutable
ThirdParty build directories between toolchains.

## Workflow

```bash
python3 -m scnet_hpc ... # use the installed scnet-hpc entrypoint
bash scripts/openfoam_toolchain_probe.sh
bash scripts/openfoam_build_isolated.sbatch
bash scripts/openfoam_tutorial_smoke.sbatch
bash scripts/openfoam_postbuild.sbatch
```

The scripts are Slurm job bodies. Run them on a compute node through the
cluster's scheduler; do not execute an OpenFOAM build on the local workstation.
The build script accepts `FOAM_TOOLCHAIN=gcc11` or `FOAM_TOOLCHAIN=gcc16`.

## Acceptance gates

`Allwmake` returning zero is not sufficient. A successful build must also have:

1. `foamInstallationTest` exit code zero and real output;
2. an executable `icoFoam`;
3. no real compiler/fatal/CMake error markers;
4. an accounting-confirmed scheduler completion with platform exit status zero;
5. a short tutorial with successful `blockMesh`, `icoFoam`, an `End` marker and
   a repeated installation test.

The full `Allwmake` is a one-time toolchain/source acceptance. Daily regression
should reuse an accepted installation and run the probe, installation test and
short tutorial only.

See [validation.md](references/validation.md) and
[validation_CN.md](references/validation_CN.md) for the evidence model.

## Local validation

```bash
bash scripts/validate.sh
```

This only checks repository scripts and documentation. It never compiles
OpenFOAM or accesses a cluster.

MIT licensed.
