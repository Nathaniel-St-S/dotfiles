#!/usr/bin/env bash
set -e

echo "🔗 Stowing dotfiles into your home directory..."

# Stow home-level dotfiles (like .zshrc, .gitconfig, .p10k.zsh, etc.)
stow -t "$HOME" .

# Stow everything inside .config to ~/.config
if [ -d ".config" ]; then
  echo "🔗 Stowing .config contents..."
  stow -t "$HOME/.config" .config
fi

echo "✅ All dotfiles have been symlinked."

