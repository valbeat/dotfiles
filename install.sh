#!/bin/bash

DOTPATH=$(cd $(dirname "${0}") && pwd)

if [ -z "${HOME}" ]; then
  HOME=$(cd ~ && pwd)
fi

# link dotfiles
for f in ${DOTPATH}/.??*; do
  dotfile=$(basename $f)
  [ "${dotfile}" == ".git" ] && continue
  if [[ "${dotfile}" =~ ^\.* ]]; then
    ln -snfv "${DOTPATH}/${dotfile}" "${HOME}/${dotfile}"
  fi
done
