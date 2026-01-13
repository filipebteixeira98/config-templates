#!/bin/bash

set -euo pipefail
# set -e  # Exit on error
# set -u  # Exit on unset variables
# set -o pipefail  # Catch errors in pipes

trap 'fail "An error occurred. Exiting..."' ERR # trap function to clean up on failure

# =============== ✨ CONFIG ✨ ===============
DOTFILES_DIR="$(pwd)/configs"
PACKAGE_LIST="packages.txt"
BACKUP_SUFFIX=".bak"

# =============== 🎨 COLORS & ICONS ===============
# Color codes
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Emojis
SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# =============== 🔊 LOGGING FUNCTIONS ===============
# Print message
log() {
  echo -e "${BLUE}${INFO} $1${RESET}"
}

success() {
  echo -e "${GREEN}${SUCCESS} $1${RESET}"
}

fail() {
  echo -e "${RED}${ERROR} $1${RESET}"
}

# =============== 💻 CODE EXTENSIONS VARIABLE ===============
extensions="
aaron-bond.better-comments
alefragnani.bookmarks
alexcvzz.vscode-sqlite
bierner.comment-tagged-templates
biomejs.biome
bradlc.vscode-tailwindcss
codeium.codeium
csstools.postcss
dbaeumer.vscode-eslint
eamodio.gitlens
editorconfig.editorconfig
esbenp.prettier-vscode
formulahendry.auto-close-tag
gabbezeira.darkwizard
gregorbiswanger.json2ts
humao.rest-client
jcbuisson.vue
jrebocho.vscode-random
miguelsolorio.symbols
mikestead.dotenv
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-toolsai.jupyter
ms-toolsai.jupyter-keymap
ms-toolsai.jupyter-renderers
ms-toolsai.vscode-jupyter-cell-tags
ms-toolsai.vscode-jupyter-slideshow
ms-vsliveshare.vsliveshare
naumovs.color-highlight
perkovec.emoji
pkief.material-icon-theme
prisma.prisma
ritwickdey.live-sass
ritwickdey.liveserver
robertz.code-snapshot
rocketseat.theme-omni
shd101wyy.markdown-preview-enhanced
streetsidesoftware.code-spell-checker
tabnine.tabnine-vscode
visualstudioexptteam.intellicode-api-usage-examples
visualstudioexptteam.vscodeintellicode
wakatime.vscode-wakatime
wallabyjs.console-ninja
yzhang.markdown-all-in-one
"
readonly extensions

# =============== 🗺️ INSTRUCTIONS FUNCTION ===============
usage_instructions() {
  cat <<EOF
Usage: ./install.sh [options]

Available options:
-h, --help              Show this help message and exit
-w, --with-dotfiles     Clone and apply dotfiles configuration
-t, --dev-tools         Install developer tools (Node, Docker, etc.)
EOF
  exit 0
}

die() {
  local msg=$1
  local code=${2-1}
  fail "$msg"
  exit "$code"
}

configure_environment() {
  with_dotfiles=false
  dev_tools=false

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage_instructions ;;
      -w|--with-dotfiles) with_dotfiles=true ;;
      -t|--dev-tools) dev_tools=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done
}

# =============== 🌀 LOADING SPINNER ===============
spinner() {
  local pid=$!
  local delay=0.1
  
  while ps -p $pid &> /dev/null; do
    for frame in "${SPINNER_FRAMES[@]}"; do
      printf "\r%s Installing... %s" "$INFO" "$frame"

      sleep $delay
    done
  done
  
  printf "\r"
}

# =============== 🔍 CHECK DEPENDENCIES ===============
check_requirements() {
  log "Checking required commands to run this script..."

  for cmd in sudo apt; do
    if ! command -v "${cmd%% *}" &> /dev/null; then
      fail "Missing required command: $cmd"
      
      echo -e "${RED}Please install it manually before running this script.${RESET}"
      
      exit 1
    fi
  done

  success "All core requirements are available."
}

# =============== 📦 PACKAGE INSTALLATION ===============
install_packages() {
  log "Installing packages..."

  if [ ! -f "$PACKAGE_LIST" ]; then
    fail "❌ Package list '$PACKAGE_LIST' not found."

    exit 1
  fi

  while read -r package; do
    if [ -n "$package" ]; then
      log "Installing $package..."
      
      sudo apt install -y "$package" &> /dev/null &
      
      spinner $!
      
      if [ $? -eq 0 ]; then
        success "$package installed"
      else
        fail "Failed to install $package"
      fi
    fi
  done < $PACKAGE_LIST
}

install_dev_tools() {
  echo -e "🔸 Installing dependencies for codium editor"

  sleep 0.75

  if command -v codium; then
    echo -e "🔸 Installing codium editor"

    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
      | gpg --dearmor \
      | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
    
    echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
    
    sudo apt update && sudo apt install codium
    
    # codium --list-extensions | xargs -L 1 echo codium --install-extension
    echo "$extensions" | xargs -L 1 echo codium --install-extension

    #while read -r ext; do
    #  codium --install-extension "$ext"
    #done <<< "$extensions"
  fi

  echo "✅ Installed code editor and extensions"

  echo -e "🔸 Installing node.js 💚 runtime through nvm manager"

  sleep 0.75

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

  . "$HOME/.nvm/nvm.sh"

  nvm install 22

  echo "✅ Installed nvm $(nvm current) node $(node -v) npm $(npm --version)"

  echo -e "🔸 Installing yarn package manager"

  npm install --global yarn

  echo "✅ Installed yarn on version $(yarn -v)"

  echo -e "🔸 Installing docker container application"

  if pgrep -x gnome-session > /dev/null && $XDG_SESSION_DESKTOP = 'GNOME'; then
    log "Desktop environment is GNOME. Configuring necessary dependencies..."

    sudo apt install gnome-terminal
  fi

  # Add Docker's official GPG key:
  sudo apt update
  
  sudo apt install ca-certificates curl
  
  sudo install -m 0755 -d /etc/apt/keyrings
  
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  # echo \
  #  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  #  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  #  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

  sudo tee /etc/apt/sources.list.d/docker.sources <<-EOF
	Types: deb
	URIs: https://download.docker.com/linux/debian
	Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
	Components: stable
	Signed-By: /etc/apt/keyrings/docker.asc
	EOF

  sudo apt update

  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo systemctl status docker

  sudo systemctl start docker

  sudo docker run hello-world

  sudo groupadd docker

  sudo usermod -aG docker $USER

  newgrp docker

  sudo chown "$USER":"$USER" /home/"$USER"/.docker -R

  sudo chmod g+rwx "$HOME/.docker" -R

  docker run hello-world

  sudo systemctl enable docker.service

  sudo systemctl enable containerd.service

  echo "✅ Installed docker on version $(docker version)"

  echo -e "🔸 Installing snapd package manager"

  sudo apt install snapd

  echo "✅ Installed snapd on version $(snap version)"

  echo -e "🔸 Installing httpie api client"

  snap install httpie

  echo "✅ Installed httpie on version $(httpie --version)"
  
  echo -e "🔸 Installing Hoppscotch http client"

  wget https://github.com/hoppscotch/releases/releases/latest/download/Hoppscotch_linux_x64.deb

  sudo apt install ./Hoppscotch_linux_x64.deb

  rm -rf Hoppscotch_linux_x64.deb

  echo "✅ Installed Hoppscotch"
  
  echo -e "🔸 Installing DBeaver database"

  sudo snap install dbeaver-ce

  echo "✅ Installed DBeaver"
}

# =============== 🔗 SYMLINK DOTFILES ===============
link_dotfiles() {
  log "Linking dotfiles..."
  
  for file in $(ls configs); do
    target="$HOME/.$file"
    source_file="$DOTFILES_DIR/$file"

    if [ -e "$target" ]; then
      log "Backing up $target to $target$BACKUP_SUFFIX"
      
      mv "$target" "$target$BACKUP_SUFFIX"
    fi

    ln -s "$source_file" "$target"
    
    success "Linked $file"
  done
}

# =============== 🚀 MAIN ===============
main() {
    configure_environment "$@"

    log "🔥 Starting environment setup..."
    
    check_requirements
    
    install_packages

    if [ "$with_dotfiles" = true ]; then
      log "🛠️ Linking dotfiles..."
      link_dotfiles
    fi

    if [ "$dev_tools" = true ]; then
      log "🧰 Installing dev tools..."
      install_dev_tools
    fi
    
    success "🎉 Environment setup complete!"
}

main "$@"
