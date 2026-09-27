#!/usr/bin/env bash
# Read-only host and input assessment. No sudo, mounts, installs or key disclosure.
set -u
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${AZ_SOURCE_DIR:-$root/upstream}
firmware=${AZ_FIRMWARE:-}
cabinet=${AZ_CABINET:-}
status=0
check() { printf '%-33s %s\n' "$1" "$2"; }
check 'Architecture' "$(uname -m)"
check 'Kernel' "$(uname -r)"
check 'Page size' "$(getconf PAGESIZE)"
check 'OS' "$(. /etc/os-release; printf '%s %s' "$ID" "$VERSION_ID")"
if [[ -r /proc/device-tree/model ]]; then check 'Board model' "$(tr -d '\0' </proc/device-tree/model)"; else check 'Board model' unavailable; fi
if [[ $(uname -m) != aarch64 ]]; then check 'Target' 'NOT Orange Pi ARM64 host'; status=1; fi
if [[ -f "$source_dir/az.py" ]]; then check 'az.py' 'present'; else check 'az.py' "MISSING in $source_dir"; status=1; fi
for bin in python3 Xephyr Xvfb xrandr ffmpeg file lsblk; do
  if command -v "$bin" >/dev/null; then check "$bin" "$(command -v "$bin")"; else check "$bin" 'missing'; fi
done
for path in /lib/ld-linux-aarch64.so.1 /lib/ld-linux.so.3 /lib/ld-linux-armhf.so.3; do
  [[ ! -e "$path" ]] || check "loader $path" present
done
if [[ -n "$firmware" ]]; then
  if [[ -f "$firmware" ]]; then check 'Firmware format' "$(file -b "$firmware")"; else check 'Firmware' 'specified path absent'; status=1; fi
fi
if [[ -n "$cabinet" ]]; then
  if [[ -f "$cabinet" ]]; then check 'Cabinet format' "$(file -b "$cabinet")"; else check 'Cabinet' 'specified path absent'; status=1; fi
fi
check 'DRM nodes' "$(find /dev/dri -maxdepth 1 -name 'card*' -printf '%f ' 2>/dev/null || true)"
check 'ALSA cards' "$(awk -F: '/^[[:space:]]*[0-9]+ \[/{print $1}' /proc/asound/cards 2>/dev/null | xargs || true)"
check 'X display' "${DISPLAY:-unset}"
check 'USB storage' "$(lsblk -dn -o NAME,TRAN 2>/dev/null | awk '$2=="usb"{print $1}' | xargs || true)"
exit "$status"
