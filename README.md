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

> Your terminal is too quiet.
> Let's fix that.

**Sound FX** is a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that plays themed sound effects in response to lifecycle events — session start, prompt submit, task complete, errors, and more.

Pick a single theme or go **Mix mode** and let 12 themes collide randomly. JARVIS confirms your deploy. GLaDOS mocks your errors. Pikachu celebrates your tests passing. A WoW Peon reluctantly obeys your commands.

---

<details>
<summary>🇨🇳 中文说明</summary>

### Sound FX — Claude Code 主题音效插件

你的终端太安静了。

**Sound FX** 是一个 Claude Code 插件，在会话生命周期事件中播放主题音效。支持 12 个主题，可以选择单一主题，也可以用 Mix 模式让所有主题随机混搭。

**安装：**

```bash
claude /plugin install https://github.com/6m1w/claude-sound-fx
```

安装后在 Claude Code 中输入 `/sound-fx:setup` 进行配置。

**支持的事件：** 会话启动、提交 prompt、任务完成、工具报错、context 压缩、会话结束。

</details>

<details>
<summary>🇯🇵 日本語の説明</summary>

### Sound FX — Claude Code テーマサウンドエフェクトプラグイン

ターミナルが静かすぎる。

**Sound FX** は Claude Code のプラグインで、セッションのライフサイクルイベントにテーマサウンドエフェクトを再生します。12種類のテーマから選択でき、ミックスモードでランダム再生も可能です。

**インストール：**

```bash
claude /plugin install https://github.com/6m1w/claude-sound-fx
```

インストール後、Claude Code で `/sound-fx:setup` を実行して設定してください。

**対応イベント：** セッション開始、プロンプト送信、タスク完了、ツールエラー、コンテキスト圧縮、セッション終了。

</details>

---

## Install

```bash
claude /plugin install https://github.com/6m1w/claude-sound-fx
```

Then inside Claude Code:

```
/sound-fx:setup
```

That's it. The setup wizard will walk you through theme selection and trigger mode.

### Requirements

- **macOS** (uses `afplay` for audio playback)
- **Claude Code** with plugin support
- **Python 3** (for reading config — ships with macOS)

---

## Themes

### Sci-Fi & AI

| Theme | Vibe | Origin |
|-------|------|--------|
| **Jarvis** | *"At your service, sir."* — Calm, competent, slightly British. | Iron Man |
| **GLaDOS** | *"This was a triumph."* — Passive-aggressive AI with dark humor. | Portal |
| **Star Trek** | Classic starship interface chirps, beeps, and red alerts. | Star Trek |
| **Optimus Prime** | *"Autobots, roll out."* — Heroic commander energy. | Transformers |

### Anime アニメ

| Theme | Vibe | Origin |
|-------|------|--------|
| **JoJo** | DIO の「無駄無駄」と承太郎の「やれやれだぜ」— Dual voice chaos. | ジョジョの奇妙な冒険 |
| **One Piece** | ルフィの「よっしゃー！」— Pure rubber-band energy. | ワンピース |
| **Pikachu** | 「ピカチュウ！」— You know exactly how this sounds. | ポケットモンスター |
| **Doraemon** | 「ドラえもーん！」— The robotic cat from the future. | ドラえもん |

### Gaming & Other

| Theme | Vibe | Origin |
|-------|------|--------|
| **WoW Peon** | *"Ready to work!"* — Reluctant, overworked, relatable. | World of Warcraft |
| **StarCraft SCV** | *"SCV good to go, sir!"* — Blue-collar space worker. | StarCraft |
| **Steve Jobs** | *"One more thing..."* — Inspirational keynote energy. | Apple |
| **Mechanical Keyboard** | *clack clack clack* — Pure ASMR satisfaction. | Your dreams |

---

## How It Works

Sound FX hooks into 7 Claude Code lifecycle events:

```
 SessionStart ──→ 🔊 "I am ready."         (theme: start)
 UserPromptSubmit ──→ 🔊 "Understood."      (theme: submit)
 Stop ──→ 🔊 "Task complete."               (theme: complete)
 PostToolUseFailure ──→ 🔊 "That was a mistake." (theme: error)
 Notification ──→ 🔊 "Hmm?"                 (theme: notification)
 PreCompact ──→ 🔊 "Memory failing..."      (theme: precompact)
 SessionEnd ──→ 🔊 "Until next time."       (theme: session_end)
```

### Modes

| Mode | What it does |
|------|-------------|
| **Mix** (default) | Randomly picks from all 12 themes per event. Maximum chaos. |
| **Single Theme** | Sticks to one theme. For the focused individual. |

### Trigger Levels

| Level | Events |
|-------|--------|
| **Full** (default) | All 7 events fire sounds |
| **Minimal** | Only start, complete, error |

Config is stored at `~/.claude/sound-fx.local.json`. Re-run `/sound-fx:setup` anytime to change.

---

## Remote / SSH Setup

Working on a remote server over SSH? Sounds can't play there, but you can relay them to your local Mac.

**On your local Mac** — start the relay server:

```bash
# Find your plugin path first
ls ~/.claude/plugins/sound-fx/

# Start the relay
python3 ~/.claude/plugins/sound-fx/scripts/relay.py
```

The relay listens on `127.0.0.1:19876`. When Claude Code runs on the remote machine, hooks automatically detect non-macOS and `curl` events to your local relay via SSH port forwarding.

**SSH with port forwarding:**

```bash
ssh -R 19876:127.0.0.1:19876 user@remote-server
```

---

## Add Your Own Theme

No code changes needed. Just add a directory under `assets/`:

```
assets/my-theme/
├── manifest.json
├── MyThemeStart1.mp3
├── MyThemeComplete1.mp3
└── ...
```

`manifest.json` format:

```json
{
  "name": "My Theme",
  "description": "What it sounds like",
  "start": ["MyThemeStart1.mp3"],
  "submit": [],
  "complete": ["MyThemeComplete1.mp3"],
  "error": [],
  "notification": [],
  "precompact": [],
  "session_end": []
}
```

Empty arrays `[]` are fine — that event just won't play a sound for your theme.

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_SOUND_VOLUME` | `60` | Volume level (0–100) |
| `CLAUDE_SOUND_PORT` | `19876` | Relay server port for remote mode |

---

## License

MIT
