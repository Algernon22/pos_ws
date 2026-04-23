#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +u
source /opt/ros/humble/setup.bash
source /home/orangepi/ws_livox/install/setup.bash
set -u

cd "$WS_DIR"
colcon build --symlink-install "$@"
