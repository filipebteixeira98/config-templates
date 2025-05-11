FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  sudo \
  && rm -rf /var/lib/apt/lists/*

# Add a test user with sudo privileges (skip password for simplicity)
RUN useradd -ms /bin/bash dev && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

COPY install.sh .
COPY packages.txt .

RUN chmod +x ./install.sh

ENTRYPOINT ["./install.sh", "--with-dotfiles", "--dev-tools"]

