# Claude Code RPG Statusline

[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/hgkim)

An RPG-themed statusline for [Claude Code](https://claude.ai/code) that turns your rate limits into game stats.

```
(0h 42m) ❤️ HP 87% ■■■■■■■■□□  |  🔋 MP 63% ■■■■■■□□□□  |  ✨ Lv.3 37% ■■■■□□□□□□  |  ⚔️ Sonnet4.6  |  🧭 my-project (main)
```

## Stats

| Symbol | Stat | Source |
|--------|------|--------|
| ❤️ HP | 5-hour session limit remaining | Rate limit resets in `Xh Ym` |
| 🔋 MP | Context window remaining | How much conversation space is left |
| ✨/⭐/👑 EXP | 7-day weekly usage + Level | Accumulated across weekly resets |
| ⚔️ | Current model | Shortened display name |
| 🧭 | Directory + git branch | Current working directory |

## Level System

EXP accumulates from your 7-day usage percentage. The threshold to reach the next level increases linearly — **level N requires N+1 EXP** to advance.

- Weekly usage increases add to your cumulative EXP
- Weekly resets don't subtract — progress carries over
- Level-up shows `↑` on the next render, then disappears
- Level data persists in `~/.claude/exp_data.json`
- Max level: **100**

**Example:**
```
Week 1: use 40% → accumulated: 40 → levels up through Lv.1→2 (2), 2→3 (3), ... until threshold not met
Week 2 reset → use 30% → accumulated grows further
```

**Icon milestones:**

| Level | Icon | |
|-------|------|-|
| 1–49  | ✨   | Sparkle |
| 50–99 | ⭐   | Star |
| 100   | 👑   | Crown (max level) |

## Requirements

- [Claude Code](https://claude.ai/code)
- Ruby (pre-installed on macOS; `sudo apt install ruby` on Ubuntu/Debian)

## Installation

**1. Copy the script:**
```bash
cp statusline.rb ~/.claude/statusline-command.rb
```

**2. Add to `~/.claude/settings.json`:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "ruby ~/.claude/statusline-command.rb"
  }
}
```

That's it. The statusline appears at the bottom of every Claude Code response.

## Customization

**Colors** use the [Nord palette](https://www.nordtheme.com/) by default. Change any color in the `module C` block:

```ruby
module C
  BRIGHT_RED     = "\e[38;2;191;97;106m"   # HP bar   — Nord11
  BRIGHT_MAGENTA = "\e[38;2;163;190;140m"  # MP bar   — Nord14
  BRIGHT_YELLOW  = "\e[38;2;235;203;139m"  # EXP bar  — Nord13
  BRIGHT_ORANGE  = "\e[38;2;208;135;112m"  # Level    — Nord12
  BRIGHT_BLUE    = "\e[38;2;129;161;193m"  # Model    — Nord9
  BRIGHT_WHITE   = "\e[38;2;216;222;233m"  # Dir      — Nord4
end
```

**Bar width** (default: 10 blocks = 1 block per 10%):
```ruby
def bar(filled_pct, width: 10, ...)
```

## Reset level data

```bash
rm ~/.claude/exp_data.json
```

The file is recreated on the next Claude Code response starting at Lv.1.

## How it works

Claude Code pipes a JSON blob to the statusline command on every response. The script reads `rate_limits`, `context_window`, `model`, and `cwd` from that JSON and renders the bar using ANSI escape codes.

The level system persists state in `~/.claude/exp_data.json` using atomic writes (temp file → rename) to prevent corruption.
