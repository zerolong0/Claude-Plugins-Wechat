# 微信频道插件 · Claude Code

将个人微信连接到 Claude Code。微信消息直接进入 Claude Code 会话，Claude 以完整 Agent 能力回复。

## 工作原理

```
微信 (手机)  ←→  iLink Bot API  ←→  插件 (MCP stdio)  ←→  Claude Code
```

与外部桥接器不同，本插件以**频道**模式运行在 Claude Code 内部。Claude 实时收到你的消息，可以使用全部工具回复。

## 安装（3 步）

### 1. 安装依赖

```bash
cd plugins/wechat
bun install
```

### 2. 登录

```bash
bun server.ts login
```

终端会显示二维码，用微信扫码并在手机确认。

凭证保存在 `~/.claude/channels/wechat/account.json`。

### 3. 启动

```bash
claude --channels plugin:wechat@claude-plugins-official
```

就这样。从微信发消息，Claude Code 直接收到。

## 首次消息 — 配对

新用户首次发消息时会收到 6 位配对码：

```
🔐 需要配对。
请在终端运行：
/wechat:access pair a7ed71
```

在 Claude Code 中运行 `/wechat:access` 技能批准。

## 媒体支持

| 类型 | 接收 | 发送 | 说明 |
|------|------|------|------|
| 文本 | ✅ | ✅ | 自动分段（3800字），Markdown 转纯文本 |
| 图片 | ✅ | ✅ | 立即下载到 `inbox/`，CDN 加密上传 |
| 语音 | ✅ | — | SILK → WAV 转码 + 语音转文字 |
| 文件 | ✅ | ✅ | PDF、DOC、ZIP 等（按需下载，CDN 上传） |
| 视频 | ✅ | ✅ | MP4（按需下载，CDN 上传） |
| 引用消息 | ✅ | — | 含引用文本和媒体 |

## 工具

频道激活时 Claude Code 可用以下工具：

| 工具 | 说明 |
|------|------|
| `reply` | 发送文本和/或文件给微信用户 |
| `download_attachment` | 从微信 CDN 下载语音/视频/文件 |
| `wechat_status` | 查看连接状态和权限策略 |

## 权限控制

三种 DM 策略：

| 策略 | 行为 |
|------|------|
| `pairing`（默认） | 未知用户收到配对码，需在终端批准 |
| `allowlist` | 仅允许预批准用户，其他静默忽略 |
| `disabled` | 所有消息丢弃 |

配置文件：`~/.claude/channels/wechat/access.json`

通过 `/wechat:access` 技能管理。

## 守护进程模式

全天运行：

```bash
# 前台模式（交互）
./launch.sh

# 后台守护（tmux + 自动重启）
./launch.sh daemon

# 查看状态
./launch.sh status

# 查看日志
./launch.sh logs

# 停止
./launch.sh stop
```

守护进程在 Claude Code 退出后自动重启，带指数退避。

## 状态目录

所有状态在 `~/.claude/channels/wechat/`：

```
account.json     Bot 凭证（token, accountId）
access.json      DM 策略 + 用户白名单 + 待配对列表
sync.json        长轮询游标（重启不丢失）
health.json      健康状态（每次 poll 更新）
debug.log        调试日志
inbox/           已下载的媒体文件
```

## 架构

单文件 MCP 频道服务器（`server.ts`，约 1000 行），包含：

- iLink Bot API 客户端（6 个端点）
- AES-128-ECB CDN 加解密
- SILK 音频转 WAV
- 配对权限控制
- 消息解析（文本、图片、语音、文件、视频、引用）
- 出站消息分段和媒体上传

协议源自 `@tencent-weixin/openclaw-weixin`（MIT 许可）。

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 二维码过期 | 重新运行 `bun server.ts login` |
| 会话过期（errcode -14） | 服务器自动暂停 1 小时后恢复 |
| 收不到消息 | 检查 `access.json` 中 `allowed_users` |
| 多个 bun 进程 | 运行 `pkill -f "bun.*server.ts"` 清理 |
| `not on approved channels allowlist` | 添加 `--dangerously-load-development-channels` |

## 许可证

MIT
