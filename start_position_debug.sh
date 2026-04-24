#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION="${POSITION_DEBUG_SESSION:-position_debug}"
LOG_DIR="$WS_DIR/log/debug/$(date '+%Y%m%d_%H%M%S')"
FCU_URL="${FCU_URL:-/dev/ttyACM0}"
TGT_SYSTEM="${TGT_SYSTEM:-1}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed or not in PATH." >&2
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already exists." >&2
  echo "Attach with: tmux attach -t $SESSION" >&2
  echo "Or stop it with: tmux kill-session -t $SESSION" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

run_window() {
  local window_name="$1"
  local command="$2"

  tmux new-window -t "$SESSION" -n "$window_name" \
    "cd '$WS_DIR'; echo '[debug] $window_name log: $LOG_DIR/$window_name.log'; $command 2>&1 | tee '$LOG_DIR/$window_name.log'"
}

tmux new-session -d -s "$SESSION" -n mavros \
  "cd '$WS_DIR'; echo '[debug] mavros log: $LOG_DIR/mavros.log'; ./run_position_module.sh mavros fcu_url:=$FCU_URL tgt_system:=$TGT_SYSTEM 2>&1 | tee '$LOG_DIR/mavros.log'"

run_window livox "./run_position_module.sh livox"
run_window fast_lio "sleep 3; ./run_position_module.sh fast_lio"
run_window lio_to_mavros "sleep 5; ./run_position_module.sh lio_to_mavros"
run_window local_position "./run_position_module.sh local_position_monitor"
run_window monitor "./run_position_module.sh monitor"

tmux select-window -t "$SESSION":monitor

echo "Started tmux debug session: $SESSION"
echo "Logs: $LOG_DIR"
echo "Attach with: tmux attach -t $SESSION"

exec tmux attach -t "$SESSION"
