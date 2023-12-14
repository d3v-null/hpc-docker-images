# HPC Docker Images

## Images

| Dockerfile                  | Description                                            |
|-----------------------------|--------------------------------------------------------|
| wsclean_idg_cuda.Dockerfile | [wsclean](https://gitlab.com/aroffringa/wsclean) with [IDG](https://gitlab.com/astron-idg/idg) and CUDA support                      |
| tap.Dockerfile              | [Virtual Observatory Table Access Protocol (TAP)](https://pyvo.readthedocs.io/en/latest/) client |

## Determining your nvidia version

find the gpu partitions

```bash
sinfo
```

salloc into each gpu partition, run nvidia-smi and grep for the CUDA version

```bash
for partition in skylake-gpu milan-gpu; do sbatch --partition $partition --gres=gpu:1 --wrap 'nvidia-smi' -o ${partition}.out; done
grep 'CUDA Version' *.out
milan-gpu.out:| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
skylake-gpu.out:| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
```

## Building the images

annoyingly nvidia-smi doesn't report cuda runtime patch version,
and nvidia doesn't publish docker images tagged with the minor version,
so you need to look up the latest patch version from <https://hub.docker.com/r/nvidia/cuda/tags>
and just pray that this works.

```bash
export NVIDIA_VERSION=12.2.2
export IDG_VERSION=1.2.0
export WSCLEAN_VERSION=3.4
export DOCKER_USER=$(docker info | sed '/Username:/!d;s/.* //');
docker build \
    -f wsclean_idg_cuda.Dockerfile \
    --build-arg="NVIDIA_VERSION=${NVIDIA_VERSION}" \
    --build-arg="IDG_VERSION=${IDG_VERSION}" \
    --build-arg="WSCLEAN_VERSION=${WSCLEAN_VERSION}" \
    -t ${DOCKER_USER}/wsclean_idg:nvidia${NVIDIA_VERSION}-idg${IDG_VERSION}-wsclean${WSCLEAN_VERSION} \
    .
```

## Testing an image

you can test an image locally if you happen to have a compatible gpu

```bash
docker run --rm -it --gpus all ${DOCKER_USER}/wsclean_idg:nvidia${NVIDIA_VERSION}-idg${IDG_VERSION}-wsclean${WSCLEAN_VERSION} bash
```

## Publishing an image

```bash
docker push ${DOCKER_USER}/wsclean_idg:nvidia${NVIDIA_VERSION}-idg${IDG_VERSION}-wsclean${WSCLEAN_VERSION}
```

## Create singularity image

on the login node

```bash
#!/bin/bash
module load singularity
# - specify the image to update:
export img="wsclean_idg"
# - specify the url of the docker image
export url= ... # e.g. "docker://d3vnull0/wsclean_idg:nvidia12.2.2-idg1.2.0-wsclean3.4"
# - cd into singularity directory
cd /fred/oz048/MWA/CODE/singularity/
# - make a directory for the img if it doesn't exist
[ -d $img ] || mkdir $img
# - create the singularity image
singularity pull --force --dir $img "$url"
```

## Running singularity image

```bash
salloc --partition skylake-gpu --gres=gpu:1 --time=01:00:00
module load singularity
singularity exec --nv \
    --bind /fred/oz048/ \
    /fred/oz048/MWA/CODE/singularity/wsclean_idg/wsclean_idg_nvidia12.2.2-idg1.2.0-wsclean3.4.sif \
    wsclean -name idgtest -niter 0 \
        -scale 0.02 -size 1024 1024 \
        -auto-threshold 0.5 -auto-mask 3 \
        -pol I -multiscale -weight briggs 0  -j 10 -mgain 0.85 \
        -no-update-model-required -abs-mem 30 \
        -use-idg -idg-mode hybrid \
        /fred/oz048/dev/hyp_ionosub_1222704240_30l_src4k_2s_80kHz.ms
```
