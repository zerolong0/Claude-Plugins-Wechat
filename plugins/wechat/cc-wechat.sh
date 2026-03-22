#!/bin/bash
# cc-wechat — WeChat Channel Plugin for Claude Code
# Usage:
#   cc-wechat              Launch Claude Code with WeChat channel
#   cc-wechat login        Scan QR code to link WeChat
#   cc-wechat daemon       Background mode (tmux + auto-restart)
#   cc-wechat status       Check connection health
#   cc-wechat logs         Tail debug log
#   cc-wechat stop         Stop daemon

set -e

# Resolve plugin directory (works whether installed globally or locally)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# If installed via npm bin, follow the symlink
if [ -L "$0" ]; then
  REAL_PATH="$(readlink "$0")"
  if [[ "$REAL_PATH" != /* ]]; then
    REAL_PATH="$(cd "$(dirname "$0")" && cd "$(dirname "$REAL_PATH")" && pwd)/$(basename "$REAL_PATH")"
  fi
  SCRIPT_DIR="$(dirname "$REAL_PATH")"
fi

PLUGIN_DIR="$SCRIPT_DIR"
SERVER="$PLUGIN_DIR/server.ts"
CHANNEL_DIR="$HOME/.claude/channels/wechat"
LOG_FILE="$CHANNEL_DIR/debug.log"
TMUX_SESSION="cc-wechat"

ensure_dirs() {
  mkdir -p "$CHANNEL_DIR/inbox"
}

case "${1:-}" in
  login)
    ensure_dirs
    cd "$PLUGIN_DIR"
    bun install --no-summary 2>/dev/null
    exec bun server.ts login
    ;;

  daemon|d)
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
      echo "[cc-wechat] Daemon already running (tmux: $TMUX_SESSION)"
      echo "  Attach: tmux attach -t $TMUX_SESSION"
      echo "  Stop:   cc-wechat stop"
      exit 0
    fi
    pkill -f "bun.*server.ts" 2>/dev/null || true
    sleep 1
    tmux new-session -d -s "$TMUX_SESSION" bash -c "
      while true; do
        echo '[cc-wechat] Starting... (\$(date))'
        claude --channels plugin:fakechat@claude-plugins-official --dangerously-skip-permissions
        echo '[cc-wechat] Exited, restarting in 5s...'
        sleep 5
      done
    "
    echo "[cc-wechat] Daemon started"
    echo "  Attach: tmux attach -t $TMUX_SESSION"
    echo "  Status: cc-wechat status"
    echo "  Stop:   cc-wechat stop"
    ;;

  stop)
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null && echo "[cc-wechat] Stopped" || echo "[cc-wechat] Not running"
    pkill -f "bun.*server.ts" 2>/dev/null || true
    ;;

  status|s)
    echo "cc-wechat status"
    echo "═══════════════════"
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
      echo "  Daemon:  running"
    else
      echo "  Daemon:  stopped"
    fi
    PROCS=$(pgrep -f "bun.*server.ts" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Server:  $PROCS process(es)"
    if [ -f "$CHANNEL_DIR/account.json" ]; then
      ACCT=$(python3 -c "import json;print(json.load(open('$CHANNEL_DIR/account.json'))['accountId'])" 2>/dev/null)
      echo "  Account: $ACCT"
    else
      echo "  Account: not logged in"
    fi
    if [ -f "$CHANNEL_DIR/access.json" ]; then
      USERS=$(python3 -c "import json;print(len(json.load(open('$CHANNEL_DIR/access.json')).get('allowed_users',{})))" 2>/dev/null)
      echo "  Users:   $USERS allowed"
    fi
    if [ -f "$CHANNEL_DIR/health.json" ]; then
      python3 -c "
import json
h=json.load(open('$CHANNEL_DIR/health.json'))
print(f\"  Health:  {h.get('status','?')} (uptime {h.get('uptime_s',0)}s, {h.get('polls',0)} polls, {h.get('messages_received',0)} msgs)\")
" 2>/dev/null
    fi
    ;;

  logs|log|l)
    if [ -f "$LOG_FILE" ]; then
      tail -f "$LOG_FILE"
    else
      echo "No log file: $LOG_FILE"
    fi
    ;;

  *)
    # Default: launch Claude Code with WeChat channel
    pkill -f "bun.*server.ts" 2>/dev/null || true
    sleep 1
    exec claude --channels plugin:fakechat@claude-plugins-official "$@"
    ;;
esac
