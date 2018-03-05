#power-line
#source "$HOME/.anyenv/envs/pyenv/versions/3.5.2/lib/python3.5/site-packages/powerline/bindings/zsh/powerline.zsh"
#--------------------------------------
# プラグイン
#--------------------------------------
source ~/.zplug/init.zsh


## zplug
zplug "zplug/zplug"
## 拡張
zplug "mollifier/anyframe"
zplug "Tarrasch/zsh-functional"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "b4b4r07/zsh-vimode-visual", defer:3

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
    PROMPT='%(?.%F{green}.%F{red})$%f '
    PURE_GIT_DELAY_DIRTY_CHECK=1000
  }
  "
  
# 通知 
# メモリ食うので一旦OFF
#zplug "marzocchi/zsh-notify"
#export SYS_NOTIFIER="usr/local/bin/terminal-notifier"
# cd 系
zplug "knu/z"
zplug "Tarrasch/zsh-bd"
# gitルートへcd
zplug "mollifier/cd-gitroot"
# githubをブラウザで開く
zplug "peterhurford/git-it-on.zsh"

zplug "ascii-soup/zsh-url-highlighter"

# 補完
zplug "zsh-users/zsh-completions"

# 絵文字の補完
zplug "stedolan/jq", from:gh-r, as:command

# git br用
zplug "jhawthorn/fzy", \
    as:command, \
    hook-build:'make'
zplug "b4b4r07/git-br", \
    as:command, \
    use:'git-br'
# open git hub
zplug "paulirish/git-open", as:command

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

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
# -------------------------------------
# zshのオプション
# -------------------------------------
# ファイル補完の高速化
__git_files() { _files }
# cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# 補完
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
export PATH=$PATH:$GOPATH/bin
export GOENVTARGET=$HOME/.goenvtarget
export PATH=$GOENVTARGET:$PATH

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
alias tgc='git branch | peco | xargs tig'

# vim
export EDITOR=/Applications/MacVim.app/Contents/MacOS/Vim
alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'

alias zconf="vim ~/.zshrc"
alias viconf="vim ~/.vimrc"
alias sshconf="vim ~/.ssh/config"
alias tmux="TERM=screen-256color-bce tmux"

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

alias cdserver="cd /Library/WebServer"
alias cdwork="cd ~/Projects/github.com/valbeat"

# 拡張子列挙
alias ext-list="find . -type f -not -iwholename '*/.git/*' | sed -e 's/^.*\///' | grep '\.' | sed -e 's/^.*\.//' | sort | uniq -c | sort -nr"
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

# mvimで開くときに新しいタブで開く
case ${OSTYPE} in
darwin*) # Mac OS X
  function macvim () {
    if [ -d /Applications/MacVim.app ]
    then
      [ ! -f $1 ] && touch $1
      open -a MacVim $1
    else
      mvim $1
    fi
  }
  ;;
esac

# has_command returns true if $1 as a shell command exists
has.command() {
    (( $+commands[${1:?too few argument}] ))
    return $status
}

# has_command returns true if $1 as a shell function exists
has.function() {
    (( $+functions[${1:?too few argument}] ))
    return $status
}

# has_command returns true if $1 as a builtin command exists
has.builtin() {
    (( $+builtins[${1:?too few argument}] ))
    return $status
}

# has_command returns true if $1 as an alias exists
has.alias() {
    (( $+aliases[${1:?too few argument}] ))
    return $status
}

# has_command returns true if $1 as an alias exists
has.galias() {
    (( $+galiases[${1:?too few argument}] ))
    return $status
}

# has returns true if $1 exists
has() {
    has.function "$1" || \
        has.command "$1" || \
        has.builtin "$1" || \
        has.alias "$1" || \
        has.galias "$1"

    return $status
}

# リンゴマーク出すための関数
function toon {
  echo -n ""
}

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
#-------------------------------------
# iTerm2
#-------------------------------------
tab-color() {
    echo -ne "\033]6;1;bg;red;brightness;$1\a"
    echo -ne "\033]6;1;bg;green;brightness;$2\a"
    echo -ne "\033]6;1;bg;blue;brightness;$3\a"
}
tab-reset() {
    echo -ne "\033]6;1;bg;*;default\a"
}

# Change the color of the tab when using SSH
# reset the color after the connection closes
color-ssh() {
    if [[ -n "$ITERM_SESSION_ID" ]]; then
        trap "tab-reset" INT EXIT
        if [[ "$*" =~ "builder" ]]; then
            tab-color 255 0 0
        else
            tab-color 0 255 0
        fi
    fi
    ssh $*
}
compdef _ssh color-ssh=ssh

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
export PATH="$PATH:/Users/t-kajikawa/Library/Android/sdk"
export PATH="$PATH:/Users/t-kajikawa/Library/Android/sdk/platform-tools"


#-------------------------------------
# peco
#-------------------------------------

# exp: ls | p cd
p() { peco | while read LINE; do $@ $LINE; done }

# Ctrl + ] => ghq
function peco-src () {
  local selected_dir=$(ghq list -p | peco --prompt "REPOSITORY >" --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src
