#!/bin/bash
# git clean filter for .codex/config.toml.
# codex CLI appends per-machine [projects."<path>"] trust tables to the user
# config on every "trust this repository" prompt. Strip them at stage time so
# local trust state never enters version control.
exec awk '
  /^\[projects\./ || /^\[projects\]/ { skip = 1; next }
  /^\[/ { skip = 0 }
  {
    if (skip) next
    lines[++n] = $0
  }
  END {
    while (n > 0 && lines[n] == "") n--
    for (i = 1; i <= n; i++) print lines[i]
  }
'
