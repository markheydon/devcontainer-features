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

# Install eza (modern ls replacement) — version and checksums from upstream release assets
EZA_VERSION="0.23.5"
if ! command -v eza >/dev/null 2>&1; then
    echo "📦 Installing eza v${EZA_VERSION}..."
    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64)
            EZA_ARCH="x86_64-unknown-linux-gnu"
            EZA_SHA256="f3bfd758743699e6c8ac38c6c65cf4aadc8f02d046a0af5a4c4b28e59e305a5a"
            ;;
        aarch64)
            EZA_ARCH="aarch64-unknown-linux-gnu"
            EZA_SHA256="0f00cb699085984bb6af43f9e14c8e003255aeb1a996d071a347c02c80a90b6f"
            ;;
        armv7l)
            EZA_ARCH="arm-unknown-linux-gnueabihf"
            EZA_SHA256="115b3a3d3f0c7c8921a69e221d2256e5cf96393a18dde328ab5c1d97d2458326"
            ;;
        *)
            echo "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac
    mkdir -p /tmp/eza
    cd /tmp/eza
    curl -fsSL \
        "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}.zip" \
        -o eza.zip
    echo "${EZA_SHA256}  eza.zip" | sha256sum -c -
    unzip -q eza.zip
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