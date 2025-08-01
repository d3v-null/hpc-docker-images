# Our image is based on Debian bullseye
FROM debian:bullseye

# Set for all apt-get install, must be at the very beginning of the Dockerfile.
ENV DEBIAN_FRONTEND noninteractive

# Update the OS
# use libatlass instead of liblapack3 libblas3
RUN apt-get -y update; \
    apt-get -y install \
    build-essential \
    cython3 \
    git \
    ipython3 \
    jq \
    libatlas3-base \
    procps \
    python3-dev \
    python3-ipykernel \
    python3-ipython \
    python3-matplotlib \
    python3-numpy \
    python3-pandas \
    python3-scipy \
    python3-seaborn \
    python3-six \
    wget \
    ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    apt-get -y autoremove;

# Bullseye Versions:
# - python3-astropy: 3.3.4-1
# - python3-h5py: 2.10.0-9
# - python3-numpy: 1:1.19.5-1
# - python3-scipy: 1.6.0-2
# - python3-matplotlib: 3.3.4-1

# use python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN update-alternatives --install /usr/bin/ipython ipython /usr/bin/ipython3 1

# install dependencies not available on apt
RUN python -m pip install pyuvdata
RUN python -m pip install git+https://github.com/d3v-null/SSINS.git@eavils-copilot
RUN python -m pip install cthulhu

ENTRYPOINT bash