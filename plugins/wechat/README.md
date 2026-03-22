# WeChat Channel Plugin for Claude Code

Connect your personal WeChat (微信) to Claude Code. Messages from WeChat are delivered directly into your Claude Code session — Claude responds with its **full capabilities** (file editing, terminal commands, code search, etc.).

## How It Works

```
WeChat (phone)  ←→  iLink Bot API  ←→  Plugin (MCP)  ←→  Claude Code
```

Unlike external bridges, this plugin runs **inside** Claude Code as a channel. Claude sees your messages in real-time and can use all its tools to respond.

## Setup (3 steps)

### 1. Install

```bash
cd plugins/wechat
bun install
```

**Optional: register `cc-wechat` as a global command**

```bash
bun install -g .
```

This adds `cc-wechat` to your PATH so you can run `cc-wechat`, `cc-wechat daemon`, `cc-wechat status`, etc. from anywhere.

### 2. Login

```bash
# If installed globally:
cc-wechat login

# Or directly:
bun server.ts login
```

A QR code appears in your terminal. Scan it with WeChat on your phone and confirm.

Your credentials are saved to `~/.claude/channels/wechat/account.json`.

### 3. Launch

```bash
claude --channels plugin:wechat@claude-plugins-official
```

That's it. Send a WeChat message and it appears in Claude Code.

## First Message — Pairing

When someone messages your bot for the first time, they receive a 6-character code:

```
🔐 Pairing required.
To connect, run this in your terminal:
/wechat:access pair a7ed71
```

Approve it in Claude Code by running the `/wechat:access` skill.

## Supported Media

| Type | Receive | Send | Details |
|------|---------|------|---------|
| Text | ✅ | ✅ | Auto-chunked at 3800 chars, Markdown stripped |
| Image | ✅ | ✅ | Eagerly downloaded to `inbox/`, CDN upload for sending |
| Voice | ✅ | — | SILK → WAV transcoding + voice-to-text |
| File | ✅ | ✅ | PDF, DOC, ZIP, etc. (lazy download, CDN upload) |
| Video | ✅ | ✅ | MP4 (lazy download, CDN upload) |
| Quoted messages | ✅ | — | Referenced text and media |

## Tools

Claude Code has access to these tools when the channel is active:

| Tool | Description |
|------|-------------|
| `reply` | Send text and/or files to a WeChat user |
| `download_attachment` | Download voice/video/file from WeChat CDN |
| `wechat_status` | Check connection status and access policy |

## Access Control

Three DM policies:

| Policy | Behavior |
|--------|----------|
| `pairing` (default) | Unknown senders get a pairing code to approve |
| `allowlist` | Only pre-approved users, others silently dropped |
| `disabled` | All messages dropped |

Configuration stored at `~/.claude/channels/wechat/access.json`.

Manage via the `/wechat:access` skill in Claude Code.

## Keepalive / Daemon Mode

For all-day operation, use the launch script:

```bash
# Foreground (interactive)
cc-wechat

# Background daemon (tmux + auto-restart)
cc-wechat daemon

# Check status
cc-wechat status

# View logs
cc-wechat logs

# Stop
cc-wechat stop
```

> If not installed globally, use `./cc-wechat.sh` instead.

The daemon automatically restarts Claude Code if it exits, with exponential backoff.

## State Directory

All state lives in `~/.claude/channels/wechat/`:

```
account.json     Bot credentials (token, accountId)
access.json      DM policy + user allowlist + pending pairings
sync.json        Long-poll cursor (survives restarts)
health.json      Health status (updated every poll cycle)
debug.log        Debug log
inbox/           Downloaded media files
```

## Architecture

Single-file MCP channel server (`server.ts`, ~1000 lines) containing:

- iLink Bot API client (6 endpoints: getUpdates, sendMessage, getConfig, sendTyping, getUploadUrl, getQrCode)
- AES-128-ECB CDN encryption/decryption
- SILK audio to WAV transcoding
- Access control with pairing
- Message parsing (text, image, voice, file, video, quoted messages)
- Outbound message chunking and media upload

Protocol derived from `@tencent-weixin/openclaw-weixin` (MIT license).

## Troubleshooting

| Issue | Solution |
|-------|----------|
| QR code expired | Run `bun server.ts login` again |
| Session expired (errcode -14) | Server auto-pauses 1 hour, then recovers |
| No messages arriving | Check `access.json` — is the sender in `allowed_users`? |
| Multiple bun processes | Run `pkill -f "bun.*server.ts"` to clean up |
| `not on approved channels allowlist` | Use `--dangerously-load-development-channels` flag |

## License

MIT
