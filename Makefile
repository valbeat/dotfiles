DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodules
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

.PHONY: init
init: ## Setup environment settings
	@brew bundle --file=~/.brewfile

.PHONY: test
test: ## Test dotfiles and init scripts
	@echo "Start to test dotfiles in docker container."
	@echo ""
	@docker run -it -v $(DOTPATH):/home/dotfiles-sandbox/dotfiles valbeat/dotfiles-sandbox:latest /bin/bash

.PHONY: update
update: ## Fetch changes for this repo
	@git pull origin master
	@git submodule update --init
	@git submodule foreach git pull origin master

.PHONY: install
install: backup update deploy init ## Run make update, deploy, init
	@exec $$SHELL

.PHONY: backup
backup: ## Copy target dotfiles to repository
	@echo "Start to backup dotfiles to repository."
	@echo ""
	@$(foreach dotfile, $(DOTFILES), cp -rn $(abspath $(HOME)/$(dotfile) $(DOTPATH)/$(dotfile));)

.PHONY: clean
clean: ## Copy target dotfiles to repository
	@echo "Start to clean dotfiles."
	@echo ""
	@$(foreach dotfile, $(DOTFILES), mv $(abspath $(HOME)/$(dotfile) /tmp/$(dotfile));)

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

