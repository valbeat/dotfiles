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

.PHONY: test
test: ## Run repo tests (tools/tests/*.sh)
	@status=0; for t in $(DOTPATH)/tools/tests/test-*.sh; do \
		echo "== $$(basename $$t)"; bash $$t || status=1; done; exit $$status

.PHONY: settings-diff
settings-diff: ## Show what the next nix switch would change in ~/.claude and ~/.gemini settings.json
	@bash $(DOTPATH)/tools/settings-diff.sh

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
