# git-config
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

## alias
# vimのundo履歴をクリーンアップ 
alias cleanup_undo='find ~/.vim/undodir -type f -size +10M -exec rm {} \;'

alias ll="exa -l -h -@ -mU --icons --git --time-style=long-iso --color=automatic --group-directories-first"
alias l="ll -aa"

alias du='du -h'
alias .z='nvim ~/.zshrc'
alias .n='cd ~/.config/nvim && nvim .'
alias cdd='cd ~/dotfiles'
alias cdf='cd ~/fe'
alias cdr='cd ~/dev/rust'
alias cdv='cd ~/test-vue/vue-application'
alias cda='cd ~/atc/rust/root'
alias cdw='cd ~/.config/wezterm'

# git alias
alias gita="git commit --allow-empty -m"

setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_cd
setopt hist_ignore_dups
setopt share_history
setopt inc_append_history

export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

function gitmain() {
    git config --global user.name "yahomi-dev"
    git config --global user.email "yahomi.dev@gmail.com"
}
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export PATH=$HOME/bin:$PATH

if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
