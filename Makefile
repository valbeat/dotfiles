# Symlink deployment, Homebrew packages, and repo updates are managed by nix
# (see flake.nix apps and darwin/): `nix run .#switch` / `nix run .#update`.
# Only tasks with no nix equivalent remain here.
DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
# Skills live in the private plugin marketplace, not in this repo.
PLUGINS_PRIVATE ?= $(HOME)/src/github.com/valbeat/agent-plugins-private

.DEFAULT_GOAL := help

.PHONY: patches
patches: ## Apply claude -p replacement patches to plugin caches
	@bash $(DOTPATH)/tools/patches/apply.sh

.PHONY: hunk-skill
hunk-skill: ## Re-sync the hunk-review skill in agent-plugins-private from the installed hunk
	@cp "$$(hunk skill path)" $(PLUGINS_PRIVATE)/plugins/portable-tools/skills/hunk-review/SKILL.md
	@echo "Synced portable-tools/skills/hunk-review/SKILL.md from $$(hunk --version)"
	@echo "Bump portable-tools version (both .claude-plugin and .codex-plugin plugin.json) in agent-plugins-private and open a PR to ship it."

.PHONY: test
test: ## Run repo tests (tools/tests/*.sh)
	@status=0; for t in $(DOTPATH)/tools/tests/test-*.sh; do \
		echo "== $$(basename $$t)"; bash $$t || status=1; done; exit $$status

.PHONY: settings-diff
settings-diff: ## Show what the next nix switch would change in ~/.claude, ~/.gemini and agy settings.json
	@bash $(DOTPATH)/tools/settings-diff.sh

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
