#!/bin/bash

DOTPATH=$(cd $(dirname "${0}") && pwd)

if [ -z "${HOME}" ]; then
  HOME=$(cd ~ && pwd)
fi

# link dotfiles
for f in $HOME/.??*; do
  if [[ "$f" =~ ^\.* ]]; then
     cp -rn $f ./
  fi
done

