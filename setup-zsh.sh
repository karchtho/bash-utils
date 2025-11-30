#!/bin/bash

# =============================================================================
# Setup ZSH complet : Oh My Zsh + Powerlevel10k + Plugins + Alias
# Usage: chmod +x setup-zsh.sh && ./setup-zsh.sh
# =============================================================================

set -e

echo "🚀 Installation de ZSH + Oh My Zsh + Powerlevel10k"
echo "=================================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Installation des paquets
echo -e "${BLUE}[1/6]${NC} Installation de zsh, curl, git..."
sudo apt update
sudo apt install -y zsh curl git

# 2. Installation Oh My Zsh (non-interactive)
echo -e "${BLUE}[2/6]${NC} Installation d'Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${YELLOW}Oh My Zsh déjà installé, skip...${NC}"
fi

# 3. Installation Powerlevel10k
echo -e "${BLUE}[3/6]${NC} Installation de Powerlevel10k..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo -e "${YELLOW}Powerlevel10k déjà installé, skip...${NC}"
fi

# 4. Installation des plugins
echo -e "${BLUE}[4/6]${NC} Installation des plugins..."

# zsh-autosuggestions
AUTOSUGG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ ! -d "$AUTOSUGG_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGG_DIR"
else
    echo -e "${YELLOW}zsh-autosuggestions déjà installé${NC}"
fi

# zsh-syntax-highlighting
SYNTAX_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [ ! -d "$SYNTAX_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_DIR"
else
    echo -e "${YELLOW}zsh-syntax-highlighting déjà installé${NC}"
fi

# 5. Configuration du .zshrc
echo -e "${BLUE}[5/6]${NC} Configuration de .zshrc..."

# Backup
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

# Appliquer le thème Powerlevel10k
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

# Activer les plugins
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo history docker npm)/' "$HOME/.zshrc"

# Ajouter les alias et config
cat >> "$HOME/.zshrc" << 'EOF'

# =============================================================================
# ALIAS PERSONNALISÉS
# =============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lt='ls -ltrh'

# Git
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias glog='git log --oneline --graph --decorate -15'
alias gst='git stash'
alias gstp='git stash pop'
alias grh='git reset --hard'

# Dev - Python
alias python='python3'
alias pip='pip3'
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'
alias serve='python3 -m http.server 8000'

# Dev - Node/NPM
alias ni='npm install'
alias nid='npm install --save-dev'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrs='npm run start'
alias nrt='npm run test'

# Système
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias cls='clear'
alias c='clear'
alias ports='sudo netstat -tulanp'
alias meminfo='free -h'
alias diskinfo='df -h'
alias cpuinfo='lscpu'
alias myip='curl -s ifconfig.me && echo'
alias weather='curl -s wttr.in/?format=3'

# Fichiers
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias h='history | tail -30'
alias hg='history | grep'

# Raccourcis projets (personnalise ces chemins)
alias dev='cd ~/dev'
alias proj='cd ~/projects'
alias dl='cd ~/Downloads'
alias doc='cd ~/Documents'

# Raccourcis éditeurs
alias zshrc='${EDITOR:-nano} ~/.zshrc'
alias reload='source ~/.zshrc && echo "✅ .zshrc rechargé"'

# =============================================================================
# CONFIGURATION HISTORIQUE
# =============================================================================
export HISTSIZE=50000
export SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# =============================================================================
# DIVERS
# =============================================================================
# Correction automatique des commandes
setopt CORRECT

# Pas de beep
setopt NO_BEEP

# CD sans taper cd
setopt AUTO_CD

# PATH local
export PATH="$HOME/.local/bin:$PATH"

EOF

# 6. Changer le shell par défaut
echo -e "${BLUE}[6/6]${NC} Configuration de zsh comme shell par défaut..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Installation terminée !${NC}"
echo ""
echo "📋 Ce qui a été installé :"
echo "   • Zsh (shell par défaut)"
echo "   • Oh My Zsh"
echo "   • Powerlevel10k (thème)"
echo "   • zsh-autosuggestions"
echo "   • zsh-syntax-highlighting"
echo "   • Alias utiles (git, dev, système...)"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT :${NC}"
echo "   1. Redémarre ton terminal ou tape : exec zsh"
echo "   2. L'assistant Powerlevel10k va se lancer automatiquement"
echo "   3. Installe une Nerd Font pour les icônes :"
echo "      https://github.com/romkatv/powerlevel10k#fonts"
echo ""
echo "📝 Fichiers :"
echo "   • Config : ~/.zshrc"
echo "   • Backup : ~/.zshrc.backup.*"
echo "   • Éditer : zshrc (alias)"
echo "   • Recharger : reload (alias)"
echo ""
echo -e "${GREEN}🎉 Tape 'exec zsh' pour commencer !${NC}"
