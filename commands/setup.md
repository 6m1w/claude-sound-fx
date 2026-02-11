---
description: "Configure sound effects theme and trigger mode"
allowed-tools: [Read, Write, Bash, AskUserQuestion]
---

# Sound FX Setup

You are configuring the Sound FX plugin for Claude Code. This plugin plays themed sound effects in response to Claude Code events (session start, prompt submit, task complete, error, notification, context compact, session end).

Available themes (12 total):
- **Sci-Fi & AI**: Jarvis (Iron Man), GLaDOS (Portal), Star Trek, Optimus Prime (Transformers)
- **Anime**: JoJo's Bizarre Adventure, One Piece (Luffy), Pikachu, Doraemon
- **Gaming & Other**: WoW Peon, StarCraft SCV, Steve Jobs, Mechanical Keyboard

## Instructions

1. Read the current config file at `~/.claude/sound-fx.local.json` (it may not exist yet). Note the current settings if any.

2. **Ask Question 1 — Mode** using AskUserQuestion:
   - header: "Mode"
   - question: "How would you like sound effects configured?"
   - multiSelect: false
   - options:
     - label: "Single Theme (Recommended)", description: "Choose one specific theme to use exclusively"
     - label: "Mix", description: "All 12 themes randomly mixed for maximum variety"
     - label: "Disable All Sounds", description: "Turn off all sound effects"

3. **If user chose "Disable All Sounds"**: Write config and skip to step 7:
   ```json
   {"enabled": false}
   ```

4. **If user chose "Single Theme"**, ask **Question 2 — Theme Group**:
   - header: "Theme"
   - question: "Which theme group?"
   - multiSelect: false
   - options:
     - label: "Jarvis / GLaDOS / Trek / Optimus", description: "Sci-Fi & AI voices and interface sounds"
     - label: "JoJo / One Piece / Pikachu / Doraemon", description: "Anime character voice lines"
     - label: "Peon / SCV / Steve Jobs / Keyboard", description: "Gaming sounds, inspirational voice, ASMR"

5. **Then ask Question 3 — Theme** based on the chosen group:

   If "Jarvis / GLaDOS / Trek / Optimus":
   - header: "Theme"
   - question: "Which theme?"
   - options:
     - label: "Jarvis", description: "Iron Man JARVIS AI assistant — voice with sci-fi UI effects"
     - label: "GLaDOS", description: "Portal's passive-aggressive AI with dark humor"
     - label: "Star Trek", description: "Classic starship interface beeps and chirps"
     - label: "Optimus Prime", description: "Transformers commander — heroic voice with effects"

   If "JoJo / One Piece / Pikachu / Doraemon":
   - header: "Theme"
   - question: "Which theme?"
   - options:
     - label: "JoJo", description: "DIO and Jotaro iconic voice lines from JoJo's Bizarre Adventure"
     - label: "One Piece", description: "Monkey D. Luffy's energetic voice lines"
     - label: "Pikachu", description: "Pikachu's signature expressions"
     - label: "Doraemon", description: "Doraemon iconic robot cat voice"

   If "Peon / SCV / Steve Jobs / Keyboard":
   - header: "Theme"
   - question: "Which theme?"
   - options:
     - label: "WoW Peon", description: "'Ready to work!' — Warcraft Peon worker sounds"
     - label: "StarCraft SCV", description: "'SCV good to go, sir!' — StarCraft worker sounds"
     - label: "Steve Jobs", description: "Inspirational voice with background effects"
     - label: "Mechanical Keyboard", description: "Satisfying mechanical keyboard ASMR sounds"

   Map theme names to directory names:
   - "Jarvis" → "jarvis", "GLaDOS" → "glados", "Star Trek" → "trek", "Optimus Prime" → "optimus"
   - "JoJo" → "jojo", "One Piece" → "onepiece", "Pikachu" → "pikachu", "Doraemon" → "doraemon"
   - "WoW Peon" → "peon", "StarCraft SCV" → "scv", "Steve Jobs" → "jobs", "Mechanical Keyboard" → "keyboard"

6. **Ask Trigger Mode** (for both Mix and Single Theme):
   - header: "Trigger"
   - question: "How often should sounds play?"
   - multiSelect: false
   - options:
     - label: "Full (Recommended)", description: "All 7 events: start, submit, complete, error, notification, compact, session end"
     - label: "Minimal", description: "Essential only: start, complete, error, notification"

   Map: "Full" → "full", "Minimal" → "minimal"

7. **Write the config** to `~/.claude/sound-fx.local.json`:

   For Mix mode:
   ```json
   {"theme": "mix", "mode": "<full|minimal>", "enabled": true}
   ```

   For Single Theme:
   ```json
   {"theme": "<directory_name>", "mode": "<full|minimal>", "enabled": true}
   ```

   For Disable:
   ```json
   {"enabled": false}
   ```

8. **Confirm** the setup is complete. Show a summary:
   - Mode: Mix / Single (theme name) / Disabled
   - Trigger: Full / Minimal (if applicable)
   - Tell the user they can re-run `/sound-fx:setup` anytime to change settings.

9. **Play a test sound** (skip if Disabled):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/hook.sh start
   ```
