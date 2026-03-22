# Claude-Plugins-Wechat

[English](#english) | [中文](#中文)

---

<a id="english"></a>

## WeChat Channel Plugin for Claude Code

Connect your personal **WeChat (微信)** to [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Messages arrive directly in your Claude Code session — Claude responds with **full agent capabilities**: file editing, terminal commands, code search, and more.

This is **not** an external bridge. The plugin runs **inside** Claude Code via MCP, giving it complete access to all tools.

```
WeChat (phone)  ←→  iLink Bot API  ←→  Plugin (MCP stdio)  ←→  Claude Code
```

### Quick Start

```bash
# 1. Clone
git clone https://github.com/zerolong0/Claude-Plugins-Wechat.git
cd Claude-Plugins-Wechat/plugins/wechat

# 2. Install
bun install

# 3. Login — scan the QR code with WeChat
bun server.ts login

# 4. Launch Claude Code with WeChat
claude --channels plugin:wechat@claude-plugins-official
```

Done. Send a WeChat message and Claude Code responds.

### Features

| Feature | Support |
|---------|---------|
| Text messages | Send & receive, auto-chunked, Markdown stripped |
| Images | Send & receive, AES-128-ECB CDN encryption |
| Voice | Receive with SILK→WAV transcoding + speech-to-text |
| Files | Send & receive (PDF, DOC, ZIP, etc.) |
| Video | Send & receive (MP4) |
| Quoted messages | Receive with context |
| Access control | Pairing codes, allowlist, or disabled |
| Daemon mode | tmux auto-restart with health monitoring |
| Typing indicator | Real-time "typing..." status |

### How It Differs from cc-connect

| | cc-connect | This Plugin |
|---|---|---|
| Architecture | External bridge → `claude -p` | MCP channel inside Claude Code |
| Claude capabilities | Limited (text only, no tools) | Full (Read, Edit, Bash, Grep, etc.) |
| Context | New process per message | Persistent session |
| Media | Basic text + images | Full: image, voice, file, video |
| CDN encryption | None | AES-128-ECB |

### Documentation

See [plugins/wechat/README.md](./plugins/wechat/README.md) for complete setup guide, access control, daemon mode, troubleshooting, and architecture details.

### Contributing

We welcome new channel plugins! See [CONTRIBUTING.md](./CONTRIBUTING.md) for the plugin specification.

### License

MIT

---

<a id="中文"></a>

## 微信频道插件 · Claude Code

将你的**个人微信**连接到 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)。微信消息直接进入 Claude Code 会话 — Claude 以**完整 Agent 能力**回复：编辑文件、执行命令、搜索代码，一切皆可。

这**不是**外部桥接器。插件通过 MCP 协议运行在 Claude Code **内部**，拥有所有工具的完整访问权限。

```
微信 (手机)  ←→  iLink Bot API  ←→  插件 (MCP stdio)  ←→  Claude Code
```

### 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/zerolong0/Claude-Plugins-Wechat.git
cd Claude-Plugins-Wechat/plugins/wechat

# 2. 安装依赖
bun install

# 3. 登录 — 用微信扫描终端中的二维码
bun server.ts login

# 4. 启动 Claude Code + 微信频道
claude --channels plugin:wechat@claude-plugins-official
```

完成。从微信发一条消息，Claude Code 会直接收到并回复。

### 功能支持

| 功能 | 支持 |
|------|------|
| 文本消息 | 收发，自动分段，Markdown 转纯文本 |
| 图片 | 收发，AES-128-ECB CDN 加解密 |
| 语音 | 接收，SILK→WAV 转码 + 语音转文字 |
| 文件 | 收发（PDF、DOC、ZIP 等） |
| 视频 | 收发（MP4） |
| 引用消息 | 接收，含上下文 |
| 权限控制 | 配对码 / 白名单 / 禁用 |
| 守护进程 | tmux 自动重启 + 健康监控 |
| 打字状态 | 实时「正在输入...」 |

### 与 cc-connect 的区别

| | cc-connect | 本插件 |
|---|---|---|
| 架构 | 外部桥接 → `claude -p` | MCP 频道，运行在 Claude Code 内部 |
| Claude 能力 | 受限（仅文本，无工具） | 完整（Read、Edit、Bash、Grep 等） |
| 上下文 | 每条消息新进程 | 持久会话 |
| 媒体 | 基础文本+图片 | 全类型：图片、语音、文件、视频 |
| CDN 加密 | 无 | AES-128-ECB |

### 详细文档

参见 [plugins/wechat/README.md](./plugins/wechat/README.md)，包含完整安装指南、权限控制、守护进程、故障排除和架构说明。

### 贡献

欢迎提交新的频道插件！参见 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解插件规范。

### 许可证

MIT
