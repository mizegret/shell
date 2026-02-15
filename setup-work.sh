#!/usr/bin/env bash
set -euo pipefail

DIRS=(
  "$HOME/workspace/dotfiles"
  "$HOME/workspace/neovim"
  "$HOME/workspace/shell"
)

# Keep the DIRS definition above this block.
# Example:
# DIRS=(
#   "$HOME/workspace/foo"
#   "$HOME/workspace/bar"
# )

SESSION="work"

if [[ -z "${DIRS+x}" ]]; then
  echo "DIRS is not set. Define DIRS in setup-work.sh."
  exit 1
fi

if [[ ${#DIRS[@]} -eq 0 ]]; then
  echo "DIRS is empty. Add at least one directory."
  exit 1
fi

for i in "${!DIRS[@]}"; do
  dir="${DIRS[$i]}"
  if [[ "$dir" == "~" || "$dir" == "~/"* ]]; then
    dir="${dir/#\~/$HOME}"
    DIRS[$i]="$dir"
  fi
  if [[ ! -d "$dir" ]]; then
    echo "Directory not found: $dir"
    exit 1
  fi
done

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found."
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

first_dir="${DIRS[0]}"
first_name="$(basename "$first_dir")"

tmux new-session -d -s "$SESSION" -n "$first_name" -c "$first_dir"

create_layout() {
  local target_window="$1"
  local dir="$2"

  # Match prefix+g in ~/.tmux.conf
  tmux kill-pane -a -t "${target_window}.0"
  tmux split-window -h -t "${target_window}.0" -c "$dir"
  tmux split-window -v -t "${target_window}.1" -c "$dir"
  tmux select-pane -t "${target_window}.0"
}

create_layout "${SESSION}:0" "$first_dir"

for dir in "${DIRS[@]:1}"; do
  name="$(basename "$dir")"
  win_id="$(tmux new-window -t "$SESSION" -n "$name" -c "$dir" -P -F '#I')"
  create_layout "${SESSION}:${win_id}" "$dir"
done

if [[ -z "${TMUX:-}" ]]; then
  tmux attach -t "$SESSION"
else
  tmux switch-client -t "$SESSION"
fi
