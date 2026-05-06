#!/usr/bin/env bash
set -e

echo "📦 Installing Copilot-Likes toolset..."

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  ripgrep \
  fd-find \
  fzf \
  jq \
  tree \
  bat \
  git-delta \
  direnv

# ---- Fix Ubuntu naming quirks ----
ln -sf /usr/bin/fdfind /usr/local/bin/fd || true
ln -sf /usr/bin/batcat /usr/local/bin/bat || true

# ---- Nice defaults for dev UX ----

echo "⚙️ Configuring git + shell niceties..."

# Better git diff
git config --system core.pager "delta" || true

# Enable direnv automatically if available
if command -v direnv >/dev/null 2>&1; then
    echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc
fi

# Add useful aliases globally
cat << 'EOF' >> /etc/bash.bashrc

# Copilot-friendly aliases
alias ll="eza -lah --git"
alias ls="eza --icons"
alias cat="bat"
alias grep="rg"

EOF

# Install eza (modern ls replacement)
if ! command -v eza >/dev/null 2>&1; then
    echo "📦 Installing eza..."
    apt-get install -y unzip
    mkdir -p /tmp/eza && cd /tmp/eza
    curl -L https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.zip -o eza.zip
    unzip eza.zip
    install -m 755 eza /usr/local/bin/eza
    cd /
    rm -rf /tmp/eza
fi

echo "✅ Copilot-Likes installed!"