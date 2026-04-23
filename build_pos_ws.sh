#!/usr/bin/env bash

set -euo pipefail

WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVOX_SETUP="$HOME/ws_livox/install/setup.bash"

set +u
source /opt/ros/humble/setup.bash
source "$LIVOX_SETUP"
set -u

cd "$WS_DIR"
colcon build --symlink-install "$@"
