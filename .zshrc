#power-line
#source "$HOME/.anyenv/envs/pyenv/versions/3.5.2/lib/python3.5/site-packages/powerline/bindings/zsh/powerline.zsh"
#--------------------------------------
# プラグイン
#--------------------------------------
source ~/.zplug/init.zsh


## zplug
## 拡張
#zplug "mollifier/anyframe"
#zplug "Tarrasch/zsh-functional"
zplug "zsh-users/zsh-syntax-highlighting", defer:2, lazy:true
#zplug "b4b4r07/zsh-vimode-visual", defer:3

# テーマ
## Liquid prompt
#LP_ENABLE_TIME=1
#LP_USER_ALWAYS=1
#LP_ENABLE_GIT=0
#LP_ENABLE_SVN=0
#LP_ENABLE_HG=0
# 改行
#LP_PS1_POSTFIX="
#$ "
#zplug 'nojhan/liquidprompt'

## pure
zplug "mafredri/zsh-async", defer:1
zplug "sindresorhus/pure", defer:2, \
  hook-load:"{
    PURE_GIT_DELAY_DIRTY_CHECK=1000
  }
  "
# 通知 
# メモリ食うので一旦OFF
#zplug "marzocchi/zsh-notify"
#export SYS_NOTIFIER="usr/local/bin/terminal-notifier"
# cd 系
#zplug "knu/z"
#zplug "Tarrasch/zsh-bd"
# gitルートへcd
zplug "mollifier/cd-gitroot", lazy:true
# githubをブラウザで開く
#zplug "peterhurford/git-it-on.zsh"

#zplug "ascii-soup/zsh-url-highlighter"

# 補完
zplug "zsh-users/zsh-completions", lazy:true

# git br用
#zplug "jhawthorn/fzy", \
#    as:command, \
#    hook-build:'make'
#zplug "b4b4r07/git-br", \
#    as:command, \
#    use:'git-br'
# open git hub
#zplug "paulirish/git-open", as:command

# 遅いのでコメントアウト
# Install plugins if there are plugins that have not been installed
#if ! zplug check --verbose; then
#    printf "Install? [y/N]: "
#    if read -q; then
#        echo; zplug install
#    fi
#fi

# Then, source plugins and add commands to $PATH
zplug load --verbose

#--------------------------------------
# 言語設定
#--------------------------------------
export LANG=ja_JP.UTF-8

# -------------------------------------
# 環境変数
# -------------------------------------
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
# SSHで接続した先で日本語が使えるようにする
export LANG=ja_JP.UTF-8

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# エディタ
export EDITOR=/usr/local/bin/vim

# ページャ
#export PAGER=vimpager
#export MANPAGER=vimpager


if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

#色の定義
local DEFAULT=$'%{^[[m%}'$
local RED=$'%{^[[1;31m%}'$
local GREEN=$'%{^[[1;32m%}'$
local YELLOW=$'%{^[[1;33m%}'$
local BLUE=$'%{^[[1;34m%}'$
local PURPLE=$'%{^[[1;35m%}'$
local LIGHT_BLUE=$'%{^[[1;36m%}'$
local WHITE=$'%{^[[1;37m%}'$

# vimモード
set -o vi 

# for brew dotnet
# ref: http://monry.hatenablog.com/entry/2018/01/20/235901
# system-wide environment settings for zsh(1)
if [ -x /usr/libexec/path_helper ]; then
  eval `/usr/libexec/path_helper -s`
fi



# -------------------------------------
# prompt
# -------------------------------------
source "$HOME/bin/zsh-gkeadm-prompt"
setopt transient_rprompt

# -------------------------------------
# zshのオプション
# -------------------------------------

# cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# 補完
# zplug内でloadしてるので不要
# autoload -Uz compinit && compinit

## 補完候補をキャッシュする。
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
## 詳細な情報を使わない
zstyle ':completion:*' verbose no
#ファイル補完候補に色を付ける
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct
# ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash
# ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt mark_dirs            
# 補完候補一覧でファイルの種別を識別マーク表示 (訳注:ls -F の記号) 
setopt list_types            
# 補完キー連打で順に補完候補を自動で補完
setopt auto_menu
# カッコの対応などを自動的に補完
setopt auto_param_keys       
# コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments
# コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt magic_equal_subst
# 語句の途中でもカーソル位置で補完
setopt complete_in_word
# カーソル位置は保持したままファイル名一覧を順次その場で表示
setopt always_last_prompt
# 補完開始時に絞り込み開始
# zstyle ':completion:*' menu select interactive
# zstyle ':completion:*:default' menu select=2
# setopt menu_complete

# ファイル補完の高速化
__git_files() { _files }

# ssh host
function print_known_hosts (){
    if [ -f $HOME/.ssh/known_hosts ]; then
        cat $HOME/.ssh/known_hosts | tr ',' ' ' | cut -d' ' -f1
    fi
}
_cache_hosts=($( print_known_hosts ))

# cd ls
# タブによるファイルの順番切り替えをしない
unsetopt auto_menu
# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd
# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd
# 自動でpushdを実行
setopt auto_pushd
# pushdから重複を削除
setopt pushd_ignore_dups

# cdrコマンドで履歴にないディレクトリにも移動可能に
zstyle ":chpwd:*" recent-dirs-default true
# 中間ファイルを補完しない
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?~' '*\#'
#あらかじめcdpathを適当に設定しておく
cdpath=(~)
# カレントディレクトリに候補がない場合のみ cdpath 上のディレクトリを候補に出す
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
# 親ディレクトリからカレントディレクトを表示させないようにする (例: cd ../<TAB>):
zstyle ':completion:*:cd:*' ignore-parents parent pwd
#LS_COLORSを設定しておく
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# history
# 他のターミナルとヒストリーを共有
setopt share_history
# ヒストリーに重複を表示しない
setopt histignorealldups

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# 色を使う
setopt prompt_subst

# ^Dでログアウトしない。
setopt ignoreeof

# ビープ音を流さない
setopt no_beep
setopt no_nomatch
# コマンド実行後は右プロンプトを消す
setopt transient_rprompt
# sudoの際にコマンドを探す
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# markdownをw3mで見る
ress() {
    FILENAME=$1
    if [ $# -lt 1 ]; then
        echo "Usage: $0 FILENAME"
    else
        github-markup $FILENAME | w3m -T text/html
    fi
}
# -------------------------------------
# パス
# -------------------------------------
export PATH="$PATH:/usr/local/git/bin"
export PATH="$PATH:/Applications/MacVim.app/Contents/MacOS"
export PATH="$PATH:/opt/ImageMagick/bin"
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="$HOME:/.composer/vendor/bin:$PATH"
# go
export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME
export PATH=$PATH:$GOPATH/bin
export GOENVTARGET=$HOME/.goenvtarget
export PATH=$GOENVTARGET:$PATH
export GO15VENDOREXPERIMENT=1
# dotnet
export PATH=$PATH:$HOME/dotnet
# coreutilsのシンボリックリンク
export PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
# 重複する要素を自動的に削除
typeset -U path cdpath fpath manpath

path=(
    $HOME/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    $path
)


# anyenv
if [ -d $HOME/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    eval "$(anyenv init -)"
    # tmux対応
    for D in `\ls $HOME/.anyenv/envs`
    do
        export PATH="$HOME/.anyenv/envs/$D/shims:$PATH"
    done
fi

eval "$(direnv hook zsh)"
# -------------------------------------
# プロンプト
# -------------------------------------
#テーマで設定しているため不要
autoload -U promptinit; promptinit

# 間違えたときに出るコマンド
SPROMPT="%{${fg[red]}%}Did you mean?: %R -> %r [nyae]? %{${reset_color}%}"

chpwd() {
    ls -F
}

256colortest() {
    local code
    for code in {0..255}
    do
        echo -e "\e[38;05;${code}m $code: Test"
    done
}

# -------------------------------------
# エイリアス
# -------------------------------------

# -n 行数表示, -I バイナリファイル無視, svn関係のファイルを無視
alias grep="grep --color -I --exclude='*.svn-*' --exclude='entries' --exclude='*/cache/*'"

# ls
alias ls="ls -G" # color for darwin
alias lt="ls -lt"
alias ltr="ls -ltr"
alias ll="ls -l"
alias la="ls -la"
alias l1="ls -1"
alias lly="ls -l --time-style=long-iso"

alias cdg='cd-gitroot'
alias cp='cp -i'
alias rm='rm -i'
alias back='pushd'
alias tree="tree -NC" # N: 文字化け対策, C:色をつける
alias aw=anyframe-widget-select-widget

alias viRename=massren

# git
alias g='git'
alias tg='tig'
alias tgc='git branch | fzf | xargs tig'

# vim
export EDITOR=/Applications/MacVim.app/Contents/MacOS/Vim
alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'

alias tmux="TERM=screen-256color-bce tmux"

# iterm
alias ssh="ssh-iterm-profile-setting"

alias today="date '+%Y%m%d'"

alias updatedb='sudo /usr/libexec/locate.updatedb'

# windowsのNASのパスをmacのsmb://に変換
alias to-smb="tr '\' '/' | xargs -I {} echo 'smb:'{}"

# 左に指定した入力にのみ存在する行を出力
alias diffl='diff --old-line-format="%L" --unchanged-line-format="" --new-line-format=""'
# 右に指定した入力にのみ存在する行を出力
alias diffr='diff --old-line-format="" --unchanged-line-format="" --new-line-format="%L"'
# 両方に存在する行にみを出力
alias diffc='diff --old-line-format="" --unchanged-line-format="%L" --new-line-format=""'


# 拡張子列挙
alias ext-list="find . -type f -not -iwholename '*/.git/*' | sed -e 's/^.*\///' | grep '\.' | sed -e 's/^.*\.//' | sort | uniq -c | sort -nr"

# docker
alias fig=docker-compose
# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }
# Get container process
alias dps="docker ps -a"

# Execute interactive container, e.g., $dex base /bin/bash
alias dex="docker exec -i -t"

# get container ip address
alias dip="docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

# get ip address all containers
_docker_show_ip_all() {
  docker ps -a -q | xargs docker inspect --format '{{.Name}}  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
}
alias dipa=_docker_show_ip_all
# Stop all containers
_docker_stop_all() { docker stop $(docker ps -a -q); }
alias dstop=_docker_stop_all

# Stop select container
_docker_fzf_stop() {
  local line=`docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"| awk 'NR != 1 {print}' | fzf`
  if [ "$line" != "" ]; then
    id=`echo $line | awk '{print $1}'`
    docker stop ${id}
  fi
}
alias dfstop=_docker_fzf_stop

# Remove all containers (only stopped)
drm() { docker rm $(docker ps -a -q); }
# Remove all images
drmi() { docker rmi $(docker images -q); }
# exec select
_docker_exec_sh() { 
  local line=`docker ps --format "table {{.Names}}" | awk 'NR != 1 {print}' | fzf`
  if [ "$line" != "" ]; then
    docker exec -it ${line} sh
  fi
}
alias dsh=_docker_exec_sh

# kubectl
alias k=kubectl
alias kx=kubectx
alias kn=kubens

alias kgp='kubectl get pod'
alias kdp='kubectl describe pod'
alias keit='kubectl exec -it'

# gcloud

function _gcloud_set_account() {
  local account=$(gcloud auth list --format="value(account)" | fzf | awk '{print $1}')
  if [[ -n $account ]]; then
    gcloud config set account $account
    return $?
  fi
}
alias gsa=_gcloud_set_account

function _gcloud_set_project() {
  local proj=$(gcloud projects list | fzf --header-lines=1 | awk '{print $1}')
  if [[ -n $proj ]]; then
    gcloud config set project $proj
    return $?
  fi
}
alias gsp=_gcloud_set_project

function _gcloud_activate_configuration() {
  local config=$(gcloud config configurations list | fzf --header-lines=1 | awk '{print $1}' )
  if [[ -n $config ]]; then
    gcloud config configurations activate $config
    return $?
  fi
}
alias gac=_gcloud_activate_configuration

# vagrant
alias vgkey="vagrant ssh-config | grep IdentityFile | sed -e 's/IdentityFile//' | sed -e 's/^[ ]*//'"

# -------------------------------------
# キーバインド
# -------------------------------------

bindkey -v

function cdup() {
   echo
   cd ..
   zle reset-prompt
}
zle -N cdup
bindkey '^K' cdup

bindkey "^R" history-incremental-search-backward

# -------------------------------------
# その他関数
# -------------------------------------
# iTerm2のタブ名を変更する
case "${TERM}" in
kterm*|xterm)
    precmd() {
        echo -ne "\033]0;${USER}@${HOST}\007"
    }
    ;;
esac

# gitのrootへ移動
function git-root() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd $PWD/$(git rev-parse --show-cdup)
  fi
}

# Finderのアクティブウィンドウのパスにターミナルで移動
function cdf () {
  target=`osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)'`
  if [ "$target" != "" ]
  then
    cd "$target"
    pwd
  else
    echo 'No Finder window found' >&2
  fi
}

function _fzf_ssh() {
  local host="$(command egrep -i '^Host\s+.+' $HOME/.ssh/config $(find $HOME/.ssh/conf.d -type f 2>/dev/null) | command egrep -v '[*?]' | awk '{print $2}'| sort | fzf --select-1 -e --prompt "HOST >" --query "$LBUFFER")"
  if [ "$host" == "" ]; then
    exit
  fi
  ssh $host 
}
alias fssh=_fzf_ssh


#-------------------------------------
# iTerm2
#-------------------------------------

# shell integration
source ~/.iterm2_shell_integration.`basename $SHELL`

# title
function chpwd() { ls; echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print "/"$1"/"$2}'| rev)\007"}

# color
tab-color() {
    echo -ne "\033]6;1;bg;red;brightness;$1\a"
    echo -ne "\033]6;1;bg;green;brightness;$2\a"
    echo -ne "\033]6;1;bg;blue;brightness;$3\a"
}

tab-reset() {
    echo -ne "\033]6;1;bg;*;default\a"
}

alias top='tab-color 134 200 0; top; tab-reset'
#-------------------------------------
# brew
#-------------------------------------

# CaskのシンボリックリンクをApplicationsに
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export PATH="$PATH:/Applications/android-sdk/sdk/platform-tools"
export PATH="$PATH:$HOME/Library/Android/sdk"
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"


#-------------------------------------
# fzf
#-------------------------------------

# exp: ls | p cd
p() { fzf | while read LINE; do $@ $LINE; done }

# Ctrl + ] => ghq
function fzf-src () {
  local dir=$(ghq root)/$(ghq list | fzf -e --prompt "REPO >")
  if [ ! -n "$dir" ]; then
    return 0
  fi
  cd ${dir}
  zle clear-screen
}
zle -N fzf-src
bindkey '^]' fzf-src

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#-------------------------------------
# google cloud sdk
#-------------------------------------
## Set path for GoogleCloudSDK
export GCLOUD_SDK="$HOME/google-cloud-sdk"
export PATH="$PATH:$GCLOUD_SDK/bin"

## Set path for App Engine SDK for GO
export APPENGINE_SDK="$GCLOUD_SDK/platform/google_appengine"
export PATH="$PATH:$APPENGINE_SDK"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$GCLOUD_SDK/path.zsh.inc" ]; then source "$GCLOUD_SDK/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$GCLOUD_SDK/completion.zsh.inc" ]; then source "$GCLOUD_SDK/completion.zsh.inc"; fi

#-------------------------------------
# load local settings
#-------------------------------------
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"

#-------------------------------------
# completion
#-------------------------------------

if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi

if [ $commands[helm] ]; then
  source <(helm completion zsh)
fi

if [ $commands[stern] ]; then
  source <(stern --completion=zsh)
fi
