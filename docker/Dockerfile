FROM ubuntu:16.04

ARG USERNAME=dotfiles-sandbox

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

# For jp_JP.UTF-8 and JST(Asia/Tokyo)
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
RUN apt-get update \
  && apt-get install -y language-pack-ja tzdata \
  && update-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja" \
  && echo "${TZ}" > /etc/timezone \
  && rm /etc/localtime \
  && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
  && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Add user and grant sudo privileges
RUN groupadd -g 1000 ${USERNAME} \
  && useradd -g ${USERNAME} -G sudo -m -s /bin/zsh ${USERNAME} \
  && echo "${USERNAME}:${USERNAME}" | chpasswd \
  && echo "Defaults visiblepw" >> /etc/sudoers \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
WORKDIR /home/${USERNAME}/

CMD ["/bin/bash"]
