.PHONY: test
test: deploy ## Test for successful initialization
DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodules .github
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: list
list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), ls -dF $(val);)

.PHONY: deploy
deploy: ## Create symlink to home directory
	@echo "Start to deploy dotfiles to home directory."
	@echo ""
	@$(foreach dotfile, $(DOTFILES), ln -sfnv $(abspath $(DOTPATH)/$(dotfile) $(HOME)/$(dotfile));)

.PHONY: update
update: ## Fetch changes for this repo
	@git pull origin master
	@git submodule update --init
	@git submodule foreach git pull origin master

.PHONY: install
install: clean deploy ## Run make deploy, init

.PHONY: brew
brew: ## Install packages from Brewfile
	@echo "Start to install packages from Brewfile."
	@echo ""
	@brew bundle --file=$(DOTPATH)/Brewfile

.PHONY: brew-dump
brew-dump: ## Update Brewfile from current environment
	@echo "Start to dump Brewfile from current environment."
	@echo ""
	@brew bundle dump --force --file=$(DOTPATH)/Brewfile

.PHONY: patches
patches: ## Apply claude -p replacement patches to plugin caches
	@bash $(DOTPATH)/tools/patches/apply.sh

.PHONY: backup
backup: ## Copy target dotfiles to repository
	@echo "Start to backup dotfiles to repository."
	@echo ""
	-@$(foreach dotfile, $(DOTFILES), cp -rn $(abspath $(HOME)/$(dotfile) $(DOTPATH)/$(dotfile));)

.PHONY: clean
clean: ## Copy target dotfiles to repository
	@echo "Start to clean dotfiles."
	@echo ""
	-@$(foreach dotfile, $(DOTFILES), mv $(abspath $(HOME)/$(dotfile) /tmp/$(dotfile));)

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

