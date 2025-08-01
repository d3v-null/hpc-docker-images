# https://gitlab.com/ska-telescope/sdp/ska-sdp-spack.git

# docker build . -f dp3-mwa.Dockerfile --tag d3vnull0/dp3-mwa:latest --push

# ---------------------------
# Builder Stage: Build environment, install dependencies, and generate Spack view
# ---------------------------
FROM spack/ubuntu-jammy:0.23.0 AS builder
# note to replicate some of these steps in your own container, you should first:
# . /opt/spack/share/spack/setup-env.sh

# some packages must be installed by apt in addition to spack.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -y \
    # -> wget: casacore packagse misses this as a build dependency
    #7 446.1 ==> Installing casacore-3.6.1-4e6f2sbww43az7spzgi77inyyr4ewura [192/234]
    #7 457.6 sh: 1: wget: not found
    'wget' \
    # -> needed to install ska-sdp-func later by pip
    'cmake' 'libcfitsio-dev' \
    # -> cmake doesn't like spack installed libcurl, or apt installed either!
    # /opt/view/lib/libcurl.so.4: no version information available (required by /usr/bin/cmake)
    # 'libcurl4'
    ;

# Clone the custom Spack repository from GitLab
# update packages/everybeam/package.py to add version('0.7.2', commit='v0.7.2', submodules=True)
RUN git clone https://gitlab.com/ska-telescope/sdp/ska-sdp-spack.git /opt/ska-sdp-spack && \
    sed -i 's/version("0.7.1", commit="v0.7.1", submodules=True)/version("0.7.2", commit="v0.7.2", submodules=True)/' /opt/ska-sdp-spack/packages/everybeam/package.py && \
    spack repo add /opt/ska-sdp-spack

# Create a new Spack environment which writes to /opt
RUN --mount=type=cache,target=/opt/buildcache \
    mkdir -p /opt/{software,spack_env,view} && \
    spack env create --dir /opt/spack_env && \
    spack env activate /opt/spack_env && \
    spack mirror add --autopush --unsigned mycache file:///opt/buildcache && \
    spack config add "config:install_tree:root:/opt/software" && \
    spack config add "view:/opt/view" && \
    spack add \
    'everybeam@:0.7.2' \
    'dp3@master' \
    && \
    spack install --no-check-signature --fail-fast

FROM ubuntu:jammy AS runtime

# Copy necessary files from builder
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/view /opt/view
COPY --from=builder /opt/spack_env /opt/spack_env
COPY --from=builder /opt/spack /opt/spack
COPY --from=builder /opt/ska-sdp-spack /opt/ska-sdp-spack

# Setup Spack environment
ENV SPACK_ROOT=/opt/spack \
    PATH=/opt/view/bin:/opt/software/bin:/usr/local/bin:/usr/bin:/bin
RUN . /opt/spack/share/spack/setup-env.sh && \
    spack repo add /opt/ska-sdp-spack && \
    spack env activate /opt/spack_env && \
    echo ". /opt/spack/share/spack/setup-env.sh" >> /etc/profile.d/spack.sh && \
    echo "spack env activate /opt/spack_env" >> /etc/profile.d/spack.sh && \
    . /etc/profile.d/spack.sh

# Create a startup script that activates the environment
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'source /opt/spack/share/spack/setup-env.sh' >> /usr/local/bin/entrypoint.sh && \
    echo 'spack env activate /opt/spack_env' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh
