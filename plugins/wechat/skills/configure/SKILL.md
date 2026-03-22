---
name: configure
description: Set up the WeChat channel — scan QR code to link your WeChat account. Use when the user pastes a WeChat bot token, asks to configure WeChat, or wants to check channel status.
---

# WeChat Channel Configuration

## First-time Setup

WeChat uses QR code scanning to authenticate (unlike Telegram/Discord which use tokens).

### Step 1: Start QR Login

Run this command to initiate login:

```bash
cd "${CLAUDE_PLUGIN_ROOT}" && bun server.ts login
```

A QR code will appear in the terminal. Scan it with your WeChat mobile app and confirm.

### Step 2: Verify Connection

After scanning, the token and account ID are saved automatically to:
`~/.claude/channels/wechat/account.json`

### Step 3: Restart Claude Code

```bash
claude --channels plugin:wechat
```

## Check Status

To verify the connection is active, use the `wechat_status` tool.

## Troubleshooting

- **QR expired**: Run the login command again
- **Session expired (errcode -14)**: Re-run login to refresh credentials
- **No messages arriving**: Check that the sender is in your allowlist (`/wechat:access`)
