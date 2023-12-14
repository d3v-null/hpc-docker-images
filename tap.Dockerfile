# Our image is based on Debian bullseye
FROM debian:bullseye

LABEL description="Docker image for TAP service. see: https://github.com/d3v-null/hpc-docker-images"

# Set for all apt-get install, must be at the very beginning of the Dockerfile.
ENV DEBIAN_FRONTEND noninteractive

# Update apt and install dependencies
RUN apt-get -y update; \
    apt-get -y install \
        python3 \
        python3-pip \
        python3-ipython \
        python3-ipykernel \
        python3-astropy \
        python3-pandas \
        python3-numpy \
        ipython3 \
        procps \
    ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    apt-get -y autoremove;

# use python3 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# install other python reqs
RUN pip install pyvo

# set the entrypoint
ENTRYPOINT bash