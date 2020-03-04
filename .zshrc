#--------------------------------------
# Auto compile
#--------------------------------------
if [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
   zcompile ~/.zshrc
fi 
#--------------------------------------
# プラグイン
#--------------------------------------

## zplug init
case ${OSTYPE} in
  darwin*)
    export ZPLUG_HOME=/usr/local/opt/zplug
    ;;
  linux*)
    export ZPLUG_HOME=/home/linuxbrew/.linuxbrew/opt/zplug
    ;;
esac
source $ZPLUG_HOME/init.zsh

# 補完
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions", \
  hook-load:"{
    bindkey '^ ' autosuggest-accept
  }
  "

# テーマ
## pure
zplug "mafredri/zsh-async"
zplug "sindresorhus/pure", defer:2, \
  hook-load:"{
    PURE_GIT_DELAY_DIRTY_CHECK=1000
  }
  "
## シンタックスハイライト(compinit後に読み込み)
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# 関数
zplug "mollifier/cd-gitroot"

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  zplug install
fi

# Then, source plugins and add commands to $PATH
zplug load --verbose

# -------------------------------------
# 環境変数
# -------------------------------------
# SSHで接続した先で日本語が使えるようにする
export LANG=ja_JP.UTF-8

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# エディタ
export EDITOR='vim'
# ページャ
export PAGER=vimpager
export MANPAGER=vimpager

# ncurses
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ncurses/lib"
export CPPFLAGS="-I/usr/local/opt/ncurses/include"
export PKG_CONFIG_PATH="/usr/local/opt/ncurses/lib/pkgconfig"

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

# linuxbrew
case ${OSTYPE} in
  linux*)
    export PATH="/home/linuxbrew/.linuxbrew/bin/:$PATH"
    ;;
esac

# -------------------------------------
# prompt
# -------------------------------------
#source "$HOME/bin/zsh-gkeadm-prompt"

# -------------------------------------
# zshのオプション
# -------------------------------------

# cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

## 補完候補をキャッシュする。
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
## 詳細な情報を使わない
zstyle ':completion:*' verbose no
#ファイル補完候補に色を付ける
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# 補完開始時に絞り込み開始
zstyle ':completion:*' menu select interactive

#LS_COLORSを設定しておく
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# Use fzf instead of using zstyle completion
#zstyle ':completion:*:(processes|jobs)' menu yes select=2

# 入力された文字そのままで補完
# マッチするものがなければ，小文字を大文字に変えつつ補完
# マッチするものがなければ，大文字を小文字に変えるルールを追加（`+'）して補完
#⁠a-zをそれぞれ対応するA-Zに置き換えて，A-Zもそれぞれ対応するa-zに置き換えて補完してみるのと同時に，右側にハイフンかアンダースコアかピリオドが来る場所には * を補ったかのように補完
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
# 中間ファイルを補完しない
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?~' '*\#'
# カレントディレクトリに候補がない場合のみ cdpath 上のディレクトリを候補に出す
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
# 親ディレクトリからカレントディレクトを表示させないようにする (例: cd ../<TAB>):
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# sudoの際にコマンドを探す
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

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

# cd ls
# タブによるファイルの順番切り替えをしない
unsetopt auto_menu
# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd
# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd
# pushdから重複を削除
setopt pushd_ignore_dups

# cdrコマンドで履歴にないディレクトリにも移動可能に
zstyle ":chpwd:*" recent-dirs-default true
#あらかじめcdpathを適当に設定しておく
cdpath=(~)

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

# キー入力待ちを早く (default:40)
KEYTIMEOUT=1

# -------------------------------------
# パス
# -------------------------------------
PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
PATH="$PATH:/usr/local/git/bin"
PATH="/usr/local/opt/openssl/bin:$PATH"
PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# go
export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME
export GOENVTARGET=$HOME/.goenvtarget
export GO15VENDOREXPERIMENT=1
export GO111MODULE=on

PATH=$PATH:$GOPATH/bin
PATH=$GOENVTARGET:$PATH

# dotnet
PATH=$PATH:$HOME/dotnet

if [ type brew >/dev/null 2>&1 ]; then
  # coreutilsのシンボリックリンク
  PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
fi

PATH="$HOME/.yarn/bin:$PATH"

# 重複する要素を自動的に削除
typeset -U path cdpath fpath manpath

path=(
    $HOME/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    $path
)

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

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

# expand global aliases by space
# http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
globalias() {
  if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
    zle _expand_alias
    # zle expand-word
  fi
  zle self-insert
}

zle -N globalias

bindkey " " globalias

##############################
# common
##############################

alias -g A='| awk'
# count
alias -g C='| wc -l'
alias -g G='| grep --color=auto'
alias -g H='| head'
alias -g T='| tail'
alias -g L='| less -R'
alias -g X='| xargs'

alias c='pbcopy'
alias d='docker'
alias h='tldr' 
alias y='yarn'

# Copy current directory path
alias pwdc='pwd | tr -d "\n" | pbcopy'

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

# interactive rename files
alias vrename=massren

alias ezrc='vim ~/.zshrc'

alias tmux="TERM=screen-256color-bce tmux"


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

##############################
# docker
##############################
alias fig=docker-compose
# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }
# Get container process
alias dps="docker ps -a"

# Execute interactive container, e.g., $dex base /bin/bash
alias deit="docker exec -i -t"

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
# Remove all containers (only stopped)
_docker_rm_all() { docker rm $(docker ps -a -q); }
alias drm=_docker_rm_all
# Remove all images
_docker_rm_all_images() { docker rmi $(docker images -q); }
alias drmi=_docker_rm_all_images

_fzf_docker_tag() {
  local selected_id=`docker images | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $3}'`
  if [ "$selected_id" != "" ]; then
    print -z "docker tag ${selected_id} "
  fi
}
alias fdtag=_fzf_docker_tag

# Stop select container
_fzf_docker_stop() {
  local line=`docker ps --format "table {{.id}}\t{{.names}}\t{{.status}}"| fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ "$line" != "" ]; then
    id=`echo $line | awk '{print $1}'`
    docker stop ${id}
  fi
}
alias fdstop=_fzf_docker_stop

# fzf docker run
_fzf_docker_run() {
  local image=`docker images | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}'`
  if [ "$image" != "" ]; then
    docker run ${image}
  fi
}
alias fdrun=_fzf_docker_run

# fzf docker exec -it
_fzf_docker_exec_it() { 
  local line=`docker ps --format "table {{.Names}}" | fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ "$line" != "" ]; then
    print -z "docker exec -it ${line}"
  fi
}
alias fdeit=_fzf_docker_exec_it

alias lzd=lazydocker

##############################
# kubectl
##############################
alias k=kubectl
alias kx=kubectx
alias kn=kubens

alias kgp='kubectl get pod'
alias kgn='kubectl get node'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdn='kubectl describe node'
alias keit='kubectl exec -it'

alias wkgp='watch -n1 kubectl get pod'
alias wkgn='watch -n1 kubectl get node'

function _fzf_kubectl_describe_node() {
  local node=$(kubectl get node | fzf --header-lines=1 -m | awk '{print $1}')
  if [[ -n $node ]]; then
    print -z "kubectl describe node ${node} "
  fi
}

alias fkdn=_fzf_kubectl_describe_node

function _fzf_kubectl_describe_pod() {
  local selection=`kubectl get pods --all-namespaces | fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ $selection == "" ]; then
    return 0
  fi

  local namespace=`echo $selection | awk '{ print $1 }'`
  local pod=`echo $selection | awk '{ print $2 }'`
  if [[ -n $pod ]]; then
    print -z "kubectl describe pod ${pod} "
  fi
}

alias fkdp=_fzf_kubectl_describe_pod

function _fzf_kubectl_describe() {
  local selection=$(kubectl get all | grep -v '^NAME' | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}')
  if [[ -n $pod ]]; then
    print -z "kubectl describe pod ${selection} "
  fi
}

alias fkd=_fzf_kubectl_describe

function _fzf_kubectl_exec_it() {
  local selection=`kubectl get pods --all-namespaces | fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ $selection == "" ]; then
    return 0
  fi

  local namespace=`echo $selection | awk '{ print $1 }'`
  local pod=`echo $selection | awk '{ print $2 }'`
  local containers=`kubectl -n $namespace get pods $pod -o jsonpath='{range .spec.containers[*]}{@.name}{"\n"}{end}'`
  if [ $containers == "" ]; then
    return 0
  fi
  
  local container_count=$((`echo "$containers" | wc -l`))
  if [ ${container_count} -gt "1" ]; then
    container=`echo "$containers" | fzf --header "Select a container..."`
  else
    container=$containers
  fi

  if [ $containers == "" ]; then
    return 0
  fi

  print -z "kubectl exec -n ${namespace} -it ${pod} -c ${container} "
}
alias fkeit=_fzf_kubectl_exec_it

# ref: https://gist.github.com/jondlm/35cbf0363eb925e2eff6ff86c0a30992
function _fzf_kubectl_exec_it_sh() {
  local selection=`kubectl get pods --all-namespaces | fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ $selection == "" ]; then
    return 0
  fi
  local namespace=`echo $selection | awk '{ print $1 }'`
  local pod=`echo $selection | awk '{ print $2 }'`
  local containers=`kubectl -n $namespace get pods $pod -o jsonpath='{range .spec.containers[*]}{@.name}{"\n"}{end}'`
  if [ $containers == "" ]; then
    return 0
  fi
  local container_count=$((`echo "$containers" | wc -l`))
  
  if [ ${container_count} -gt "1" ]; then
    container=`echo "$containers" | fzf --header "Select a container..."`
  else
    container=$containers
  fi
  
  kubectl exec -n $namespace -it $pod -c $container ash ||\
  kubectl exec -n $namespace -it $pod -c $container bash ||\
  kubectl exec -n $namespace -it $pod -c $container sh
}

alias fkeitsh=_fzf_kubectl_exec_it_sh

function _fzf_kubectl_logs() {
  local selection=`kubectl get pods --all-namespaces -o wide | fzf --header-lines=1 --query="$*" --select-1 -e `
  if [ $selection == "" ]; then
    return 0
  fi
  local namespace=`echo $selection | awk '{ print $1 }'`
  local pod=`echo $selection | awk '{ print $2 }'`
  local containers=`kubectl -n $namespace get pods $pod -o jsonpath='{range .spec.containers[*]}{@.name}{"\n"}{end}'`
  local container_count=$((`echo "$containers" | wc -l`))

  local container
  if [ ${container_count} -gt "1" ]; then
    container=`echo "$containers" | fzf --header "Select a container..."`
  else
    container=$containers
  fi

  if [ $container == "" ]; then
    return 0
  fi

  print -z "kubectl logs -n ${namespace} ${pod} -c ${container}"
}
alias fkl=_fzf_kubectl_logs


##############################
# gcloud
##############################
function _gcloud_set_credential() {
  local selection=`gcloud container clusters list | fzf --header-lines=1 --query="$*" --select-1 -e `
  local cluster=`echo $selection | awk '{print $1}'`
  local zone=`echo $selection | awk '{print $2}'`
  if [[ -n $selection ]]; then
    gcloud container clusters get-credentials $cluster --zone $zone
    return $?
  fi
}
alias gsc=_gcloud_set_credential

function _gcloud_set_account() {
  local account=$(gcloud auth list --format="value(account)" | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}')
  if [[ -n $account ]]; then
    gcloud config set account $account
    return $?
  fi
}
alias gsa=_gcloud_set_account

function _fzf_gce_ssh() {
  local select=$(gcloud compute instances list --filter="STATUS:RUNNING" | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1,$2}')
  local host=$(echo $select | awk '{print $1}')
  local zone=$(echo $select | awk '{print $2}')
  gcloud compute ssh ${host} --internal-ip --zone ${zone}
}
alias fgssh=_fzf_gce_ssh

function _fzf_kubectl_get_pod_with_node() {
  local node=$(kubectl get nodes -o wide | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}')
  print -z  "kubectl get pods -o wide --all-namespaces | awk 'NR == 1 || /\\${node}/'" 
}
alias fkgpn=_fzf_kubectl_get_pod_with_node

function _open_gcp_console() {
  local proj=$(gcloud projects list | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}')
  if [[ -n $proj ]]; then
    open https://console.cloud.google.com/home/dashboard?project=${proj}
    return $?
  fi
}
alias opengcp=_open_gcp_console


function _gcloud_set_project() {
  local proj=$(gcloud projects list | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}')
  if [[ -n $proj ]]; then
    gcloud config set project $proj
    return $?
  fi
}
alias gsp=_gcloud_set_project

function _gcloud_activate_configuration() {
  local config=$(gcloud config configurations list | fzf --header-lines=1 --query="$*" --select-1 -e | awk '{print $1}' )
  if [[ -n $config ]]; then
    gcloud config configurations activate $config
    return $?
  fi
}
alias gac=_gcloud_activate_configuration


##############################
# alias for ruby
##############################
alias be=bundle exec

##############################
# alias for misc
##############################

# git
alias g='git'
alias tg='tig'
alias tgc='git branch | fzf | xargs tig --stdin'

# iterm
alias ssh="ssh-iterm-profile-setting"

# memo edit with grep
function _memo_edit_grep {

  if [ $commands[mdcat] ]; then
    local selection=$(memo grep $1 | fzf --preview 'echo {} | awk -F":" "{print \$1}" | xargs -I% echo \"%\" | xargs mdcat')
  else
    local selection=$(memo grep $1 | fzf --preview 'echo {} | awk -F":" "{print \$1}" | xargs -I% echo \"%\" | xargs cat')
  fi

  if [[ -n $selection ]]; then
    local file=$(echo ${selection} | awk -F":" '{print $1}')
    local num=$(echo ${selection} | awk -F":" '{print $2}')
    vim +${num} ${file}
    return $?
  fi
}
alias memoeg=_memo_edit_grep

function _memo_rename {
  local selection=$(memo list --fullpath | fzf --preview 'echo {} | xargs mdcat')
  if [[ -n $selection ]]; then
    local dir=$(dirname $selection)
    local current=$(basename $selection)
    local date=$(echo ${current} | sed -n -e 's/\(^[0-9]\{4\}-[0-9]\{1,2\}-[0-9]\{1,2\}\).*$/\1/p')

    cd $dir 1>/dev/null

    echo "Rename ${current} to ?"
    read input
    if [[ -n $date  ]]; then
      new="${date}-${input}.md"
    else
      new="${input}.md"
    fi
    mv ${current} ${new}

    return $?
  fi
}
alias memor=_memo_rename

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
  local host="$(egrep -i '^Host\s+.+' $HOME/.ssh/config $(find $HOME/.ssh/conf.d -type f 2>/dev/null) | egrep -v '[*?]' | awk '{print $2}'| sort | fzf --select-1 --prompt "HOST >" --query "$LBUFFER")"
  if [ "$host" == "" ]; then
    return
  fi
  ssh -A $host
}
alias fssh=_fzf_ssh


#-------------------------------------
# iTerm2
#-------------------------------------

# shell integration
# https://www.iterm2.com/documentation-shell-integration.html
# TODO: アップデートがあった際はインストールし直す
if [[ ! -f ~/.iterm2_shell_integration.zsh ]]; then
  curl -L https://iterm2.com/shell_integration/zsh \
  -o ~/.iterm2_shell_integration.zsh
fi
#source ~/.iterm2_shell_integration.zsh

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

#-------------------------------------
# fzf
#-------------------------------------
# exp: ls | p cd
p() { fzf | while read LINE; do $@ $LINE; done }

# Ctrl + ] => ghq
function fzf-src () {
  local project=$(ghq list | fzf -e --prompt "REPO >" --query "$LBUFFER")
  if [ "$project" == "" ]; then
    return 0
  fi
  cd $(ghq root)/${project}
  zle clear-screen
}
zle -N fzf-src
bindkey '^]' fzf-src

function fzf-src-remote () {
  local selected=$(ghq list | fzf -e --prompt "REPO >" --query "$LBUFFER")
  if [ "${selected}" == "" ]; then
    return 0
  fi

  if [[ "${selected}" =~ ^github.com.*  ]]; then
    local repo=$(echo ${selected} | rev | cut -d "/" -f -2 | rev)
    BUFFER="hub browse ${repo}"
    zle accept-line
  fi
  # for others
  BUFFER="open https://${selected}"
  zle accept-line

  zle clear-screen
}
zle -N fzf-src-remote
bindkey '^p' fzf-src-remote

#-------------------------------------
# google cloud sdk
#-------------------------------------
## Set path for GoogleCloudSDK
export GCLOUD_SDK="$HOME/google-cloud-sdk"
PATH="$PATH:$GCLOUD_SDK/bin"

## Set path for App Engine SDK for GO
export APPENGINE_SDK="$GCLOUD_SDK/platform/google_appengine"
PATH="$PATH:$APPENGINE_SDK"

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

if [ $commands[aws] ]; then
  PATH=$HOME/.anyenv/envs/pyenv/shims/aws_completer:$PATH
fi

export PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
