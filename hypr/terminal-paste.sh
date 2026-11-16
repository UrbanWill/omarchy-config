#!/bin/bash
# SUPER + V in a terminal (see bindings.lua). Pastes text with the terminal's
# own CTRL + SHIFT + V. If the clipboard holds an image and no text, sends
# CTRL + V instead, which Claude Code (and other TUIs) read as "paste image".
#
# Over ssh or mosh, CTRL + V would make the remote program read the remote
# clipboard, which doesn't have the image. So when the focused terminal runs an
# interactive ssh or mosh session, the image is copied to /tmp on that host and
# its path is pasted instead. Claude Code attaches a pasted image path as an image.
#
# This runs outside Hyprland on purpose: wl-paste needs the compositor to
# answer, so calling it from the Lua config blocks Hyprland and freezes it.

# Press and release mods + V. Same down/up split as Omarchy's universal
# clipboard, with explicit mods so the still-held SUPER doesn't merge into the chord.
send_v() {
  hyprctl eval "
    hl.dispatch(hl.dsp.send_key_state({ mods = '$1', key = 'V', state = 'down' }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = '$1', key = 'V', state = 'up' }))
    end, { timeout = 50, type = 'oneshot' })
  " >/dev/null
}

# Every process below PID $1.
descendants() {
  ps -e -o pid=,ppid= | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END {
      queue = root
      while (queue != "") {
        n = split(queue, q, " "); queue = ""
        for (i = 1; i <= n; i++) {
          m = split(kids[q[i]], k, " ")
          for (j = 1; j <= m; j++) { print k[j]; queue = queue " " k[j] }
        }
      }
    }'
}

# Turn an interactive ssh command line ($@ without argv[0]) into the arguments
# for a new ssh to the same host. Sets $dest and the array $opts. Fails for a
# ProxyJump hop (-W).
parse_ssh() {
  dest="" opts=()
  local a flag value
  while (($#)); do
    a=$1
    shift
    [[ -n $dest ]] && break
    case $a in
      --) ;;
      -[BbcDEeFIiJLlmOoPpQRSWw]*)
        flag=${a:1:1} value=${a:2}
        if [[ -z $value ]]; then value=$1; shift; fi
        case $flag in
          W) return 1 ;;
          [FiJlopP]) opts+=("-$flag" "$value") ;;
        esac
        ;;
      -*) ;;
      *) dest=$a ;;
    esac
  done
  [[ -n $dest ]]
}

# mosh execs mosh-client with "-# <mosh's own arguments> |", joined by spaces.
# The host is the first word that isn't an option. With --ssh the words of its
# value are indistinguishable from mosh's, so don't guess.
parse_mosh() {
  dest="" opts=()
  [[ $1 == "-# "* && $1 != *--ssh* ]] || return 1
  local -a words
  read -ra words <<<"${1#-# }"
  set -- "${words[@]}"
  while (($#)); do
    case $1 in
      -p | --port | --server | --client | --predict | --family | --bind-server | --experimental-remote-ip) shift ;;
      -*) ;;
      *) dest=$1; return 0 ;;
    esac
    shift
  done
  return 1
}

# The host the focused window is connected to, as $dest and $opts. Ghostty runs
# every window in one process, so a session found under that process may belong
# to another window. mosh marks its window by prefixing the title with "[mosh]";
# plain ssh leaves no mark, so an ssh session counts only when the process has
# one window, or when the title names the host. Anything uncertain is local.
find_remote() {
  local pid=$1 title=$2 proc kind c
  local -a argv
  local -A hosts=() windows=()

  for proc in $(ps -o pid= --ppid "$pid"); do
    c=$(readlink "/proc/$proc/fd/0" 2>/dev/null)
    [[ $c == /dev/pts/* ]] && windows[$c]=1
  done

  kind=ssh
  [[ $title == "[mosh]"* ]] && kind=mosh-client
  for proc in $(descendants "$pid"); do
    # Interactive sessions read a terminal; git's ssh and our uploads read pipes.
    [[ $(readlink "/proc/$proc/fd/0" 2>/dev/null) == /dev/pts/* ]] || continue
    mapfile -d '' -t argv <"/proc/$proc/cmdline" 2>/dev/null || continue
    [[ ${argv[0]##*/} == "$kind" ]] || continue
    if [[ $kind == ssh ]]; then parse_ssh "${argv[@]:1}"; else parse_mosh "${argv[1]}"; fi &&
      hosts[$dest]=$(declare -p dest opts)
  done

  if ((${#hosts[@]} == 1)) && [[ $kind == mosh-client || ${#windows[@]} == 1 ]]; then
    eval "${hosts[*]}"
    return 0
  fi
  for c in "${!hosts[@]}"; do
    if [[ $title == *"${c#*@}"* ]]; then
      eval "${hosts[$c]}"
      return 0
    fi
  done
  return 1
}

# Test hook: `terminal-paste.sh --find-remote PID [TITLE]` prints what would be used.
if [[ $1 == --find-remote ]]; then
  find_remote "$2" "${3:-}" && printf '%q ' ssh "${opts[@]}" "$dest" && echo
  exit
fi

types=$(timeout 1 wl-paste --list-types 2>/dev/null)

if grep -qE '^(text/plain|UTF8_STRING|STRING|TEXT)' <<<"$types" || ! grep -q '^image/' <<<"$types"; then
  send_v "CTRL SHIFT"
  exit
fi

window=$(hyprctl activewindow -j)
if ! find_remote "$(jq -r .pid <<<"$window")" "$(jq -r .title <<<"$window")"; then
  send_v "CTRL"
  exit
fi

type=$(grep -m1 '^image/' <<<"$types")
ext=${type#image/}
[[ $ext =~ ^[a-z0-9]+$ ]] || ext=png
image=$(mktemp --suffix=".$ext")
trap 'rm -f "$image"' EXIT
wl-paste --type "$type" >"$image" && [[ -s $image ]] || exit 1

# ssh keeps the first value given for an option, so these win over the
# session's own command line and ssh_config: no remote command, TTY or forwards.
remote="/tmp/clip-$(date +%Y%m%d-%H%M%S-%N).$ext"
if ! err=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o RemoteCommand=none -o RequestTTY=no -o ClearAllForwardings=yes \
  "${opts[@]}" "$dest" "umask 077 && cat > '$remote'" <"$image" 2>&1); then
  notify-send "Image paste to $dest failed" "$err"
  exit 1
fi

# Paste the path through the clipboard, then put the image back.
printf '%s' "$remote" | wl-copy
send_v "CTRL SHIFT"
sleep 0.5
wl-copy --type "$type" <"$image"
