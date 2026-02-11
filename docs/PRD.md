# claude-sound-fx

为 Claude Code 提供主题化音效反馈的插件。支持多主题选择、Mix 混合模式、触发模式配置。

## 产品设计

### 用户体验流程

1. 安装插件：`claude plugin:add github:6m1w/claude-sound-fx`
2. 首次 SessionStart → 提示运行 `/sound-fx:setup`
3. 交互式选择主题 + 触发模式 → 写入 `~/.claude/sound-fx.local.json`
4. 后续 session 自动按配置播放音效
5. 想改配置 → 重新运行 `/sound-fx:setup`

### 配置选项

**主题模式：**
- Mix（默认）— 所有主题随机混合
- 单一主题 — 只从选定主题播放

**触发模式：**
- Full（默认）— 所有 7 个事件都触发
- Minimal — 仅 ready / complete / error

### Hook 事件映射

| Hook 事件 | 音效事件 | 触发时机 | Minimal 模式 |
|-----------|---------|---------|-------------|
| SessionStart | ready | 会话启动 | yes |
| UserPromptSubmit | yes | 用户提交 prompt | no |
| Notification | what | 通知提醒 | no |
| Stop | complete | Claude 完成回复 | yes |
| PostToolUseFailure | error | 工具调用失败 | yes |
| PreCompact | precompact | context 压缩前 | no |
| SessionEnd | session_end | 会话结束 | no |

---

## 主题清单

| # | 目录名 | 显示名 | 风格 | 音频来源 | 状态 |
|---|--------|--------|------|---------|------|
| 1 | peon | World of Warcraft Peon | 游戏语音/搞笑 | 原始音效 | done |
| 2 | scv | StarCraft SCV | 游戏语音/硬核 | 原始音效 | done |
| 3 | trek | Star Trek | 科幻界面音 | 原始音效 | done |
| 4 | jarvis | Jarvis | AI 语音/科技感 | ElevenLabs TTS | done |
| 5 | jojo | JoJo's Bizarre Adventure | 动漫/热血 | Fish Audio TTS | done |
| 6 | onepiece | One Piece | 动漫/元气 | Fish Audio TTS | done |
| 7 | pikachu | Pikachu | 动漫/可爱 | Fish Audio TTS | done |
| 8 | stevejobs | Steve Jobs | 科技/励志 | TTS | in progress |
| 9 | matrix | The Matrix | 数字音效/赛博朋克 | TBD | todo |
| 10 | keyboard | Mechanical Keyboard | 机械键盘/ASMR | TBD | todo |

### 新增主题方式

在 `assets/` 下建目录，放入音频文件 + `manifest.json`，无需改任何代码。

manifest.json 格式：
```json
{
  "name": "显示名",
  "description": "主题描述",
  "ready": ["file1.mp3"],
  "yes": ["file2.mp3"],
  "what": [],
  "complete": [],
  "error": [],
  "precompact": [],
  "session_end": []
}
```

---

## 插件结构

```
claude-sound-fx/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据
├── hooks/
│   ├── hooks.json               # 7 个 hook 事件注册
│   └── hook.sh                  # 核心脚本（读配置 → 读 manifest → 播放）
├── commands/
│   └── setup.md                 # /sound-fx:setup 交互式配置
├── assets/
│   ├── peon/                    # manifest.json + wav files
│   ├── scv/                     # manifest.json + wav files
│   ├── trek/                    # manifest.json + wav files
│   ├── jarvis/                  # manifest.json + mp3 files
│   ├── jojo/                    # manifest.json + mp3 files (DIO + Jotaro)
│   ├── onepiece/                # manifest.json + mp3 files (Luffy)
│   ├── pikachu/                 # manifest.json + mp3 files
│   ├── stevejobs/               # manifest.json + mp3 files (in progress)
│   └── <new-theme>/             # 新主题只需加目录
├── scripts/
│   ├── generate_voices.py       # Fish Audio TTS 批量生成脚本
│   └── relay.py                 # 远程 SSH relay 服务
├── docs/
│   └── PRD.md                   # 本文件
├── .gitignore
└── README.md
```

---

## 技术要点

- **配置文件**：`~/.claude/sound-fx.local.json`（theme + mode）
- **manifest 驱动**：每个主题目录含 manifest.json 声明事件→文件映射，hook.sh 动态扫描
- **路径解析**：`${CLAUDE_PLUGIN_ROOT}` 环境变量（插件模式）或脚本相对路径（独立模式）
- **音频播放**：macOS `afplay -v <volume>`，支持 wav / mp3
- **远程模式**：非 macOS 通过 `curl → relay.py` 转发到本地播放
- **音量控制**：`CLAUDE_SOUND_VOLUME` 环境变量（0-100）
- **bash 兼容**：macOS 自带 bash 3.x，不用 readarray 等 bash 4+ 特性
- **TTS 生成**：Fish Audio API（日文动漫角色）/ ElevenLabs API（英文角色）

---

## 待办

- [ ] 补充主题：Steve Jobs（in progress）
- [ ] 补充主题：Matrix / Keyboard
- [ ] README.md（安装说明 + 截图 + 主题预览）
- [ ] 测试 `commands/setup.md` 的交互流程
- [ ] 考虑 wav 文件体积，大文件用 Git LFS 或统一转 mp3
- [ ] initial commit + push to GitHub
- [ ] 更新 generate_voices.py 移除 subagent 相关台词
