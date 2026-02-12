# @6m1w/opencode-sound-fx

Themed sound effects plugin for [Opencode](https://opencode.ai) — the same audio themes from [claude-sound-fx](https://github.com/6m1w/claude-sound-fx), now for Opencode.

## Install

```bash
# In your project or global opencode config
npm install @6m1w/opencode-sound-fx
```

Add to `opencode.json`:

```json
{
  "plugin": ["@6m1w/opencode-sound-fx"]
}
```

## Configuration

Uses the same config file as claude-sound-fx:

```bash
# ~/.claude/sound-fx.local.json
# (or ~/.config/opencode/sound-fx.json)
```

```json
{
  "theme": "jarvis",
  "mode": "full",
  "enabled": true
}
```

### Options

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `theme` | `"mix"`, `"jarvis"`, `"glados"`, `"trek"`, ... | `"mix"` | Sound theme |
| `mode` | `"full"`, `"minimal"` | `"full"` | Which events trigger sounds |
| `enabled` | `true`, `false` | `true` | Enable/disable sounds |

### Available Themes

Jarvis, GLaDOS, Star Trek, Optimus Prime, JoJo, One Piece, Pikachu, Doraemon, WoW Peon, StarCraft SCV, Steve Jobs, Mechanical Keyboard

## Event Mapping

| Opencode Event | Sound Event | Description |
|----------------|-------------|-------------|
| `session.created` | `start` | New session started |
| `message.updated` (user) | `submit` | User sent a message |
| `session.idle` (busy→idle) | `complete` | AI finished responding |
| `session.error` | `error` | Error occurred |
| `session.compacted` | `precompact` | Context was compacted |
| `session.deleted` | `session_end` | Session ended |

## Cross-Platform

Automatically detects the available audio player:

| Platform | Player |
|----------|--------|
| macOS | `afplay` |
| Linux (PulseAudio) | `paplay` |
| Linux (ALSA) | `aplay` |
| Linux (ffmpeg) | `ffplay` |
| Windows | PowerShell `SoundPlayer` |

## Volume

Set via environment variable:

```bash
export CLAUDE_SOUND_VOLUME=60  # 0-100, default 60
```

## License

MIT
