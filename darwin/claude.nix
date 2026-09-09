# home-manager module: the Claude Code and Gemini CLI settings this repository
# owns, merged into the live settings files at activation.
#
# Why merge instead of symlink or copy: Claude Code writes to
# ~/.claude/settings.json itself (`/model`, `/config`, auto mode's per-project
# `autoMode` block, plugin installs) and Orca injects its agent-status hooks
# there on every launch. A read-only store symlink breaks those writes, and a
# plain copy discards them on every switch. So the live file stays a regular,
# untracked file and `nix run .#switch` folds the managed keys into it with
# darwin/claude/merge.jq (managed wins; unnamed keys pass through; hooks are
# unioned). The same applies to ~/.gemini/settings.json.
#
# To change a setting: edit the attrset below, then `nix run .#switch`.
# Tests for the merge rules: tools/tests/test-merge-settings.sh
{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  jsonFormat = pkgs.formats.json { };

  # iTerm2's bundled status reporter (badge / attention when Claude needs
  # input). macOS-only; the symlink ~/.config/iterm2/cc-status ->
  # iTerm.app/Contents/Resources/utilities/cc-status is created by hand.
  ccStatusHook = {
    hooks = [
      {
        type = "command";
        command = "${home}/.config/iterm2/cc-status";
        async = true;
      }
    ];
  };
  ccStatusEvents = [
    "Notification"
    "PermissionRequest"
    "PostToolUse"
    "PreToolUse"
    "SessionEnd"
    "SessionStart"
    "Stop"
    "StopFailure"
    "SubagentStop"
    "UserPromptSubmit"
  ];
  ccStatusHooks = lib.optionalAttrs pkgs.stdenv.isDarwin (
    lib.genAttrs ccStatusEvents (_: [ ccStatusHook ])
  );

  ownHooks = {
    PreToolUse = [
      {
        matcher = "Bash|Write|Edit|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/guard.sh";
          }
        ];
      }
    ];
    PostToolUse = [
      {
        matcher = "Write|Edit|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/format.sh";
          }
        ];
      }
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/log-tooluse.sh";
          }
        ];
      }
    ];
  };

  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    cleanupPeriodDays = 30;
    env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    attribution.sessionUrl = false;
    includeCoAuthoredBy = false;

    # `model` is deliberately absent: it is chosen per session (see the
    # Model Selection Policy in .claude/CLAUDE.md), and `/model` writes it
    # into the live file, which the merge leaves alone.
    permissions = {
      allow = [
        "Read"
        "Write"
        "Edit"
        "MultiEdit"
        "Glob"
        "Grep"
        "WebFetch"
        "TodoWrite"
        "NotebookEdit"
        # Task (subagents) stays allowed: hooks/guard.sh blocks `claude -p`
        # and points skills at Task as the in-subscription replacement.
        "Task"
      ];
      deny = [
        "Bash(sudo rm -rf *)"
        "Bash(sudo mkfs *)"
        "Bash(sudo dd *)"
        "Bash(rm -rf /)"
        "Bash(chmod 777 *)"
        "Read(.env)"
        "Read(.env.*)"
        "Read(~/.ssh/**)"
        "Read(~/.aws/**)"
        "Read(~/.kube/config)"
        "Read(~/.docker/config.json)"
        "Read(~/.config/gcloud/**)"
        "Read(~/.azure/**)"
      ];
      ask = [ ];
      defaultMode = "auto";
    };

    hooks = lib.zipAttrsWith (_: lib.concatLists) [
      ownHooks
      ccStatusHooks
    ];

    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
      padding = 0;
    };

    enabledPlugins = {
      "claude-md-management@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "codex@openai-codex" = true;
      "design@valbeat-plugins" = true;
      "dev-workflow@valbeat-plugins" = true;
      "git-workflow@valbeat-plugins" = true;
      "modularity@vladikk-modularity" = true;
      "personal-tools@valbeat-plugins-private" = true;
      "ralph-loop@claude-plugins-official" = true;
      "skill-tools@valbeat-plugins" = true;
      "slack@claude-plugins-official" = true;
      "vercel@claude-plugins-official" = true;
      "writing@valbeat-plugins" = true;
      "aws-agents@agent-toolkit-for-aws" = true;
      "aws-agents-for-devsecops@agent-toolkit-for-aws" = true;
      "aws-core@agent-toolkit-for-aws" = true;
      "aws-data-analytics@agent-toolkit-for-aws" = true;
    };
    extraKnownMarketplaces = {
      openai-codex.source = {
        source = "github";
        repo = "openai/codex-plugin-cc";
      };
      valbeat-plugins.source = {
        source = "github";
        repo = "valbeat/claude-plugins";
      };
      valbeat-plugins-private.source = {
        source = "github";
        repo = "valbeat/claude-plugins-private";
      };
      vladikk-modularity.source = {
        source = "github";
        repo = "vladikk/modularity";
      };
      agent-toolkit-for-aws.source = {
        source = "git";
        url = "git@github.com:aws/agent-toolkit-for-aws.git";
      };
    };

    # UI preferences
    language = "Japanese";
    alwaysThinkingEnabled = true;
    tui = "default";
    theme = "dark-daltonized";
    editorMode = "vim";
    verbose = true;
    teammateMode = "auto";
    skipDangerousModePermissionPrompt = true;
    skipWorkflowUsageWarning = true;
    skipAutoPermissionPrompt = true;
    inputNeededNotifEnabled = true;
    agentPushNotifEnabled = true;
    remoteControlAtStartup = true;
    voiceEnabled = true;
  };

  geminiSettings = {
    theme = "Default";
    selectedAuthType = "oauth-personal";
    contextFileName = "AGENTS.md";
  };

  # Shell snippet: merge the generated <managed> JSON into <target> in place.
  # Seeds an empty target, refuses to touch a target that is not valid JSON,
  # and only rewrites the file when the merge actually changes it.
  mergeInto =
    target: managed:
    let
      jq = lib.getExe pkgs.jq;
    in
    ''
      target=${lib.escapeShellArg target}
      managed=${managed}
      if [[ -n "''${DRY_RUN:-}" ]]; then
        echo "would merge $managed into $target"
      else
        mkdir -p "$(dirname "$target")"
        [[ -s "$target" ]] || echo '{}' > "$target"
        if ! ${jq} -e . "$target" >/dev/null 2>&1; then
          echo "claude.nix: $target is not valid JSON; leaving it untouched" >&2
        else
          tmp=$(mktemp "$target.XXXXXX")
          if ${jq} --argjson managed "$(cat "$managed")" -f ${./claude/merge.jq} "$target" > "$tmp"; then
            if cmp -s "$tmp" "$target"; then
              rm -f "$tmp"
            else
              mv "$tmp" "$target"
              echo "merged managed settings into $target"
            fi
            chmod 644 "$target"
          else
            rm -f "$tmp"
            echo "claude.nix: merge into $target failed" >&2
            exit 1
          fi
        fi
      fi
    '';
in
{
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    mergeInto "${home}/.claude/settings.json" (
      jsonFormat.generate "claude-settings.json" claudeSettings
    )
  );

  home.activation.geminiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    mergeInto "${home}/.gemini/settings.json" (
      jsonFormat.generate "gemini-settings.json" geminiSettings
    )
  );
}
