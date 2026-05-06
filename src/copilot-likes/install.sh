#!/usr/bin/env bash
set -e

echo "📦 Installing Copilot-Likes toolset..."

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ripgrep \
  fd-find \
  fzf \
  jq \
  tree \
  bat \
  git-delta \
  direnv \
  unzip \
  curl

# ---- Fix Ubuntu naming quirks ----
ln -sf /usr/bin/fdfind /usr/local/bin/fd || true
ln -sf /usr/bin/batcat /usr/local/bin/bat || true

# ---- Nice defaults for dev UX ----

echo "⚙️ Configuring git + shell niceties..."

# Better git diff
git config --system core.pager "delta" || true

# Install eza (modern ls replacement)
if ! command -v eza >/dev/null 2>&1; then
    echo "📦 Installing eza..."
    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64)  EZA_ARCH="x86_64-unknown-linux-gnu" ;;
        aarch64) EZA_ARCH="aarch64-unknown-linux-gnu" ;;
        armv7l)  EZA_ARCH="armv7-unknown-linux-gnueabihf" ;;
        *)       echo "Unsupported architecture: ${ARCH}"; exit 1 ;;
    esac
    mkdir -p /tmp/eza
    cd /tmp/eza
    curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.zip" -o eza.zip
    unzip eza.zip
    install -m 755 eza /usr/local/bin/eza
    cd /
    rm -rf /tmp/eza
fi

# Enable direnv and add useful aliases globally.
# Writing to a dedicated file (rather than appending) makes this idempotent:
# re-running the script simply overwrites the file with the same content.
cat > /etc/profile.d/copilot-likes.sh << 'EOF'
# Copilot-Likes: direnv hook
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# Copilot-friendly aliases
alias ll="eza -lah --git"
alias ls="eza --icons"
alias cat="bat"
alias grep="rg"
EOF

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ Copilot-Likes installed!"