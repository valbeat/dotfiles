FROM valbeat/dotfiles-sandbox:latest

COPY --chown=dotfiles-sandbox:dotfiles-sandbox . /home/dotfiles-sandbox/dotfiles

RUN cd dotfiles \
  && make test

WORKDIR /home/dotfiles-sandbox/dotfiles

CMD ["make"]
