#!/usr/bin/env ruby
# Claude Code statusLine — RPG style (HP/MP bars)
require 'json'

module C
  RESET          = "\e[0m"
  BOLD           = "\e[1m"
  DIM            = "\e[2m"
  BRIGHT_RED     = "\e[38;2;191;97;106m"   # Nord11 #BF616A rose
  BRIGHT_MAGENTA = "\e[38;2;163;190;140m"  # Nord14 #A3BE8C green
  BRIGHT_YELLOW  = "\e[38;2;235;203;139m"  # Nord13 #EBCB8B amber
  BRIGHT_BLUE    = "\e[38;2;129;161;193m"  # Nord9  #81A1C1 blue
  BRIGHT_WHITE   = "\e[38;2;216;222;233m"  # Nord4  #D8DEE9 snow
  BRIGHT_ORANGE  = "\e[38;2;208;135;112m"  # Nord12 #D08770 aurora orange
end


def bar(filled_pct, width: 10, fill_char: "■", empty_char: "□")
  filled_pct = filled_pct.clamp(0, 100)
  filled = (filled_pct / 100.0 * width).round
  (fill_char * filled) + (empty_char * (width - filled))
end

input = $stdin.read
data  = JSON.parse(input) rescue {}

# --- 5-hour rate limit => HP ---
rate   = data["rate_limits"] || {}
five_h = rate["five_hour"]

if five_h
  hp_pct    = (100 - five_h["used_percentage"].to_f).round.clamp(0, 100)
  resets_at = five_h["resets_at"]
  if resets_at
    secs_left = ((resets_at.to_i - Time.now.to_i)).clamp(0, 99999)
    h = secs_left / 3600
    m = (secs_left % 3600) / 60
    timer_str = "#{C::DIM}(#{h}h #{m}m)#{C::RESET} "
  else
    timer_str = ""
  end
  hp_part   = "#{timer_str}#{C::BRIGHT_RED}❤️ HP#{C::RESET} #{C::BRIGHT_RED}#{C::BOLD}#{hp_pct}%#{C::RESET} #{C::BRIGHT_RED}#{bar(hp_pct)}#{C::RESET}"
else
  hp_part = "#{C::BRIGHT_RED}❤️ HP#{C::RESET} #{C::DIM}---#{C::RESET}"
end

# --- Context Window => MP ---
ctx           = data["context_window"] || {}
remaining_pct = ctx["remaining_percentage"]

if remaining_pct
  mp_rem  = remaining_pct.to_f.round.clamp(0, 100)
  mp_part = "#{C::BRIGHT_MAGENTA}🌿 MP#{C::RESET} #{C::BRIGHT_MAGENTA}#{C::BOLD}#{mp_rem}%#{C::RESET} #{C::BRIGHT_MAGENTA}#{bar(mp_rem)}#{C::RESET}"
else
  mp_part = "#{C::BRIGHT_MAGENTA}🌿 MP#{C::RESET} #{C::DIM}---#{C::RESET}"
end

# --- 7-day rate limit => EXP ---
seven_d = rate["seven_day"]

if seven_d
  exp_pct = seven_d["used_percentage"].to_f.clamp(0, 100).round
  wk_part = "👑 #{C::BRIGHT_YELLOW}EXP#{C::RESET} #{C::BRIGHT_YELLOW}#{C::BOLD}#{exp_pct}%#{C::RESET} #{C::BRIGHT_YELLOW}#{bar(exp_pct)}#{C::RESET}"
else
  wk_part = "👑 #{C::BRIGHT_YELLOW}EXP#{C::RESET} #{C::DIM}---#{C::RESET}"
end

# --- Model badge ---
model_name = data.dig("model", "display_name").to_s
if !model_name.empty?
  short      = model_name.gsub(/Claude\s*/i, "").gsub(/\s+/, "")
  model_part = "#{C::BRIGHT_BLUE}⚔️ #{short}#{C::RESET}"
end

cwd    = data["cwd"].to_s
branch = cwd.empty? ? "" : `git -C "#{cwd}" branch --show-current 2>/dev/null`.strip
dir_str = File.basename(cwd) unless cwd.empty?
dir_str += " (#{branch})" if dir_str && !branch.empty?
dir_part = dir_str ? "#{C::BRIGHT_WHITE}🧭 #{dir_str}#{C::RESET}" : nil

parts = [hp_part, mp_part, wk_part]
parts << model_part if model_part
parts << dir_part if dir_part

print parts.join("  |  ")
