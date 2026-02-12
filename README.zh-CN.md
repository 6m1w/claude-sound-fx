```
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ░██████╗░█████╗░██╗░░░██╗███╗░░██╗██████╗░                 ║
    ║   ██╔════╝██╔══██╗██║░░░██║████╗░██║██╔══██╗                 ║
    ║   ╚█████╗░██║░░██║██║░░░██║██╔██╗██║██║░░██║                 ║
    ║   ░╚═══██╗██║░░██║██║░░░██║██║╚████║██║░░██║                 ║
    ║   ██████╔╝╚█████╔╝╚██████╔╝██║░╚███║██████╔╝                ║
    ║   ╚═════╝░░╚════╝░░╚═════╝░╚═╝░░╚══╝╚═════╝░                ║
    ║                                                    FX         ║
    ║   Themed sound effects for Claude Code                        ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
```

<p align="center">
  <a href="./README.md">English</a> | 中文 | <a href="./README.ja.md">日本語</a>
</p>

> 你的终端太安静了。来点声音吧。

**Sound FX** 在 AI 编程助手的生命周期事件中播放主题音效 —— 会话启动、提交 prompt、任务完成、工具报错等。支持 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 和 [Opencode](https://opencode.ai)。

选择一个主题，或者开启 **Mix 模式**，让 12 个主题随机混搭。JARVIS 确认你的部署，GLaDOS 嘲讽你的错误，皮卡丘庆祝你的测试通过，魔兽争霸的苦工不情愿地执行你的命令。

---

## 平台支持

支持所有主流平台。本地使用无需额外配置。

| 平台 | 需要额外配置？ | 工作原理 |
|------|:------------:|---------|
| **macOS** | 否 | 通过 `afplay` 直接播放 |
| **Windows (WSL)** | 否 | 通过 WSL interop 自动调用 `powershell.exe` 或 `ffplay.exe` |
| **Linux 桌面** | 否 | 自动检测 `paplay` / `ffplay` / `aplay` |
| **远程服务器 (SSH)** | 是 | 需要在本地机器上运行 relay 脚本 — 见下方 |

### 远程服务器设置

在无声卡的 headless 服务器上运行时，声音通过轻量级 HTTP relay 转发到你的本地机器：

```bash
# ① 在本地机器上克隆仓库
git clone https://github.com/6m1w/claude-sound-fx.git

# ② 启动 relay（后台运行，监听 19876 端口）
python3 claude-sound-fx/scripts/relay.py &

# ③ SSH 连接时带端口转发
ssh -R 19876:127.0.0.1:19876 your-server

# ④ 在服务器上正常使用 Claude Code / Opencode — 声音在本地播放
```

Relay 命令：

```bash
python3 scripts/relay.py --status  # 查看配置和加载的主题
python3 scripts/relay.py --kill    # 停止 relay
```

---

## 安装

### Claude Code

```
/plugin marketplace add 6m1w/claude-sound-fx
/plugin install sound-fx@claude-sound-fx
```

然后配置你的主题：

```
/sound-fx:setup
```

安装向导会引导你选择主题和触发模式。

### Opencode

```bash
npm install @6m1w/opencode-sound-fx
```

在 `opencode.json` 中添加：

```json
{
  "plugin": ["@6m1w/opencode-sound-fx"]
}
```

共享相同的配置文件（`~/.claude/sound-fx.local.json`）和音频主题。

### 更新或卸载

随时运行同一个命令：

```
/sound-fx:setup
```

向导会让你选择 **Configure**、**Update** 或 **Remove**：

| 操作 | 说明 |
|------|------|
| **Configure** | 设置或更改主题和触发模式 |
| **Update** | 重新应用当前配置、刷新 hooks、播放测试音效 |
| **Remove** | 彻底移除音效 —— 删除配置文件 |

---

## 主题

### 科幻 & AI

| 主题 | 风格 | 来源 |
|------|------|------|
| **Jarvis** | *"随时为您服务。"* —— 冷静、专业、略带英伦范。 | 钢铁侠 |
| **GLaDOS** | *"这是一次伟大的胜利。"* —— 阴阳怪气的暗黑幽默 AI。 | 传送门 |
| **Star Trek** | 经典星舰界面的哔哔声和红色警报。 | 星际迷航 |
| **Optimus Prime** | *"汽车人，出发！"* —— 英雄指挥官的气场。 | 变形金刚 |

### 动漫

| 主题 | 风格 | 来源 |
|------|------|------|
| **JoJo** | DIO 的「无驼无驼」和承太郎的「好烦啊」—— 双声道混乱。 | JoJo 的奇妙冒险 |
| **One Piece** | 路飞的「太好了！」—— 橡皮人的纯粹能量。 | 海贼王 |
| **Pikachu** | 「皮卡丘！」—— 你完全知道这是什么声音。 | 宝可梦 |
| **Doraemon** | 「哆啦A梦！」—— 来自未来的机器猫。 | 哆啦A梦 |

### 游戏 & 其他

| 主题 | 风格 | 来源 |
|------|------|------|
| **WoW Peon** | *"准备开工！"* —— 不情愿、过劳、令人共情。 | 魔兽世界 |
| **StarCraft SCV** | *"SCV 准备就绪！"* —— 太空蓝领工人。 | 星际争霸 |
| **Steve Jobs** | *"One more thing..."* —— 发布会的灵感能量。 | Apple |
| **Mechanical Keyboard** | *咔嗒咔嗒咔嗒* —— 纯粹的 ASMR 满足感。 | 你的梦想 |

---

## 工作原理

Sound FX 挂钩到 7 个生命周期事件：

```
 SessionStart ──→ 🔊 "我准备好了。"           (主题: start)
 UserPromptSubmit ──→ 🔊 "收到。"             (主题: submit)
 Stop ──→ 🔊 "任务完成。"                     (主题: complete)
 PostToolUseFailure ──→ 🔊 "出错了。"         (主题: error)
 Notification ──→ 🔊 "嗯？"                   (主题: notification)
 PreCompact ──→ 🔊 "记忆消退中..."            (主题: precompact)
 SessionEnd ──→ 🔊 "下次再见。"               (主题: session_end)
```

> **注意：** 工具权限弹窗（批准/拒绝弹窗）不属于 Claude Code 可挂钩的生命周期事件，因此本插件无法在权限弹窗时播放音效。

### 模式

| 模式 | 说明 |
|------|------|
| **Mix**（默认） | 每次事件从 12 个主题中随机选择。最大混乱。 |
| **单一主题** | 固定使用一个主题。适合专注型选手。 |

### 触发级别

| 级别 | 事件 |
|------|------|
| **Full**（默认） | 全部 7 个事件都会触发音效 |
| **Minimal** | 仅启动、完成、报错、通知 |

配置存储在 `~/.claude/sound-fx.local.json`。随时运行 `/sound-fx:setup` 重新配置。

---

## 添加自定义主题

无需修改代码。只需在 `assets/` 下添加一个目录：

```
assets/my-theme/
├── manifest.json
├── MyThemeStart1.mp3
├── MyThemeComplete1.mp3
└── ...
```

`manifest.json` 格式：

```json
{
  "name": "My Theme",
  "description": "描述这个主题的声音风格",
  "start": ["MyThemeStart1.mp3"],
  "submit": [],
  "complete": ["MyThemeComplete1.mp3"],
  "error": [],
  "notification": [],
  "precompact": [],
  "session_end": []
}
```

空数组 `[]` 表示该事件不播放音效。

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_SOUND_VOLUME` | `60` | 音量（0–100） |
| `CLAUDE_SOUND_PORT` | `19876` | Relay 服务端口 |

---

## 许可证

MIT
