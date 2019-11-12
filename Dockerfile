FROM linuxbrew/linuxbrew

ARG USERNAME=dotfiles-sandbox
ENV SHELL=/bin/zsh

USER root

# Install apt packages
# Instead of `apt-get clean` to make it more effective
RUN set -eux \
   && apt-get update \
   && apt-get dist-upgrade -y \
   && apt-get install -y \
     sudo \
     git \
     zsh \
     software-properties-common \
     build-essential \
     curl \
     file \
     python-setuptools \
     ruby \
     tmux \
     vim \
   && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Set Locale
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
  && locale-gen en_US.UTF-8 \
  && export LC_ALL=en_US.UTF \
  && export LANG=en_US.UTF-8

# Add user and grant sudo privileges
RUN groupadd ${USERNAME} \
  && useradd -g ${USERNAME} -G sudo -m -s /bin/zsh ${USERNAME} \
  && echo "${USERNAME}:${USERNAME}" | chpasswd \
  && echo "Defaults visiblepw" >> /etc/sudoers \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && chown -R ${USERNAME} /home/linuxbrew/.linuxbrew \
  && chsh -s $(which zsh) ${USERNAME}

USER ${USERNAME}

RUN set -eux \
  && brew update

# Copy dotfiles
COPY --chown=dotfiles-sandbox:dotfiles-sandbox . /home/dotfiles-sandbox/dotfiles
WORKDIR /home/dotfiles-sandbox

RUN cd dotfiles \
  && make install

CMD ["zsh"]
