FROM base/archlinux
LABEL maintainer="Daniel Pereira <daniel@garajau.com.br>"

# These are the packages that pacman is going to install on this image
ARG PACKAGES="base-devel git openssh ca-certificates sudo aws-cli"

RUN pacman -Syu --noconfirm --needed $PACKAGES && \
      useradd --create-home --shell /bin/bash build && \
      echo 'build ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-build

USER build
WORKDIR /home/build
