#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POS_SETUP="$WS_DIR/install/setup.bash"
LIVOX_SETUP="$HOME/ws_livox/install/setup.bash"
MAVROS_CONNECT_TIMEOUT="${MAVROS_CONNECT_TIMEOUT:-20}"
MAVROS_PID=""

cleanup() {
  local exit_code=$?

  trap - EXIT

  if [[ -n "$MAVROS_PID" ]] && kill -0 "$MAVROS_PID" 2>/dev/null; then
    kill "$MAVROS_PID" 2>/dev/null || true
    wait "$MAVROS_PID" 2>/dev/null || true
  fi

  exit "$exit_code"
}

wait_for_mavros_connection() {
  local deadline=$((SECONDS + MAVROS_CONNECT_TIMEOUT))

  while (( SECONDS < deadline )); do
    if ! kill -0 "$MAVROS_PID" 2>/dev/null; then
      return 1
    fi

    if timeout 2 ros2 topic echo --once /mavros/state 2>/dev/null | grep -q "connected: true"; then
      echo "MAVROS connected to FCU."
      return 0
    fi

    sleep 1
  done

  return 1
}

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

MAVROS_ARGS=()
for arg in "$@"; do
  case "$arg" in
    fcu_url:=*|tgt_system:=*)
      MAVROS_ARGS+=("$arg")
      ;;
    mavros_namespace:=*)
      MAVROS_ARGS+=("namespace:=${arg#*=}")
      ;;
  esac
done

trap cleanup EXIT

cd "$WS_DIR"

echo "Starting mavros first..."
ros2 launch mavros px4.launch "${MAVROS_ARGS[@]}" &
MAVROS_PID=$!

if ! kill -0 "$MAVROS_PID" 2>/dev/null; then
  wait "$MAVROS_PID"
fi

if ! wait_for_mavros_connection; then
  echo "Warning: MAVROS did not report 'connected: true' within ${MAVROS_CONNECT_TIMEOUT}s." >&2
  echo "Continuing startup anyway, but PX4 may reject external vision until MAVROS/FCU timing is stable." >&2
fi

exec ros2 launch lio_to_mavros position_bringup.launch.py start_mavros:=false "$@"
