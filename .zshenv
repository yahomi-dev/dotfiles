# Ubuntu の /etc/zsh/zshrc は ~/.zshrc より先に compinit を呼ぶ。
# その時点では fpath の整理が済んでおらず、Docker Desktop 停止中の壊れたリンクを踏んで警告が出る。
# 補完の初期化は ~/.zshrc 側に一本化するため、グローバル側はスキップする。
skip_global_compinit=1
