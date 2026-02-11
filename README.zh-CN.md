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

**Sound FX** 是一个 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 插件，在会话生命周期事件中播放主题音效 —— 会话启动、提交 prompt、任务完成、工具报错等。

选择一个主题，或者开启 **Mix 模式**，让 12 个主题随机混搭。JARVIS 确认你的部署，GLaDOS 嘲讽你的错误，皮卡丘庆祝你的测试通过，魔兽争霸的苦工不情愿地执行你的命令。

---

## 安装

```bash
claude /plugin install https://github.com/6m1w/claude-sound-fx
```

然后在 Claude Code 中运行：

```
/sound-fx:setup
```

安装向导会引导你选择主题和触发模式。

### 系统要求

- **macOS**（使用 `afplay` 播放音频）
- 支持插件的 **Claude Code**
- **Python 3**（用于读取配置 —— macOS 自带）

---

## 主题

### 科幻 & AI

| 主题 | 风格 | 来源 |
|------|------|------|
| **Jarvis** | *"随时为您服务。"* —— 冷静、专业、略带英伦范。 | 钢铁侠 |
| **GLaDOS** | *"这是一次伟大的胜利。"* —— 阴阳怪气的暗黑幽默 AI。 | 传送门 |
| **Star Trek** | 经典星舰界面的哔哔声和红色警报。 | 星际迷航 |
| **Optimus Prime** | *"汽车人，出发！"* —— 英雄指挥官的气场。 | 变形金刚 |

### 动漫 アニメ

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

Sound FX 挂钩到 7 个 Claude Code 生命周期事件：

```
 SessionStart ──→ 🔊 "我准备好了。"           (主题: start)
 UserPromptSubmit ──→ 🔊 "收到。"             (主题: submit)
 Stop ──→ 🔊 "任务完成。"                     (主题: complete)
 PostToolUseFailure ──→ 🔊 "出错了。"         (主题: error)
 Notification ──→ 🔊 "嗯？"                   (主题: notification)
 PreCompact ──→ 🔊 "记忆消退中..."            (主题: precompact)
 SessionEnd ──→ 🔊 "下次再见。"               (主题: session_end)
```

### 模式

| 模式 | 说明 |
|------|------|
| **Mix**（默认） | 每次事件从 12 个主题中随机选择。最大混乱。 |
| **单一主题** | 固定使用一个主题。适合专注型选手。 |

### 触发级别

| 级别 | 事件 |
|------|------|
| **Full**（默认） | 全部 7 个事件都会触发音效 |
| **Minimal** | 仅启动、完成、报错 |

配置存储在 `~/.claude/sound-fx.local.json`。随时运行 `/sound-fx:setup` 重新配置。

---

## 远程 / SSH 配置

通过 SSH 在远程服务器上工作？声音无法在远程播放，但你可以将其转发到本地 Mac。

**在本地 Mac 上** —— 启动转发服务器：

```bash
# 先找到插件路径
ls ~/.claude/plugins/sound-fx/

# 启动转发
python3 ~/.claude/plugins/sound-fx/scripts/relay.py
```

转发服务器监听 `127.0.0.1:19876`。当 Claude Code 在远程机器上运行时，hooks 会自动检测非 macOS 环境并通过 SSH 端口转发将事件 `curl` 到你的本地转发服务器。

**带端口转发的 SSH：**

```bash
ssh -R 19876:127.0.0.1:19876 user@remote-server
```

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
| `CLAUDE_SOUND_PORT` | `19876` | 远程模式的转发服务器端口 |

---

## 许可证

MIT
