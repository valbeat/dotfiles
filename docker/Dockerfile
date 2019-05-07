# Install linuxbrew
FROM linuxbrew-trusty

ARG USERNAME=dotfiles-sandbox

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

# Add user and grant sudo privileges
RUN groupadd ${USERNAME} \
  && useradd -g ${USERNAME} -G sudo -m -s /bin/zsh ${USERNAME} \
  && echo "${USERNAME}:${USERNAME}" | chpasswd \
  && echo "Defaults visiblepw" >> /etc/sudoers \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}/
ENV SHELL=/bin/zsh

RUN sudo chown -R $(whoami) /home/linuxbrew/.linuxbrew
RUN sudo chsh -s $(which zsh) $(whoami)

RUN touch ~/.zshrc

CMD ["/bin/zsh"]
