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
  <a href="./README.md">English</a> | <a href="./README.zh-CN.md">中文</a> | 日本語
</p>

> タスクを開始して、ブラウザに切り替えて、ターミナルのことを忘れる。
> 5分後に戻ると —— ずっとあなたを待っていた。

**Sound FX** は [Claude Code](https://docs.anthropic.com/en/docs/claude-code) と [Opencode](https://opencode.ai) にテーマ音声キューを追加し、ターミナルを監視し続ける必要をなくします。タスク完了、エラー発生、入力待ち —— 別のウィンドウにいても聞こえます。

テーマを1つ選ぶか、**Mix モード**で12種類のテーマをランダムに混ぜましょう。JARVIS がデプロイを確認し、GLaDOS がエラーを嘲笑い、ピカチュウがテスト成功を祝い、WoW のペオンが渋々コマンドに従います。

https://github.com/user-attachments/assets/c47537fc-1c18-4256-877d-0f22d4314bfd

---

## プラットフォーム対応

すべての主要プラットフォームで動作します。ローカル使用では追加セットアップ不要。

| プラットフォーム | 追加セットアップ | 仕組み |
|------------------|:------------:|--------|
| **macOS** | 不要 | `afplay` で直接再生 |
| **Windows (WSL)** | 不要 | WSL interop で `powershell.exe` または `ffplay.exe` を自動使用 |
| **Linux デスクトップ** | 不要 | `paplay` / `ffplay` / `aplay` を自動検出 |
| **リモートサーバー (SSH)** | 必要 | ローカルマシンで relay スクリプトを実行 — 下記参照 |

### リモートサーバーセットアップ

オーディオハードウェアのない headless サーバーで実行する場合、軽量な HTTP relay 経由でローカルマシンにサウンドを転送します：

```bash
# ① ローカルマシンでリポジトリをクローン
git clone https://github.com/6m1w/claude-sound-fx.git

# ② relay を起動（バックグラウンド実行、ポート 19876 で待機）
python3 claude-sound-fx/scripts/relay.py &

# ③ ポート転送付きで SSH 接続
ssh -R 19876:127.0.0.1:19876 your-server

# ④ サーバー上で Claude Code / Opencode を通常通り使用 — サウンドはローカルで再生
```

Relay コマンド：

```bash
python3 scripts/relay.py --status  # 設定とロードされたテーマを表示
python3 scripts/relay.py --kill    # relay を停止
```

---

## インストール

### Claude Code

```
/plugin marketplace add 6m1w/claude-sound-fx
/plugin install sound-fx@claude-sound-fx
```

テーマを設定：

```
/sound-fx:setup
```

セットアップウィザードがテーマ選択とトリガーモードの設定を案内します。

### Opencode

```bash
npm install @6m1w/opencode-sound-fx
```

`opencode.json` に追加：

```json
{
  "plugin": ["@6m1w/opencode-sound-fx"]
}
```

同じ設定ファイル（`~/.claude/sound-fx.local.json`）とオーディオテーマを共有します。

### 更新・削除

同じコマンドをいつでも実行：

```
/sound-fx:setup
```

ウィザードが **Configure**、**Update**、**Remove** の選択肢を表示します：

| アクション | 動作 |
|------------|------|
| **Configure** | テーマとトリガーモードの設定・変更 |
| **Update** | 現在の設定を再適用、フックを更新、テストサウンドを再生 |
| **Remove** | サウンドエフェクトを完全に削除 — 設定ファイルを削除 |

---

## テーマ

### SF & AI

| テーマ | 雰囲気 | 出典 |
|--------|--------|------|
| **Jarvis** | *「お呼びですか。」* — 冷静で有能、少しブリティッシュ。 | アイアンマン |
| **GLaDOS** | *「大成功でした。」* — 皮肉たっぷりのダークユーモア AI。 | Portal |
| **Star Trek** | クラシックな宇宙艦のインターフェースビープ音とレッドアラート。 | スタートレック |
| **Optimus Prime** | *「オートボット、出動！」* — ヒーロー指揮官のエネルギー。 | トランスフォーマー |

### アニメ

| テーマ | 雰囲気 | 出典 |
|--------|--------|------|
| **JoJo** | DIO の「無駄無駄」と承太郎の「やれやれだぜ」— カオスの二重奏。 | ジョジョの奇妙な冒険 |
| **One Piece** | ルフィの「よっしゃー！」— 純粋なゴム人間エネルギー。 | ワンピース |
| **Pikachu** | 「ピカチュウ！」— まさにあの声。 | ポケットモンスター |
| **Doraemon** | 「ドラえもーん！」— 未来からやってきたネコ型ロボット。 | ドラえもん |

### ゲーム & その他

| テーマ | 雰囲気 | 出典 |
|--------|--------|------|
| **WoW Peon** | *「仕事する準備できました！」* — 渋々、過労、共感できる。 | World of Warcraft |
| **StarCraft SCV** | *「SCV、出動準備完了！」* — 宇宙のブルーカラー作業員。 | StarCraft |
| **Steve Jobs** | *「One more thing...」* — インスピレーショナルな基調講演エネルギー。 | Apple |
| **Mechanical Keyboard** | *カチカチカチ* — 純粋な ASMR の満足感。 | あなたの夢 |

---

## 仕組み

Sound FX は7つのライフサイクルイベントにフックします：

```
 SessionStart ──→ 🔊 「準備完了。」              (テーマ: start)
 UserPromptSubmit ──→ 🔊 「了解。」             (テーマ: submit)
 Stop ──→ 🔊 「タスク完了。」                    (テーマ: complete)
 PostToolUseFailure ──→ 🔊 「エラーです。」      (テーマ: error)
 Notification ──→ 🔊 「ん？」                    (テーマ: notification)
 PreCompact ──→ 🔊 「記憶が薄れていく...」       (テーマ: precompact)
 SessionEnd ──→ 🔊 「また次回。」                (テーマ: session_end)
```

> **注意：** ツール権限プロンプト（承認/拒否ポップアップ）は Claude Code のフック可能なライフサイクルイベントではないため、このプラグインでは音を再生できません。

### モード

| モード | 動作 |
|--------|------|
| **Mix**（デフォルト） | イベントごとに12テーマからランダム選択。最大のカオス。 |
| **単一テーマ** | 1つのテーマに固定。集中したい人向け。 |

### トリガーレベル

| レベル | イベント |
|--------|----------|
| **Full**（デフォルト） | 全7イベントでサウンド再生 |
| **Minimal** | 開始、完了、エラー、通知のみ |

設定は `~/.claude/sound-fx.local.json` に保存されます。`/sound-fx:setup` をいつでも再実行して変更可能です。

---

## カスタムテーマの追加

コード変更は不要です。`assets/` にディレクトリを追加するだけ：

```
assets/my-theme/
├── manifest.json
├── MyThemeStart1.mp3
├── MyThemeComplete1.mp3
└── ...
```

`manifest.json` フォーマット：

```json
{
  "name": "My Theme",
  "description": "テーマのサウンドスタイルの説明",
  "start": ["MyThemeStart1.mp3"],
  "submit": [],
  "complete": ["MyThemeComplete1.mp3"],
  "error": [],
  "notification": [],
  "precompact": [],
  "session_end": []
}
```

空の配列 `[]` はそのイベントでサウンドを再生しないことを意味します。

---

## 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `CLAUDE_SOUND_VOLUME` | `60` | 音量レベル（0–100） |
| `CLAUDE_SOUND_PORT` | `19876` | Relay サーバーポート |

---

## ライセンス

MIT
