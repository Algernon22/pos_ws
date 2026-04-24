#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POS_SETUP="$WS_DIR/install/setup.bash"
LIVOX_SETUP="$HOME/ws_livox/install/setup.bash"
LIVOX_CONFIG="$HOME/ws_livox/install/livox_ros_driver2/share/livox_ros_driver2/config/MID360_config.json"
MODULE="${1:-}"

shift || true

if [[ -z "$MODULE" ]]; then
  echo "Usage: $0 <mavros|livox|fast_lio|lio_to_mavros|monitor|local_position_monitor> [args...]" >&2
  exit 2
fi

if [[ ! -f "$LIVOX_SETUP" ]]; then
  echo "Missing livox workspace setup: $LIVOX_SETUP" >&2
  exit 1
fi

if [[ ! -f "$POS_SETUP" ]]; then
  echo "Missing pos_ws install setup: $POS_SETUP" >&2
  echo "Run $WS_DIR/build_pos_ws.sh first." >&2
  exit 1
fi

if [[ ! -f "$LIVOX_CONFIG" ]]; then
  echo "Missing Livox MID360 config: $LIVOX_CONFIG" >&2
  exit 1
fi

set +u
source /opt/ros/humble/setup.bash
source "$LIVOX_SETUP"
source "$POS_SETUP"
set -u

cd "$WS_DIR"

case "$MODULE" in
  mavros)
    exec ros2 launch mavros px4.launch "$@"
    ;;
  livox)
    PUBLISH_FREQ="10.0"
    FRAME_ID="livox_frame"

    for arg in "$@"; do
      case "$arg" in
        publish_freq:=*)
          PUBLISH_FREQ="${arg#*=}"
          ;;
        frame_id:=*)
          FRAME_ID="${arg#*=}"
          ;;
      esac
    done

    exec ros2 run livox_ros_driver2 livox_ros_driver2_node --ros-args \
      -p xfer_format:=0 \
      -p multi_topic:=0 \
      -p data_src:=0 \
      -p publish_freq:="$PUBLISH_FREQ" \
      -p output_data_type:=0 \
      -p frame_id:="$FRAME_ID" \
      -p user_config_path:="$LIVOX_CONFIG" \
      -p lvx_file_path:=/tmp/mid360.lvx \
      -p cmdline_input_bd_code:=livox0000000001
    ;;
  fast_lio)
    exec ros2 launch fast_lio mapping.launch.py config_file:=mid360.yaml rviz:=false "$@"
    ;;
  lio_to_mavros)
    exec ros2 launch lio_to_mavros lio_to_mavros.launch.py \
      odom_topic:=/Odometry \
      vision_topic:=/mavros/vision_pose/pose \
      odom_out_topic:=/mavros/odometry/in \
      publish_odom:=false \
      "$@"
    ;;
  monitor)
    exec "$WS_DIR/monitor_position_stack.sh" "$@"
    ;;
  local_position_monitor)
    exec bash -c '
      while true; do
        clear
        echo "MAVROS local_position monitor - $(date \"+%F %T\")"
        echo
        timeout 4 ros2 topic echo --once /mavros/local_position/odom || true
        echo
        timeout 5 ros2 topic hz /mavros/local_position/odom || true
        echo
        echo "Next refresh in 5s. Press Ctrl-C to stop this monitor."
        sleep 5
      done
    '
    ;;
  *)
    echo "Unknown module: $MODULE" >&2
    echo "Expected one of: mavros, livox, fast_lio, lio_to_mavros, monitor, local_position_monitor" >&2
    exit 2
    ;;
esac
