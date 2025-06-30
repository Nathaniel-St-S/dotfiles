#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$DOTFILES_DIR/.config"

echo -e "${GREEN}Starting dotfiles setup...${NC}"

# Required packages
REQUIRED_APPS=("zsh" "kitty" "lite-xl" "stow" "zoxide")

install_packages() {
  echo -e "${GREEN}Checking for missing packages...${NC}"
  for pkg in "${REQUIRED_APPS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      echo -e "${GREEN}Installing $pkg...${NC}"
      if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y "$pkg"
      elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "$pkg"
      elif command -v brew &>/dev/null; then
        brew install "$pkg"
      else
        echo "⚠️ Unsupported package manager. Please install $pkg manually."
      fi
    else
      echo "$pkg is already installed."
    fi
  done
}

install_zinit() {
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [ ! -d "$ZINIT_HOME" ]; then
    echo -e "${GREEN}Installing zinit...${NC}"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  else
    echo "zinit is already installed."
  fi
}

install_lpm_and_plugins() {
  echo -e "${GREEN}Installing Lite XL Plugin Manager (lpm)...${NC}"

  # Set install location
  LPM_BIN="$HOME/.local/bin/lpm"
  mkdir -p "$HOME/.local/bin"

  if ! command -v lpm &>/dev/null && [ ! -f "$LPM_BIN" ]; then
    echo -e "${GREEN}Downloading lpm binary...${NC}"
    wget https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux -O "$LPM_BIN"
    chmod +x "$LPM_BIN"
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "lpm is already installed."
  fi

  # Plugin list
  LITE_XL_PLUGIN_LIST=(
    lsp
    lsp_c
    lsp_rust
    lsp_java
    lsp_python
    plugin_manager
    debugger
    lintplus
    terminal
    align_carets
    autoinsert
    autosave
    bracketmatch
    ephemeral_tabs
    indentguide
    lsp_snippets
    minimap
    pdfview
    settings
    snippets
  )

  echo -e "${GREEN}Installing Lite XL plugins...${NC}"
  for plugin in "${LITE_XL_PLUGIN_LIST[@]}"; do
    echo -e "→ Installing $plugin"
    "$LPM_BIN" install "$plugin" --assume-yes
  done
}


symlink_dotfiles() {
  echo -e "${GREEN}Symlinking top-level dotfiles with stow...${NC}"
  for file in .zshrc .p10k.zsh; do
    if [[ -f "$DOTFILES_DIR/$file" ]]; then
      echo "Stowing $file"
      stow --target="$HOME" "$file"
    fi
  done
}

symlink_config_folders() {
  echo -e "${GREEN}Symlinking config folders with stow...${NC}"
  cd "$DOTFILES_DIR/.config"
  for dir in */; do
    dir=${dir%/}
    echo "Stowing $dir → $HOME/.config/$dir"
    stow --dir="$DOTFILES_DIR/.config" --target="$HOME/.config" "$dir"
  done
  cd "$DOTFILES_DIR"
}

set_zsh_default_shell() {
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo -e "${GREEN}Setting zsh as the default shell...${NC}"
    chsh -s "$(which zsh)"
  fi
}

# Run all steps
install_packages
install_zinit
install_lpm_and_plugins
symlink_dotfiles
symlink_config_folders
set_zsh_default_shell

echo -e "${GREEN}Dotfiles setup complete!${NC}"

