# Symlink deployment, Homebrew packages, and repo updates are managed by nix
# (see flake.nix apps and darwin/): `nix run .#switch` / `nix run .#update`.
# Only tasks with no nix equivalent remain here.
DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help

.PHONY: patches
patches: ## Apply claude -p replacement patches to plugin caches
	@bash $(DOTPATH)/tools/patches/apply.sh

.PHONY: hunk-skill
hunk-skill: ## Re-sync bundled hunk-review skill from the installed hunk
	@cp "$$(hunk skill path)" $(DOTPATH)/.claude/skills/hunk-review/SKILL.md
	@echo "Synced .claude/skills/hunk-review/SKILL.md from $$(hunk --version)"

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
