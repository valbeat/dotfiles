FROM valbeat/dotfiles-sandbox:latest

COPY --chown=dotfiles-sandbox:dotfiles-sandbox . /home/dotfiles-sandbox/dotfiles

RUN cd dotfiles \
  && make test

CMD ["/bin/zsh"]
