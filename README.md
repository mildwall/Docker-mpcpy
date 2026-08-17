# Docker-mpcpy

A reproducible container build of the JModelica + CasADi + IPOPT optimization toolchain, packaged with [MPCPy](https://github.com/lbl-srg/MPCPy) for grey-box building-energy modelling, parameter estimation, and model predictive control research. The published image is on Docker Hub as [`guokai94/mpcpy`](https://hub.docker.com/r/guokai94/mpcpy) and converts directly to Apptainer for use on HPC clusters.

## Why this exists

JModelica.org was withdrawn from open-source distribution by Modelon in 2019, and its final open release depends on a Python 2.7 stack that no longer builds cleanly on current systems. Research that relies on JModelica's FMU compilation and CasADi-based collocation, as MPCPy does, therefore needs a frozen, rebuildable environment rather than a native install.

This image fixes the whole toolchain at known-good versions: JModelica, CasADi, Sundials, IPOPT 3.12.4 with HSL linear solvers, MPCPy, EstimationPy, and a pinned Modelica Buildings library. I built it during my PhD at UCL to calibrate grey-box thermal models of buildings, where the same environment had to run unchanged on a desktop and on the UCL Myriad HPC cluster (via Apptainer, which cannot assume root access or a writable system).

## What the image contains

| Component | Version / source |
|---|---|
| Base image | `lbnlblum/ubuntu-1804_jmodelica_trunk` (Ubuntu 18.04 + JModelica trunk, from LBNL) |
| IPOPT | 3.12.4, built with MUMPS, METIS, and HSL (MA27/MA57) |
| HSL | coinhsl-2021.05.05, compiled via `ThirdParty-HSL` |
| MPCPy | [`mildwall/MPCPy`](https://github.com/mildwall/MPCPy), `Improvement` branch |
| EstimationPy | `lbl-srg/EstimationPy`, master |
| Modelica Buildings | `lbl-srg/modelica-buildings` pinned at commit `891d0c2` |
| Python environments | Miniconda: `py27` (JModelica/MPCPy runtime) and `py310` (modern analysis tools), from `py27.yml` and `py310.yml` |

The `py27` environment also carries pinned versions of scikit-learn, pvlib, pyDOE, tzwhere, siphon, and Flask packages used by MPCPy examples and by a REST interface (port 5000 is exposed).

## Quick start (Docker)

```bash
docker pull guokai94/mpcpy
docker run -it guokai94/mpcpy
```

The default command runs `bash.sh`, which activates the `py27` environment and executes MPCPy's introductory tutorial (`MPCPy/doc/userGuide/tutorial/introductory.py`). A run that finishes with `Execution finished!` confirms the FMU compilation and IPOPT solve both work.

For interactive use:

```bash
docker run -it guokai94/mpcpy bash
source ~/miniconda3/bin/activate py27
```

## Use on HPC with Apptainer

Apptainer (formerly Singularity) pulls the Docker image and converts it to a SIF file, with no root access required on the cluster:

```bash
apptainer pull mpcpy.sif docker://guokai94/mpcpy
apptainer exec --bind /path/to/your/models:/data mpcpy.sif \
    bash -c "source ~/miniconda3/bin/activate py27 && python /data/run_estimation.py"
```

This is the workflow the image was designed around: build and test locally with Docker, then run the identical environment on the cluster through Apptainer, so that solver versions and packaging stay constant between machines.

## Building from source

The build compiles IPOPT against the HSL subroutines, so it expects `coinhsl-2021.05.05` as `coinhsl.tar.gz` in the build context. HSL is licensed separately; academic licences are available from [STFC](https://licences.stfc.ac.uk/products/Software/HSL).

```bash
docker build -t mpcpy .
```

Expect a long build (IPOPT and its third-party solvers compile from source) and an image of roughly 6.4 GB.

## Repository contents

| File | Purpose |
|---|---|
| `Dockerfile` | Full build recipe |
| `py27.yml`, `py310.yml` | Conda environment specifications |
| `bash.sh` | Container entry point; runs the MPCPy tutorial as a smoke test |
| `Tips.ipynb` | Working notes and usage tips |

## Known limitations

- The runtime is Python 2.7 by design; it is frozen with JModelica, not upgradable. The `py310` environment exists for analysis around the toolchain, not for driving it.
- The Modelica Buildings library is pinned to one commit for reproducibility; newer library versions are untested against this JModelica build.
- JModelica is unmaintained upstream, so the image should be treated as an archival environment: stable, but deliberately not updated.

## Author

Guokai Chen, UCL Institute for Environmental Design and Engineering.
