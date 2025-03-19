FROM ubuntu:20.04
ENV DEBIAN_FRONTEND="noninteractive"
RUN set -x && \
    apt update && \
    apt remove --purge --auto-remove -y cmake; \
    apt install -y ca-certificates gpg wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee -a /etc/apt/sources.list.d/kitware.list >/dev/null   && \
    apt update && \
    apt install -y cmake && \
    cmake --version && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/*