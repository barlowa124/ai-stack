#!/bin/bash
# Local AI coding stack — macOS (Apple Silicon)
# Installs Ollama app + CLI symlink, uv, aider, opencode; pulls sized-for-RAM models.
set -e

echo "== ollama =="
if [ ! -d /Applications/Ollama.app ]; then
  ARCH=$(uname -m)
  curl -fL https://ollama.com/download/Ollama-darwin.zip -o /tmp/ollama_app.zip
  unzip -q /tmp/ollama_app.zip -d /Applications
  rm /tmp/ollama_app.zip
fi
mkdir -p "$HOME/.local/bin"
ln -sf /Applications/Ollama.app/Contents/Resources/ollama "$HOME/.local/bin/ollama"
OLLAMA=/Applications/Ollama.app/Contents/Resources/ollama

echo "== aider + opencode =="
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install --force --python python3.12 aider-chat@latest
curl -fsSL https://opencode.ai/install | bash 2>/dev/null || true

echo "== server (polite mode: yields to user apps, auto-unloads when idle) =="
cat > "$HOME/.local/bin/ollama-start" <<'EOS'
#!/bin/bash
OLLAMA=/Applications/Ollama.app/Contents/Resources/ollama
pgrep -f "ollama serve" >/dev/null && { echo "already running"; exit 0; }
OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_MAX_LOADED_MODELS=1 OLLAMA_KEEP_ALIVE=5m \
OLLAMA_NUM_PARALLEL=1 nohup nice -n 15 "$OLLAMA" serve > /tmp/ollama_serve.log 2>&1 &
disown; sleep 2; curl -s localhost:11434/api/version
EOS
chmod +x "$HOME/.local/bin/ollama-start"
"$HOME/.local/bin/ollama-start"

echo "== models (sized for 16GB unified memory) =="
"$OLLAMA" pull qwen2.5-coder:14b   # workhorse — ~9GB
"$OLLAMA" pull qwen2.5-coder:7b    # fast weak model — ~4.7GB
# 32GB+ RAM machines can pull qwen2.5-coder:32b instead of the 14b

echo "== configs =="
cp "$(dirname "$0")/.aider.conf.yml" "$HOME/.aider.conf.yml"
mkdir -p "$HOME/.config/opencode"
cp "$(dirname "$0")/opencode.json" "$HOME/.config/opencode/opencode.json"

echo "Done. Run 'aider' in any project dir, or 'opencode' for the agent TUI."
