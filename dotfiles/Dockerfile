FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  sudo \
  && rm -rf /var/lib/apt/lists/*

# Add a test user with sudo privileges (skip password for simplicity)
RUN useradd -ms /bin/bash dev && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

# Copy files *after* switching user (important for permissions)
COPY --chown=dev:dev install.sh .
COPY --chown=dev:dev packages.txt .

# Ensure the script is executable
RUN chmod +x install.sh

# ENTRYPOINT ["./install.sh", "--with-dotfiles", "--dev-tools"]
ENTRYPOINT ["/bin/bash", "-c", "echo '🚀 Starting script...'; ./install.sh --with-dotfiles, --dev-tools]
