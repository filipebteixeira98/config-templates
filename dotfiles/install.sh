#!/bin/bash

# =============== 🐚 SPINNER ===============
# wget https://raw.githubusercontent.com/Silejonu/bash_loading_animations/main/bash_loading_animations.sh
# source $HOME/bash_loading_animations.sh
# trap BLA::stop_loading_animation SIGINT

# set -euo pipefail
set -e  # Exit on error
set -u  # Exit on unset variables
set -o pipefail  # Catch errors in pipes

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
Available options:
-h, --help            <OPTIONAL>    Print this help and exit
-l, --loader          <OPTIONAL>    Chose loader to display
-m, --message         <OPTIONAL>    Text to display while loading
-e, --ending          <OPTIONAL>    Text to display when finishing
EOF
  exit 0
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

  while read -r package; do
    if [ -n "$package" ]; then
      log "Installing $package..."
      
      (sudo apt install -y "$package" &> /dev/null) &
      
      spinner $!
      
      if [ $? -eq 0 ]; then
        success "$package installed"
      else
        fail "Failed to install $package"
      fi
    fi
  done < packages.txt

  echo -e "🔸 Installing dependencies for codium editor"

  sleep 0.75

  if command -v codium; then
    # codium --list-extensions | xargs -L 1 echo codium --install-extension
    $extensions | xargs -L 1 echo codium --install-extension
  else
    $extensions | xargs -L 1 echo code --install-extension
  fi

  echo "✅ Installed code editor extensions"

  echo -e "🔸 Installing node.js 💚 runtime through nvm manager"

  sleep 0.75

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

  \. "$HOME/.nvm/nvm.sh"

  nvm install 22

  echo "✅ Installed nvm $(nvm current) node $(node -v) npm $(npm --version)"

  echo -e "🔸 Installing yarn package manager"

  npm install --global yarn

  echo "✅ Installed yarn on version $(yarn -v)"
}

# =============== 🔗 SYMLINK DOTFILES ===============
link_dotfiles() {
  log "Linking dotfiles..."
  
  for file in $(ls configs); do
    target="$HOME/.$file"
    source_file="$(pwd)/configs/$file"

    if [ -e "$target" ]; then
      log "Backing up $target to $target.bak"
      
      mv "$target" "$target.bak"
    fi

    ln -s "$source_file" "$target"
    
    success "Linked $file"
  done
}

# =============== 🚀 MAIN ===============
main() {
    log "🔥 Starting environment setup..."

    check_requirements
    install_packages
    link_dotfiles

    success "🎉 Environment setup complete!"
}

main "$@"

configure_environment() {
  loader=''
  message=''
  ending=''
  
  while :; do
    case "${1-}" in
    -h | --help) handle_usage_instructions;;
    -l | --loader)
      loader="${2-}"
      shift
      ;;
    -m | --message)
      message="${2-}"
      shift
      ;;
    -e | --ending)
      ending="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done
}
