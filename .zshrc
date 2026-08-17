# ============================================================
# 環境判定
# ============================================================
# Mac / WSL でパスもコマンドも違うため、先にフラグを立てて以降で分岐する
IS_MAC=0
IS_WSL=0

case "$OSTYPE" in
  darwin*) IS_MAC=1 ;;
esac

if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
  IS_WSL=1
fi

# ============================================================
# パッケージマネージャ / バージョン管理
# ============================================================
# brew は最初に評価する。mise を含む大半の CLI が brew 配下にあるため
if [ "$IS_MAC" = 1 ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="/opt/homebrew/opt/curl/bin:$PATH"
fi

if [ "$IS_WSL" = 1 ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if command -v mise > /dev/null; then
  eval "$(mise activate zsh)"
fi

# ============================================================
# PATH
# ============================================================
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# deno: 新しいインストーラは env を吐くので、あればそれを使う
export DENO_INSTALL="$HOME/.deno"

if [ -s "$DENO_INSTALL/env" ]; then
  . "$DENO_INSTALL/env"
else
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if [ -s "$BUN_INSTALL/_bun" ]; then
  source "$BUN_INSTALL/_bun"
fi

if [ "$IS_WSL" = 1 ]; then
  export PATH="$PATH:$HOME/jpm/bin"
fi

export EDITOR=nvim

# ============================================================
# プロンプト (vcs_info)
# ============================================================
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{#00d7ff}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

PROMPT='
%F{green}(%~) %F %F{cyan}$vcs_info_msg_0_%f
%# '

# ============================================================
# 補完
# ============================================================
# brew 配下の補完定義を fpath に足してから compinit する
if [ -d "$(brew --prefix 2> /dev/null)/share/zsh/site-functions" ]; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

autoload -Uz compinit
compinit

# ============================================================
# オプション / 履歴
# ============================================================
setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_cd
setopt hist_ignore_dups
setopt share_history
setopt inc_append_history

export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

# ============================================================
# キーバインド
# ============================================================
bindkey '^U' push-line

# ghq のリポジトリを fzf で選んで移動 (Ctrl-g)
# BUFFER 経由で実行するので、移動先が履歴に cd として残る
if command -v ghq > /dev/null && command -v fzf > /dev/null; then
  ghq-fzf() {
    local dir
    dir=$(ghq list --full-path | fzf --height=40% --reverse --prompt='ghq> ')

    if [ -z "$dir" ]; then
      zle reset-prompt
      return
    fi

    BUFFER="cd ${(q)dir}"
    zle accept-line
  }

  zle -N ghq-fzf
  bindkey '^G' ghq-fzf
fi

# ============================================================
# alias (共通)
# ============================================================
# vimのundo履歴をクリーンアップ
alias cleanup_undo='find ~/.vim/undodir -type f -size +10M -exec rm {} \;'

## テスト用のneovim起動
alias nvim-test='nvim -u ~/nvim-test/init.lua'
alias nvim='NVIM_APPNAME=nvim-pack nvim'
alias snvim='NVIM_APPNAME=nvim-sub nvim'
alias pnvim='nvim'

# ls: exa があれば使い、無ければ coreutils の ls にフォールバックする
if command -v exa > /dev/null; then
  alias ll="exa -l -h -@ -mU --icons --git --time-style=long-iso --color=automatic --group-directories-first"
  alias l="ll -aa"
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

alias grep='grep --color=auto'
alias du='du -h'
alias .z='nvim ~/.zshrc'
alias .n='cd ~/.config/nvim && nvim .'
alias cdd='cd ~/dotfiles'

# git alias
alias gc='git commit -m'
alias gs='git status'
alias gita="git commit --allow-empty -m"
# dev/main/master とカレント以外で、マージ済みのブランチを一覧
alias gbm='git branch --merged | grep -v "^\*" | grep -vE "^\s*(dev|main|master)$"'
# 上の一覧をまとめて削除 (-d なので未マージは保護される)
alias gbmd='git branch --merged | grep -v "^\*" | grep -vE "^\s*(dev|main|master)$" | xargs -r git branch -d'

# claude alias
alias ccc='claude -c --dangerously-skip-permissions'
alias ccd='claude --dangerously-skip-permissions'
alias ccn='CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude -c --dangerously-skip-permissions'
alias wclaude='CLAUDE_CONFIG_DIR=~/.claude-work claude'

# ============================================================
# alias (Mac 固有)
# ============================================================
if [ "$IS_MAC" = 1 ]; then
  alias cdf='cd ~/fe'
  alias cdr='cd ~/dev/rust'
  alias cdv='cd ~/test-vue/vue-application'
  alias cda='cd ~/atc/rust/root'
  alias cdw='cd ~/.config/wezterm'
fi

# ============================================================
# WSL 固有
# ============================================================
if [ "$IS_WSL" = 1 ]; then
  alias cddes='cd ~/dev/ytt-links-design-system'
  alias cda='cd ~/dev/atomhanreiai'
  alias cdn='cd ~/.config/nvim-pack/'
  alias cdl='cd ~/dev/ckdcorsap/liferay'
  alias cdk='cd ~/memo/hp-reborn/docs/記事動的化'
  alias ii='explorer.exe'

  # 非テキストファイルを less で読めるようにする (Debian の lesspipe)
  if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
  fi

  # ls の色定義 (LS_COLORS)
  if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
  fi

  # WSLg の Wayland ソケットを指す (デフォルトの $XDG_RUNTIME_DIR/wayland-0 が無い環境向け)
  # nvim の wl-paste や、シェルからの wl-copy/wl-paste をこれで動かす
  if [ -S /mnt/wslg/runtime-dir/wayland-0 ] && [ ! -S "${XDG_RUNTIME_DIR%/}/wayland-0" ]; then
    export WAYLAND_DISPLAY=/mnt/wslg/runtime-dir/wayland-0
  fi

  # ファイル/URL を Windows 側 Chrome で開く (~/.local/bin/wslopen)
  export BROWSER="$HOME/.local/bin/wslopen"

  # Shift+Win+S のキャプチャは image/bmp でしか共有されず Claude Code が拾えない
  # PNG に変換してクリップボードへ戻す (Claude Code のプロンプトで `! clip2png` -> Ctrl+V)
  clip2png() {
    local tmp
    tmp="$(mktemp --suffix=.png)"

    if ! wl-paste -t image/bmp 2>/dev/null | python3 -c "
import sys, io
from PIL import Image
Image.open(io.BytesIO(sys.stdin.buffer.read())).save(sys.argv[1])
" "$tmp" 2>/dev/null; then
      echo 'clip2png: クリップボードに画像がありません' >&2
      rm -f "$tmp"
      return 1
    fi

    # wl-copy は内容を配信し続ける常駐プロセスを起こす。setsid で親シェルから
    # 切り離さないと、呼び出し元のシェル終了時に道連れで死んで貼れなくなる。
    # 出力を捨てるのはパイプを掴んだままにしてハングさせないため
    setsid wl-copy -t image/png < "$tmp" > /dev/null 2>&1
    sleep 0.3
    rm -f "$tmp"
  }
fi

# ============================================================
# 関数
# ============================================================
function gitmain() {
    git config --global user.name "yahomi-dev"
    git config --global user.email "yahomi.dev@gmail.com"
}
