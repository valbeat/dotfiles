{ ... }:
{
  imports = [
    ./system-defaults.nix
    ./homebrew.nix
  ];

  # Platform / user
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "takuma";
  users.users.takuma.home = "/Users/takuma";

  # This host uses Determinate Nix, which manages the Nix installation with
  # its own daemon. Disable nix-darwin's native Nix management to avoid the
  # conflict. (nix-command/flakes are already enabled by Determinate, so the
  # `nix.*` settings options are intentionally not used here.)
  nix.enable = false;

  # Manage /etc/zshrc so the nix environment is on PATH.
  # The existing ~/.zshrc is sourced afterwards and stays untouched.
  programs.zsh.enable = true;

  # sudo は Touch ID で認証する。reattach を付けないと tmux や Orca のような
  # 多重化された端末の中で pam_tid が bootstrap session を掴めず失敗する。
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # 認証タイムスタンプを端末ごとではなくユーザー単位で共有する。
  # 既定の timestamp_type=tty では、実端末で認証しても別セッション
  # （エージェント経由の非対話シェルなど）には引き継がれず、
  # `nix run .#switch` のたびに TTY のある端末へ行く必要がある。
  # global にすると、実端末で `sudo -v` を一度通せば timestamp_timeout の
  # 間だけ他のセッションからも sudo が通る。期限切れで元に戻る。
  security.sudo.extraConfig = ''
    Defaults timestamp_type=global
  '';

  # Used for backwards compatibility of stateful data. Bump only with care.
  system.stateVersion = 5;
}
