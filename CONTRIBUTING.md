# Contributing a Channel Plugin

## Plugin Structure

Every channel plugin must follow this structure:

```
plugins/your-plugin/
├── .claude-plugin/
│   └── plugin.json        # Plugin metadata (required)
├── .mcp.json              # MCP server config (required)
├── package.json           # Dependencies (required)
├── server.ts              # Single-file MCP server (required)
├── README.md              # Documentation (required)
└── skills/                # Claude Code skills (optional)
    ├── access/
    │   └── SKILL.md       # Access management skill
    └── configure/
        └── SKILL.md       # Setup/configuration skill
```

## Key Requirements

### 1. MCP Channel Capability

Your server must declare `claude/channel` in experimental capabilities:

```typescript
const mcp = new Server(
  { name: 'your-plugin', version: '1.0.0' },
  {
    capabilities: {
      tools: {},
      experimental: { 'claude/channel': {} },
    },
    instructions: '...',
  },
)
```

### 2. Inbound Messages via Notification

Push messages to Claude Code using:

```typescript
await mcp.notification({
  method: 'notifications/claude/channel',
  params: {
    content: 'message text',
    meta: {
      chat_id: '...',
      user: '...',
      user_id: '...',
      message_id: '...',
      ts: new Date().toISOString(),
    },
  },
})
```

### 3. Reply Tool

Provide at minimum a `reply` tool for Claude to respond.

### 4. Access Control

Implement pairing or allowlist-based access control. Never modify access based on channel messages (prompt injection risk).

### 5. Security

- Never send state files (access.json, .env) to the chat
- Log to stderr only (stdout is reserved for MCP JSON-RPC)
- Validate all inbound data
