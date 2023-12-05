# syntax=docker/dockerfile:1
ARG NVIDIA_VERSION=11.3.1

FROM nvidia/cuda:${NVIDIA_VERSION}-devel-ubuntu20.04

ARG BOOST_VERSION=1.71.0

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        file \
        g++ \
        git \
        libboost-all-dev \
        libboost-test${BOOST_VERSION} \
        libfftw3-dev \
        liblapacke-dev \
        ninja-build \
        python3 \
        python3-pip \
        wget \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

ARG IDG_VERSION=1.2.0

RUN git clone --depth 1 --branch ${IDG_VERSION} https://git.astron.nl/RD/idg.git /idg && \
    cd /idg && \
    git submodule update --init --recursive && \
    ls -al . && \
    mkdir build && \
    cd build && \
    cmake .. \
        "-DCMAKE_LIBRARY_PATH=/usr/local/cuda/compat;/usr/local/cuda/lib64" \
        "-DCMAKE_CXX_FLAGS=-isystem /usr/local/cuda/include" \
        -DBUILD_TESTING=On -DBUILD_LIB_CUDA=On -DBUILD_PACKAGES=On && \
    make install -j`nproc`

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update -y && \
    apt-get -y install \
        build-essential \
        casacore-data casacore-dev \
        libblas-dev \
        libboost-date-time-dev \
        libboost-filesystem-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-test-dev \
        libcfitsio-dev \
        libgsl-dev \
        libhdf5-dev \
        liblapack-dev \
        libopenmpi-dev \
        libpng-dev \
        libpython3-dev \
        pkg-config \
        python3-dev \
        python3-numpy \
        python3-pytest \
        python3-sphinx \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*
# duplicates: cmake git g++ pkg-config libfftw3-dev wget python3

ARG WSCLEAN_VERSION=3.4

RUN git clone --depth 1 --branch v${WSCLEAN_VERSION} https://gitlab.com/aroffringa/wsclean.git /wsclean && \
    cd /wsclean && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j`nproc` && \
    make install && \
    wsclean --version

