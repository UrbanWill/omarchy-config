#!/bin/bash
# SUPER + V in a terminal (see bindings.lua). Pastes text with the terminal's
# own CTRL + SHIFT + V. If the clipboard holds an image and no text, sends
# CTRL + V instead, which Claude Code (and other TUIs) read as "paste image".
#
# This runs outside Hyprland on purpose: wl-paste needs the compositor to
# answer, so calling it from the Lua config blocks Hyprland and freezes it.

types=$(timeout 1 wl-paste --list-types 2>/dev/null)

mods="CTRL SHIFT"
if ! grep -qE '^(text/plain|UTF8_STRING|STRING|TEXT)' <<<"$types" && grep -q '^image/' <<<"$types"; then
  mods="CTRL"
fi

# Same down/up split as Omarchy's universal clipboard, with explicit mods so
# the still-held SUPER doesn't merge into the chord.
hyprctl eval "
  hl.dispatch(hl.dsp.send_key_state({ mods = '$mods', key = 'V', state = 'down' }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = '$mods', key = 'V', state = 'up' }))
  end, { timeout = 50, type = 'oneshot' })
" >/dev/null
