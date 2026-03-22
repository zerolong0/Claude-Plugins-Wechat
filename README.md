# Claude-Plugins-Wechat

Community channel plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Plugins

| Plugin | Description | Status |
|--------|-------------|--------|
| [wechat](./plugins/wechat/) | WeChat (微信) channel — send and receive messages, images, voice, files, and video through personal WeChat | Beta |

## What are Channel Plugins?

Channel plugins connect Claude Code to external messaging platforms. When a channel is active, Claude Code can:

- Receive messages from the platform in real-time
- Reply using its full capabilities (Read, Edit, Bash, Grep, etc.)
- Send files, images, and other media back to the chat

This is fundamentally different from external bridges like cc-connect — Claude Code itself handles the conversation, not a limited `-p` subprocess.

```
WeChat User (phone)
     ↕  iLink Bot API
Channel Plugin (MCP stdio)
     ↕
Claude Code (full agent capabilities)
```

## Quick Start

### WeChat

```bash
# 1. Install
cd plugins/wechat && bun install

# 2. Login (scan QR code with WeChat)
bun server.ts login

# 3. Launch Claude Code with WeChat channel
claude --channels plugin:wechat@claude-plugins-official
```

See [plugins/wechat/README.md](./plugins/wechat/README.md) for full documentation.

## Contributing

We welcome new channel plugins! See [CONTRIBUTING.md](./CONTRIBUTING.md) for the plugin specification.

## License

MIT
