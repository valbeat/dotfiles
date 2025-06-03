# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository that manages development environment configurations using a symlink-based approach. All dotfiles are stored at the repository root and deployed to the home directory via Makefile commands.

## Common Commands

### Installation and Setup
- `make install` - Clean existing dotfiles and create symlinks (main installation)
- `make deploy` - Create symlinks from repository to home directory
- `make clean` - Move existing dotfiles to /tmp as backup
- `make backup` - Copy dotfiles from home directory to repository
- `make update` - Pull latest changes and update git submodules
- `make list` - Show all dotfiles managed by this repository

### Development Workflow
When modifying dotfiles:
1. Edit files directly in the repository
2. Changes take effect immediately (files are symlinked)
3. Test changes in your environment
4. Commit when satisfied

## Architecture

### File Organization
- All dotfiles are stored at the repository root level
- The Makefile handles deployment logic, excluding system files (`.DS_Store`, `.git`, `.gitmodules`, `.github`)
- Symlinks are used for non-destructive installation

### Key Configurations
- **Git**: Modular setup with `.gitconfig` (main), `.gitconfig.osx` (macOS-specific), and `.gitconfig.local` (user-specific overrides)
- **Vim**: Uses `dein.vim` plugin manager with plugins defined in `.vim/rc/dein.toml`
- **Zsh**: Modern setup using `zplug` for plugin management
- **macOS**: System preferences configured via `.osx` script

### Notable Features
- Git aliases include AI-powered commit message generation using `aichat`
- Extensive vim plugin ecosystem for multiple languages
- Integration with modern tools: `fzf`, `ghq`, `tmux`, `tig`
- Amazon Q integration in shell configuration

## Testing
Tests are maintained in a separate repository (`dotfiles-testing`) to keep this repository focused on configurations only.