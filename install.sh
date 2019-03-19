#!/bin/bash

DOTPATH=$(cd $(dirname "${0}") && pwd)

if [ -z "${HOME}" ]; then
  HOME=$(cd ~ && pwd)
fi

# link dotfiles
for f in .??*; do
  [ "$f" == ".git" ] && continue
  if [[ "$f" =~ ^\.* ]]; then
    ln -snfv "$DOTPATH/$f" "$HOME/$f"
  fi
done
