#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POS_SETUP="$WS_DIR/install/setup.bash"
LIVOX_SETUP="$HOME/ws_livox/install/setup.bash"

if [[ ! -f "$LIVOX_SETUP" ]]; then
  echo "Missing livox workspace setup: $LIVOX_SETUP" >&2
  exit 1
fi

if [[ ! -f "$POS_SETUP" ]]; then
  echo "Missing pos_ws install setup: $POS_SETUP" >&2
  echo "Run $WS_DIR/build_pos_ws.sh first." >&2
  exit 1
fi

set +u
source /opt/ros/humble/setup.bash
source "$LIVOX_SETUP"
source "$POS_SETUP"
set -u

cd "$WS_DIR"
exec ros2 launch lio_to_mavros position_bringup.launch.py "$@"
