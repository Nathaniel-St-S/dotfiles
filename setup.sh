#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    gitblame
    gitdiff_highlight
    gitopen
    gitstatus
  )

  echo -e "${GREEN}Installing Lite XL plugins...${NC}"
  for plugin in "${LITE_XL_PLUGIN_LIST[@]}"; do
    echo -e "→ Installing $plugin"
    "$LPM_BIN" install "$plugin" --assume-yes
  done
}

backup_and_remove_conflicting_files() {
  local dir="$1"
  local source_dir="$DOTFILES_DIR/.config/$dir"
  local target_dir="$HOME/.config/$dir"
  
  if [ ! -d "$source_dir" ]; then
    return
  fi
  
  echo -e "${YELLOW}Checking for conflicts in $dir...${NC}"
  
  # Create backup directory with timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.config-backup/$timestamp/$dir"
  
  # Find all files in source and check if they exist in target
  find "$source_dir" -type f | while read -r source_file; do
    # Get relative path from source directory
    local rel_path="${source_file#$source_dir/}"
    local target_file="$target_dir/$rel_path"
    
    # If target file exists and is not a symlink, back it up and remove it
    if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
      echo -e "${YELLOW}→ Backing up and removing: $target_file${NC}"
      mkdir -p "$(dirname "$backup_dir/$rel_path")"
      cp "$target_file" "$backup_dir/$rel_path"
      rm "$target_file"
    fi
  done
}

symlink_dotfiles() {
  echo -e "${GREEN}Stowing top-level dotfiles (zsh)...${NC}"

  for file in .zshrc .p10k.zsh; do
    target="$HOME/$file"
    source="$DOTFILES_DIR/zsh/$file"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo -e "${GREEN}Backing up existing $target to ${target}.bak${NC}"
      mv "$target" "${target}.bak"
    fi
  done

  stow --target="$HOME" zsh
}

symlink_config_folders() {
  echo -e "${GREEN}Stowing .config folders with conflict resolution...${NC}"
  cd "$DOTFILES_DIR/.config"

  for dir in */; do
    dir=${dir%/}
    target_dir="$HOME/.config/$dir"
    source_dir="$DOTFILES_DIR/.config/$dir"

    # If the entire target directory exists and isn't a symlink, back it up and remove it
    if [ -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
      # First, backup individual conflicting files
      backup_and_remove_conflicting_files "$dir"
    fi

    echo "→ Stowing $dir → $target_dir"
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

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config-backup"

install_packages
install_zinit
install_lpm_and_plugins
symlink_dotfiles
symlink_config_folders
set_zsh_default_shell

echo -e "${GREEN}Dotfiles setup complete!${NC}"
if [ -d "$HOME/.config-backup" ] && [ "$(ls -A $HOME/.config-backup 2>/dev/null)" ]; then
  echo -e "${YELLOW}Note: Conflicting files have been backed up to ~/.config-backup/${NC}"
fi
