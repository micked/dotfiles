#!/usr/bin/env bash
set -e -p pipefail
cat /proc/driver/nvidia/version | grep $(jq -r .nvidiaVersion hm-lime.nvidia-version.json)
home-manager switch --flake ".#lime" -L
