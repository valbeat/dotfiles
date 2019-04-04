DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodules
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: list
list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

.PHONY: deploy
deploy: ## Create symlink to home directory
	@echo "Start to deploy dotfiles to home directory."
	@echo ""
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(DOTPATH)/$(val) $(HOME)/$(val));)

.PHONY: init
init: ## Setup environment settings
	@echo "init is inactive temporarily"

.PHONY: test
test: ## Test dotfiles and init scripts
	@echo "Start to test dotfiles in docker container."
	@echo ""
	@docker run -it -v $(DOTPATH):/home/dotfiles-sandbox/dotfiles valbeat/dotfiles-sandbox:latest /bin/bash


.PHONY: update
update: ## Fetch changes for this repo
	git pull origin master
	git submodule update --init
	git submodule foreach git pull origin master

.PHONY: install
install: update deploy init ## Run make update, deploy, init
	@exec $$SHELL

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

