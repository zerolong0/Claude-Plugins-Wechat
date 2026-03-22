#!/bin/bash
# cc-wechat launcher with keepalive
# Usage:
#   cc-wechat            — 前台运行（交互模式）
#   cc-wechat daemon     — 后台守护进程（tmux + 自动重启）
#   cc-wechat status     — 检查健康状态
#   cc-wechat stop       — 停止守护进程
#   cc-wechat logs       — 查看日志

set -e

PLUGIN_SRC="$HOME/Documents/AI/cc-wechat/plugin/server.ts"
FAKECHAT_DST="$HOME/.claude/plugins/cache/claude-plugins-official/fakechat/0.0.1/server.ts"
WECHAT_DST="$HOME/.claude/plugins/cache/claude-plugins-official/wechat/0.1.0/server.ts"
LOG_DIR="$HOME/.claude/channels/wechat"
LOG_FILE="$LOG_DIR/debug.log"
PID_FILE="$LOG_DIR/daemon.pid"
HEALTH_FILE="$LOG_DIR/health.json"
TMUX_SESSION="cc-wechat"
MAX_RESTART_DELAY=60
RESTART_DELAY=5

# ── Sync latest code ──
sync_code() {
  if [ -f "$PLUGIN_SRC" ]; then
    cp "$PLUGIN_SRC" "$FAKECHAT_DST" 2>/dev/null
    sed -i '' "s/{ name: 'wechat'/{ name: 'fakechat'/" "$FAKECHAT_DST" 2>/dev/null
    cp "$PLUGIN_SRC" "$WECHAT_DST" 2>/dev/null
    echo "[cc-wechat] code synced"
  fi
}

# ── Kill stale processes ──
cleanup() {
  pkill -f "bun.*server.ts" 2>/dev/null || true
  sleep 1
}

# ── Health check ──
write_health() {
  local status=$1
  local msg=$2
  cat > "$HEALTH_FILE" << HEOF
{
  "status": "$status",
  "message": "$msg",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $$,
  "uptime_check": "$(date +%s)"
}
HEOF
}

# ── Commands ──

cmd_run() {
  cleanup
  sync_code
  echo "[cc-wechat] 启动中..."
  echo ""
  exec claude --channels plugin:fakechat@claude-plugins-official "$@"
}

cmd_daemon() {
  # Check if already running
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "[cc-wechat] 守护进程已在运行 (tmux: $TMUX_SESSION)"
    echo "  查看: tmux attach -t $TMUX_SESSION"
    echo "  停止: cc-wechat stop"
    return 0
  fi

  cleanup
  sync_code

  # Create tmux session with auto-restart loop
  tmux new-session -d -s "$TMUX_SESSION" bash -c "
    echo \$\$ > '$PID_FILE'
    DELAY=$RESTART_DELAY
    while true; do
      echo ''
      echo '═══════════════════════════════════════'
      echo \"[cc-wechat] 启动 Claude Code + 微信 (\$(date))\"
      echo '═══════════════════════════════════════'
      echo ''

      # Write health: starting
      cat > '$HEALTH_FILE' << EOF2
{\"status\":\"starting\",\"timestamp\":\"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"pid\":\$\$}
EOF2

      claude --channels plugin:fakechat@claude-plugins-official --dangerously-skip-permissions
      EXIT_CODE=\$?

      # Write health: restarting
      cat > '$HEALTH_FILE' << EOF2
{\"status\":\"restarting\",\"exit_code\":\$EXIT_CODE,\"timestamp\":\"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}
EOF2

      echo ''
      echo \"[cc-wechat] Claude Code 退出 (code=\$EXIT_CODE)，\${DELAY}秒后重启...\"
      sleep \$DELAY

      # Exponential backoff (cap at $MAX_RESTART_DELAY)
      DELAY=\$((DELAY * 2))
      if [ \$DELAY -gt $MAX_RESTART_DELAY ]; then DELAY=$MAX_RESTART_DELAY; fi

      # Sync code on restart (pick up updates)
      cp '$PLUGIN_SRC' '$FAKECHAT_DST' 2>/dev/null
      sed -i '' \"s/{ name: 'wechat'/{ name: 'fakechat'/\" '$FAKECHAT_DST' 2>/dev/null

      # Reset backoff after successful long run (>5min)
      DELAY=$RESTART_DELAY
    done
  "

  echo "[cc-wechat] 守护进程已启动 (tmux: $TMUX_SESSION)"
  echo ""
  echo "  查看:   tmux attach -t $TMUX_SESSION"
  echo "  状态:   cc-wechat status"
  echo "  日志:   cc-wechat logs"
  echo "  停止:   cc-wechat stop"
}

cmd_stop() {
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    tmux kill-session -t "$TMUX_SESSION"
    echo "[cc-wechat] 守护进程已停止"
  else
    echo "[cc-wechat] 守护进程未在运行"
  fi
  cleanup
  rm -f "$PID_FILE"
  write_health "stopped" "manually stopped"
}

cmd_status() {
  echo "cc-wechat 状态"
  echo "═══════════════════════════"

  # Tmux session
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "  守护进程:  ✅ 运行中 (tmux: $TMUX_SESSION)"
  else
    echo "  守护进程:  ❌ 未运行"
  fi

  # Bun server processes
  local server_count=$(pgrep -f "bun.*server.ts" 2>/dev/null | wc -l | tr -d ' ')
  echo "  Server 进程: $server_count 个"

  # Health file
  if [ -f "$HEALTH_FILE" ]; then
    local health_status=$(python3 -c "import json; d=json.load(open('$HEALTH_FILE')); print(d.get('status','?'))" 2>/dev/null)
    local health_ts=$(python3 -c "import json; d=json.load(open('$HEALTH_FILE')); print(d.get('timestamp','?'))" 2>/dev/null)
    echo "  健康状态:  $health_status ($health_ts)"
  fi

  # Account
  if [ -f "$LOG_DIR/account.json" ]; then
    local acct=$(python3 -c "import json; d=json.load(open('$LOG_DIR/account.json')); print(d.get('accountId','?'))" 2>/dev/null)
    echo "  微信账号:  $acct"
  else
    echo "  微信账号:  ❌ 未登录"
  fi

  # Access
  if [ -f "$LOG_DIR/access.json" ]; then
    local users=$(python3 -c "import json; d=json.load(open('$LOG_DIR/access.json')); print(len(d.get('allowed_users',{})))" 2>/dev/null)
    local policy=$(python3 -c "import json; d=json.load(open('$LOG_DIR/access.json')); print(d.get('dm_policy','?'))" 2>/dev/null)
    echo "  授权用户:  $users 个 (策略: $policy)"
  fi

  # Recent log
  if [ -f "$LOG_FILE" ]; then
    local last_poll=$(grep "Poll result" "$LOG_FILE" 2>/dev/null | tail -1)
    local last_msg=$(grep "dispatchToClaude" "$LOG_FILE" 2>/dev/null | tail -1)
    if [ -n "$last_poll" ]; then
      echo "  最近 Poll: ${last_poll:1:19}"
    fi
    if [ -n "$last_msg" ]; then
      echo "  最近消息:  ${last_msg:1:19}"
    fi
  fi
}

cmd_logs() {
  if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE"
  else
    echo "无日志文件: $LOG_FILE"
  fi
}

# ── Main ──
case "${1:-}" in
  daemon|d)
    cmd_daemon
    ;;
  stop)
    cmd_stop
    ;;
  status|s)
    cmd_status
    ;;
  logs|log|l)
    cmd_logs
    ;;
  *)
    cmd_run "$@"
    ;;
esac
