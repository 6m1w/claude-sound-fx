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

2. **Ask Question 1 — Action** using AskUserQuestion:
   - header: "Action"
   - question: "What would you like to do?"
   - multiSelect: false
   - options:
     - label: "Configure (Recommended)", description: "Set up or change your sound effects theme and trigger mode"
     - label: "Update", description: "Re-apply current settings, refresh hooks, and play a test sound"
     - label: "Remove", description: "Completely remove sound effects — deletes configuration file"

3. **If user chose "Update"**:
   - Read the config at `~/.claude/sound-fx.local.json`.
   - If the file does not exist or is empty, tell the user no configuration found and suggest choosing "Configure" instead. Stop here.
   - If config exists, display the current settings summary:
     - Theme: (theme name or "mix")
     - Trigger mode: (full or minimal)
     - Enabled: (true or false)
   - Re-write the same config back to `~/.claude/sound-fx.local.json` (to ensure file integrity).
   - Play a test sound:
     ```bash
     bash ${CLAUDE_PLUGIN_ROOT}/hooks/hook.sh start
     ```
   - Confirm: "Settings verified and hooks refreshed. Everything is working!"
   - **Stop here** (do not continue to further steps).

4. **If user chose "Remove"**:
   - Delete the config file:
     ```bash
     rm -f ~/.claude/sound-fx.local.json
     ```
   - Confirm: "Sound effects have been completely removed. Configuration file deleted."
   - Tell the user: "Run `/sound-fx:setup` anytime to set up sound effects again."
   - **Stop here** (do not continue to further steps).

5. **If user chose "Configure"**, ask **Question 2 — Mode**:
   - header: "Mode"
   - question: "How would you like sound effects configured?"
   - multiSelect: false
   - options:
     - label: "Single Theme (Recommended)", description: "Choose one specific theme to use exclusively"
     - label: "Mix", description: "All 12 themes randomly mixed for maximum variety"
     - label: "Disable All Sounds", description: "Turn off all sound effects"

6. **If user chose "Disable All Sounds"**: Write config and skip to step 10:
   ```json
   {"enabled": false}
   ```

7. **If user chose "Single Theme"**, ask **Question 3 — Theme Group**:
   - header: "Theme"
   - question: "Which theme group?"
   - multiSelect: false
   - options:
     - label: "Jarvis / GLaDOS / Trek / Optimus", description: "Sci-Fi & AI voices and interface sounds"
     - label: "JoJo / One Piece / Pikachu / Doraemon", description: "Anime character voice lines"
     - label: "Peon / SCV / Steve Jobs / Keyboard", description: "Gaming sounds, inspirational voice, ASMR"

8. **Then ask Question 4 — Theme** based on the chosen group:

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

9. **Ask Trigger Mode** (for both Mix and Single Theme):
   - header: "Trigger"
   - question: "How often should sounds play?"
   - multiSelect: false
   - options:
     - label: "Full (Recommended)", description: "All 7 events: start, submit, complete, error, notification, compact, session end"
     - label: "Minimal", description: "Essential only: start, complete, error, notification"

   Map: "Full" → "full", "Minimal" → "minimal"

10. **Write the config** to `~/.claude/sound-fx.local.json`:

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

11. **Confirm** the setup is complete. Show a summary:
   - Mode: Mix / Single (theme name) / Disabled
   - Trigger: Full / Minimal (if applicable)
   - Tell the user they can re-run `/sound-fx:setup` anytime to change settings.

12. **Play a test sound** (skip if Disabled):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/hook.sh start
   ```
