# Portable command aliases. Machine/work-specific aliases belong in local.zsh.
alias vim='nvim'
alias vi='nvim'
alias refresh='exec zsh'
alias reload='source ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias path="print -l \${(s.:.)PATH}"
alias json="jq '.'"
alias py='python3'

# env/cli specific aliases 
alias kibao="~/./kibao.sh"

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -al --grid --no-user --color=always --long --git --no-filesize --icons=auto --no-time --no-permissions'
  alias l='eza -al --icons=auto'
  alias lt='eza --tree --level=1 --icons=auto'
  alias tree='eza --tree --icons=auto'
else
  alias l='ls -al'
fi

command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v opencode >/dev/null 2>&1 && alias oc='opencode'

alias gs='git switch'
alias gsn='git switch -c'
alias gss='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias amend='git commit --amend --no-edit'
alias gr='git pull --rebase'
alias gp='git push'
alias gb='git branch'
alias gl='git log --oneline --decorate --graph'
alias gdf='git diff'
alias gdfs='git diff --shortstat'
alias grl='git remote get-url --all origin'

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
