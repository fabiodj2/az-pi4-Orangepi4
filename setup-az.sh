#!/usr/bin/env bash
# setup-az.sh — Full AZ 1.30 starter setup on Raspberry Pi (ARM64) over HDMI
# Run from ~/az-starter after cloning the repo.
# Requires: XDJAZv130.UPD, az-key.conf, and a decrypted cabinet (optional but recommended).

set -euo pipefail

# ---------- CONFIG (edit these) ----------
PROJECT_DIR="$HOME/az-starter"
FIRMWARE="$PROJECT_DIR/XDJAZv130.UPD"
KEYCONF="$PROJECT_DIR/az-key.conf"
CABINET_SRC="${CABINET_SRC:-}"          # optional: /path/to/decrypted/cabinet.img or dir
USB_MOUNT="${USB_MOUNT:-/media/drclab/128 GB}"
# -----------------------------------------

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m!! %s\033[0m\n'  "$*"; }
die()  { printf '\n\033[1;31mXX %s\033[0m\n'  "$*"; exit 1; }

cd "$PROJECT_DIR" || die "Project dir not found: $PROJECT_DIR"

# ---------- 1. Host dependencies ----------
log "Installing host prerequisites"
python3 az.py deps || warn "deps step reported issues; continuing"

log "Ensuring cryptsetup, ffmpeg, xxd, x11-utils are present"
sudo apt-get update -y
sudo apt-get install -y cryptsetup-bin ffmpeg xxd x11-utils

# ---------- 2. HDMI check ----------
log "Checking HDMI output"
if command -v xrandr >/dev/null 2>&1; then
  xrandr --query | grep -E " connected" || warn "No connected display detected on xrandr."
fi

# ---------- 3. Firmware extraction + shim build ----------
[ -f "$FIRMWARE" ] || die "Firmware not found: $FIRMWARE"
[ -f "$KEYCONF" ]  || die "Key config not found: $KEYCONF"

log "Running setup: extract firmware, build shims"
python3 az.py setup --firmware "$FIRMWARE" --key-config "$KEYCONF"

# ---------- 4. Cabinet (optional) ----------
if [ -n "$CABINET_SRC" ]; then
  if [ -f "$CABINET_SRC" ]; then
    log "Mounting cabinet image read-only"
    sudo mkdir -p /mnt/azcab
    sudo mount -o ro,loop "$CABINET_SRC" /mnt/azcab

    log "Copying cabinet contents to a working directory"
    mkdir -p "$PROJECT_DIR/decrypted-cabinet"
    sudo cp -a /mnt/azcab/. "$PROJECT_DIR/decrypted-cabinet/"
    sudo chown -R "$USER:$USER" "$PROJECT_DIR/decrypted-cabinet"
    sudo umount /mnt/azcab

    CABINET_PATH="$PROJECT_DIR/decrypted-cabinet"
  elif [ -d "$CABINET_SRC" ]; then
    CABINET_PATH="$CABINET_SRC"
  else
    die "CABINET_SRC is neither file nor directory: $CABINET_SRC"
  fi

  log "Importing cabinet: $CABINET_PATH"
  python3 az.py cabinet --cabinet "$CABINET_PATH"
else
  warn "CABINET_SRC not set — setup will remain in LIMITED STARTUP mode."
fi

# ---------- 5. Verify ----------
log "Running doctor"
python3 az.py doctor

# ---------- 6. Done ----------
cat <<EOF

$(printf '\033[1;32mSetup complete.\033[0m')

Start AZ on the HDMI display with the USB library:

  cd $PROJECT_DIR
  pkill -f EP147; pkill -f Xephyr
  python3 az.py run --usb "$USB_MOUNT"

Xephyr opens as a window on the HDMI desktop.
Focus it and press Ctrl+Shift+F to fullscreen.

Stop with Ctrl+C.

Logs:       $PROJECT_DIR/local/logs/
Screenshot: DISPLAY=:1 ffmpeg -y -loglevel error -f x11grab -video_size 1280x800 -i :1 -frames:v 1 /tmp/az.png
EOF
```

Make executable and run:

```bash
chmod +x ~/az-starter/setup-az.sh
CABINET_SRC="$HOME/az-starter/pc-cabinet.img" ./setup-az.sh
