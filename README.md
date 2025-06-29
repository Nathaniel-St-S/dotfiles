# 🗃️ dotfiles — My Configs, Backed Up with Stow
  -Follow this video for advice [Setup Tutorial](https://www.youtube.com/watch?v=y6XCebnB9gs)

My personal dotfiles repo! This is where I version-control the configuration files that customize my development environment. Everything here is managed using [GNU Stow](https://www.gnu.org/software/stow/) to keep things clean, modular, and easily symlinked to my `$HOME` directory.

---

## ✨ Purpose

This repo is designed to:

- 🧩 **Back up** my essential dotfiles
- 🔁 **Synchronize** settings across systems
- 🧼 **Modularize** config with [GNU Stow](https://www.gnu.org/software/stow/)
- 🛠️ **Restore** a working setup fast on a fresh install

Whether I'm setting up a new machine or recovering from a system wipe, this repo helps me get back on my feet quickly and confidently.

---

## 📦 Dependencies

### 1. [Git](https://git-scm.com/)

To clone and manage the repository.

- **Install on Ubuntu/Debian:**
  ```bash
  sudo apt update
  sudo apt install git
  
- **Install on macOS (with Homebrew):Install on macOS (with Homebrew):**
  ```bash
  brew install git
  ```

### 2. GNU Stow [GNU Stow](https://www.gnu.org/software/stow/)

To manage symlinks from the repo into your home directory.

- **Install on Ubuntu/Debian:**
```bash
  sudo apt update
  sudo apt install stow
```

- **Install on macOS (with Homebrew):**
```
brew install stow
```


### 📁 Structure

Each application or tool I configure gets its own folder. For example, the structure looks like this:
dotfiles/
├── install.sh
├── zsh.rc
├── .config/
│   └── lite-xl/
│   └── racket/
│   └── klassy/

### 🚀 Usage

Once you've cloned the repo and installed the dependencies:
```
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Stow all configurations
stow zsh
stow lite-xl
```

- **To unstow a package (remove symlinks):**
```
stow -D zsh
```
