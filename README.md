# 🤖 dont-be-claudeless

> A lightweight context firewall and monochrome status line telemetry bar for the **Claude Code CLI**.

This tool acts as a live diagnostics monitor for your terminal. It tracks your token footprint in real-time, helping you actively prevent your agent from drifting from the "Smart Zone" into the "Dumb Zone" and becoming completely clueless.

---

## 🧠 The Philosophy: Smart Zone vs. Dumb Zone

This tool is explicitly modeled after the context engineering principles demonstrated by developer educator **Matt Pocock** in his engineering workshop, [*Full Walkthrough: Workflow for AI Coding*](https://youtube.com).

### The Core Thesis: "Task, Don't Chat" (Video Timestamp `00:05:22`)
In the workshop, Matt Pocock outlines a critical rule: **Stop using AI agents like standard chatbots.** Long, conversational chat loops inherently bloat the terminal context window, causing a sharp drop-off in agent reasoning:

* **The Smart Zone (< 100k tokens):** When you execute a fresh task or compress history, attention relationships are sharp. The model follows rules perfectly, catches complex architectural dependencies, and writes accurate code.
* **The Dumb Zone (≥ 100k tokens / ~40% Window):** As you chat continuously, attention scales quadratically. Past 100k tokens, the agent drastically slows down, starts making "stupid decisions," violates system constraints, and drains your wallet aggressively.

> *"It doesn't matter whether you're using a 1 million context window or 200k... by around 100k it starts to just get dumber."* — Matt Pocock (Timestamp `00:03:58`).

Instead of "vibe checking" your agent's current state, `dont-be-claudeless` provides hard terminal telemetry. The moment your session reaches the volatile 50% limit, the indicator transforms into an inverted video block warning you: `[!! DUMB !!]`. It's your immediate cue to stop chatting, run `/compact`, commit your files, and move to a clean, isolated task.

---

## 👀 Visual Preview

<img width="1093" height="276" alt="dont-be-claudeless" src="https://github.com/user-attachments/assets/f8837c7b-12e2-4900-9303-539fb2ad926e" />


### 🟢 Normal View (Under 50% Context Window)
`[CLAUDE-3-5-SONNET | my-project] [CTX: ████░░░░░░ 42.5k] [$1.24] [RATE: 12%] [SMART]`

### 🚨 Alert View (50% or Higher Context Window)
`[CLAUDE-3-5-SONNET | my-project] [CTX: ███████░░░ 110.2k] [$3.85] [RATE: 45%] [!! DUMB !!]`

---

## ⚡ Quick Setup Guide

### Step 1: Save the Script
Open your terminal and save the Bash script locally:
```bash
mkdir -p ~/.claude/scripts
nano ~/.claude/scripts/status-line.sh
```
*(Paste the script contents from `scripts/status-line.sh` in this repo into the file, save, and exit).*

### Step 2: Grant File Permissions
Make the script executable by your terminal shell:
```bash
chmod +x ~/.claude/scripts/status-line.sh
```

### Step 3: Link to Claude Settings
Open your global Claude configuration file:
```bash
nano ~/.claude/settings.json
```
Inject the execution command object block into your configuration layout:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/status-line.sh"
  }
}
```

Now, the next time you boot up the agent by running `claude`, your custom context firewall will stay pinned to the terminal footer!

---

## 🛠️ How to Respond to a `[!! DUMB !!]` Alert
When the status line flashes the alert, break out of the loop and implement one of Matt Pocock’s workspace mitigation steps:

1. **Run `/compact`**: This forces Claude to compress the chat string history into a dense summary, instantly buying back thousands of tokens of reasoning headroom.
2. **Task Isolation / Clear Context**: Commit your active tree branches to Git, run `/clear` to reset back to the base system prompt, and pick up a narrow, isolated task from your backlog.
