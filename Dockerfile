# This docker file is used to create a docker image with Petalinux installed
# The main purpose of this docker image is to build petalinux projects in a CI/CD pipeline

FROM ubuntu:18.04

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  autoconf \
  bc \
  bison \
  build-essential \
  expect \
  gawk \
  gcc-multilib \
  libpython3.8-dev \
  libncurses5-dev \
  libtool \
  libtool-bin \
  locales \
  net-tools \
  pylint3 \
  python \
  python3 \
  python3-pexpect \
  python3-pip \
  python3-git \
  python3-jinja2 \
  rsync \
  sudo \
  texinfo \
  tftpd \
  xterm \
  xxd \
  xz-utils \
  zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale

# Make a petalinux user (Petalinux cannot be installed to root)
RUN adduser --disabled-password --gecos '' petalinux
RUN usermod -aG sudo petalinux
RUN echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ARG PETA_RUN_FILE="petalinux-v2022.2-10141622-installer.run"

# Copy the installer and the EULA acceptance script to the container
COPY ./accept_eula.sh /home/petalinux
COPY ./build_image.sh /home/petalinux
COPY ./petalinux-v2022.2-10141622-installer.run /home/petalinux

WORKDIR /home/petalinux

# Run the Petalinux installer
RUN chmod a+rx /home/petalinux/${PETA_RUN_FILE}
RUN chmod a+rx /home/petalinux/accept_eula.sh
RUN mkdir -p /opt/Xilinx
RUN chmod 777 /tmp /opt/Xilinx
RUN cd /tmp
RUN sudo -u petalinux -i /home/petalinux/accept_eula.sh /home/petalinux/${PETA_RUN_FILE} /opt/Xilinx/petalinux
RUN rm -f /home/petalinux/${PETA_RUN_FILE}

RUN echo "root:petalinux" | chpasswd

USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8

USER root
RUN echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
  echo ". /opt/Xilinx/petalinux/settings.sh" >> /etc/profile && \
  echo ". /etc/profile" >> /root/.profile

EXPOSE 69/udp

USER petalinux

ENTRYPOINT ["/bin/bash", "-l"]