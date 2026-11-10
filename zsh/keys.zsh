# Line-editing keys shared by every machine that mirrors this setup (the Mac sources it too).
# CTRL + U deletes only before the cursor, like bash and macOS (zsh defaults to the whole line)
bindkey '^U' backward-kill-line

# CTRL + Backspace deletes the previous word (terminals send ^H, which zsh binds to deleting one character)
bindkey '^H' backward-kill-word

# CTRL + Delete deletes the next word (CTRL + SHIFT + Backspace sends it too, see hypr/line-editing.lua)
bindkey '^[[3;5~' kill-word

# SUPER + SHIFT + Z redoes (Ghostty sends it as CSI 122;6u, see hypr/line-editing.lua); SUPER + Z undoes via CTRL + _
bindkey '^[[122;6u' redo
