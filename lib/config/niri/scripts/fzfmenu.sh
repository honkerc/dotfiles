#!/bin/bash
# fzf launcher: uses custom rules if available, otherwise falls back to fzf default

# ===== Rules =====
rules=(
    # "dir:$HOME/.config/niri/scripts"
)

# ===== fzf style =====
export FZF_DEFAULT_OPTS="
  --color=spinner:#F2D5CF
  --color=hl:#5af78e
  --color=fg:#C6D0F5
  --color=header:#E78284
  --color=info:#CA9EE6
  --color=pointer:#ff5c57
  --color=marker:#BABBF1
  --color=fg+:#ff5c57
  --color=prompt:#CA9EE6
  --color=hl+:#5af78e
  --color=selected-bg:#51576D
  --color=label:#C6D0F5
  --color=bg+:#414559
  --tabstop=1
  --info=inline-right
  --prompt='  '
  --margin=0%,0%
  --padding=2%,0%,0%,0%
  --ansi
  --layout=reverse
  --border=rounded
"

# ===== Collect as "name\tpath" lines =====
lines=""

for item in "${rules[@]}"; do
    if [[ "$item" == dir:* ]]; then
        dir_path=$(eval echo "${item#dir:}")
        if [[ -d "$dir_path" ]]; then
            while IFS= read -r -d '' file; do
                [[ -f "$file" ]] || continue
                lines+="$(basename "$file")"$'\t'"$file"$'\n'
            done < <(find "$dir_path" -maxdepth 1 -type f -print0 2>/dev/null)
        else
            echo "Warning: directory not found: $dir_path" >&2
        fi

    elif [[ "$item" == desktop:* ]]; then
        dir_path=$(eval echo "${item#desktop:}")
        if [[ -d "$dir_path" ]]; then
            while IFS= read -r -d '' file; do
                name=$(grep -E "^Name=" "$file" | head -n 1 | cut -d= -f2)
                [[ -z "$name" ]] && name=$(basename "$file" .desktop)
                lines+="$name.desktop"$'\t'"$file"$'\n'
            done < <(find "$dir_path" -maxdepth 1 -type f -name "*.desktop" -print0 2>/dev/null)
        else
            echo "Warning: directory not found: $dir_path" >&2
        fi

    else
        lines+="$item"$'\t'"$item"$'\n'
    fi
done

# ===== Decide mode =====
if [ -z "$lines" ]; then
    fallback_mode=true
else
    fallback_mode=false
fi

# ===== Preview script (handles both "name\tpath" and plain path) =====
PREVIEW_SCRIPT=$(mktemp)
cat > "$PREVIEW_SCRIPT" <<'PREVIEW_EOF'
#!/bin/bash
input="$1"

if [[ "$input" == *$'\t'* ]]; then
    cmd=$(printf '%s' "$input" | cut -f2)
else
    cmd="$input"
fi

if [ -z "$cmd" ]; then
    echo "No path"
    exit 0
fi

if [[ "$cmd" != /* ]]; then
    cmd=$(realpath "$cmd" 2>/dev/null || echo "$cmd")
fi

# Action hints
printf '\033[1;36m═══ Actions ═══════════════════════\033[0m\n'
printf '\033[1;33m  Enter\033[0m  run / open\n'
printf '\033[1;33m  Alt-R\033[0m  run with sh\n'
printf '\033[1;33m  Alt-S\033[0m  run with bash\n'
printf '\033[1;33m  Alt-E\033[0m  edit with nvim\n'
printf '\033[1;33m  Alt-V\033[0m  view with less\n'
printf '\033[1;33m  Alt-Y\033[0m  copy path\n'
printf '\033[1;36m═══ Content ═══════════════════════\033[0m\n'

if [ -f "$cmd" ] && file --mime-type -b "$cmd" | grep -q "text/"; then
    bat --style=plain --color=always "$cmd" 2>/dev/null || cat "$cmd"
elif [ -f "$cmd" ]; then
    file "$cmd"
else
    echo "$cmd"
fi
PREVIEW_EOF
chmod +x "$PREVIEW_SCRIPT"
trap 'rm -f "$PREVIEW_SCRIPT"' EXIT

# ===== Select =====
if [ "$fallback_mode" = true ]; then
    result=$(fzf --prompt="  " \
        --preview-window='right,62%,border-left,wrap' \
        --preview "bash $PREVIEW_SCRIPT {}" \
        --expect=alt-r,alt-s,alt-e,alt-v,alt-y \
        2>/dev/null) || true
else
    result=$(printf '%s' "$lines" | fzf --prompt="  " \
        --delimiter='\t' --with-nth=1 \
        --preview-window='right,62%,border-left,wrap' \
        --preview "bash $PREVIEW_SCRIPT {}" \
        --expect=alt-r,alt-s,alt-e,alt-v,alt-y \
        2>/dev/null) || true
fi

[ -z "$result" ] && exit 0

key=$(printf '%s' "$result" | head -n1)
choice=$(printf '%s' "$result" | tail -n1)

[ -z "$choice" ] && exit 0

if [[ "$choice" == *$'\t'* ]]; then
    cmd=$(printf '%s' "$choice" | cut -f2)
else
    cmd=$(realpath "$choice" 2>/dev/null || echo "$choice")
fi

# ===== Dispatch =====
case "$key" in
    "")
        if [[ "$cmd" == *.desktop ]]; then
            if command -v gtk-launch >/dev/null 2>&1; then
                setsid sh -c "gtk-launch $(basename "$cmd" .desktop) >/dev/null 2>&1 &"
            else
                setsid sh -c "xdg-open \"$cmd\" >/dev/null 2>&1 &"
            fi
        elif [ -x "$cmd" ]; then
            setsid sh -c "$cmd >/dev/null 2>&1 &"
        else
            setsid xdg-open "$cmd" >/dev/null 2>&1 &
        fi
        ;;
    alt-r) setsid sh -c "sh \"$cmd\" >/dev/null 2>&1 &" ;;
    alt-s) setsid sh -c "bash \"$cmd\" >/dev/null 2>&1 &" ;;
    alt-e) setsid alacritty -e nvim "$cmd" & ;;
    alt-v) setsid alacritty -e less "$cmd" & ;;
    alt-y)
        if command -v wl-copy >/dev/null 2>&1; then
            printf '%s' "$cmd" | wl-copy
        elif command -v xclip >/dev/null 2>&1; then
            printf '%s' "$cmd" | xclip -selection clipboard
        fi
        notify-send "Path copied" "$cmd" 2>/dev/null
        ;;
esac
