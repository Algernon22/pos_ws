#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POS_SETUP="$WS_DIR/install/setup.bash"
LIVOX_SETUP="$HOME/ws_livox/install/setup.bash"

set +u
source /opt/ros/humble/setup.bash
source "$LIVOX_SETUP"
source "$POS_SETUP"
set -u

watch_topic_once() {
  local topic="$1"
  local timeout_sec="${2:-4}"

  if timeout "$timeout_sec" ros2 topic echo --once "$topic" >/tmp/position_stack_topic_check 2>/tmp/position_stack_topic_check_err; then
    echo "[OK]   $topic"
  else
    echo "[MISS] $topic"
  fi
}

show_topic_hz() {
  local topic="$1"
  local duration_sec="${2:-5}"

  echo
  echo "---- hz: $topic (${duration_sec}s) ----"
  timeout "$duration_sec" ros2 topic hz "$topic" || true
}

while true; do
  clear
  echo "Position stack monitor - $(date '+%F %T')"
  echo
  echo "Topic availability:"
  watch_topic_once /livox/lidar 4
  watch_topic_once /livox/imu 4
  watch_topic_once /Odometry 4
  watch_topic_once /mavros/vision_pose/pose 4
  watch_topic_once /mavros/local_position/odom 4
  watch_topic_once /mavros/state 4

  echo
  echo "MAVROS state:"
  timeout 4 ros2 topic echo --once /mavros/state || true

  echo
  echo "MAVROS local position:"
  timeout 4 ros2 topic echo --once /mavros/local_position/odom || true

  show_topic_hz /livox/lidar 5
  show_topic_hz /livox/imu 5
  show_topic_hz /Odometry 5
  show_topic_hz /mavros/vision_pose/pose 5
  show_topic_hz /mavros/local_position/odom 5

  echo
  echo "Next refresh in 15s. Press Ctrl-C to stop this monitor."
  sleep 15
done
