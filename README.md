# AZ 1.30 Starter — Pi 4 + HDMI Setup Notes

Working notes for running the **key-free AZ 1.30 starter** on a Raspberry Pi 4
(ARM64, native — no QEMU), with a decrypted cabinet, a USB music library, and
an HDMI monitor.

---

## Hardware

| Component | Details |
|-----------|---------|
| SBC | Raspberry Pi 4 (ARM64 / aarch64) |
| OS | Raspberry Pi OS (Bookworm, 64-bit) |
| Display | HDMI monitor at ≥1280×800 |
| USB | rekordbox-exported stick (e.g. mounted at `/media/drclab/128 GB`) |
| Controller | none required (MIDI-to-click possible via `controller.py`) |

The AZ UI renders at **1280×800**. A 1080p HDMI monitor is ideal — Xephyr opens
as a window on the desktop and can be fullscreened with **Ctrl+Shift+F**.

---

## Inputs required

| File | Purpose | Notes |
|------|---------|-------|
| `XDJAZv130.UPD` | Firmware bundle | From Pioneer's official download page |
| `az-key.conf` | Firmware key | `[XDJ-XZN]` section, `firmware_key = <hex>` |
| `cabinet.img` | **Decrypted** ext4 cabinet | Device auth tokens; not the music library |
| USB stick | rekordbox-exported library | Must contain `PIONEER/rekordbox/export.pdb` |

**Not usable:** the encrypted `cabinet.img` from inside the UPD bundle.
`file` will show `LUKS encrypted file` — the firmware key does not unlock it.

---

## HDMI setup

1. Connect the monitor to the Pi's **HDMI1** port (the one further from the
   USB-C power connector) if HDMI0 is already in use.
2. Boot to the desktop. Raspberry Pi OS auto-detects HDMI and picks a mode.
3. Verify the output:

   ```bash
   xrandr --query | grep connected
   ```

   You should see something like `HDMI-1 connected 1920x1080+0+0`.

4. If the monitor isn't detected, force it:

   ```bash
   xrandr --output HDMI-1 --mode 1920x1080 --auto
   ```

5. When AZ launches, its Xephyr window appears on the HDMI desktop. Drag it to
   the monitor, focus it, and press **Ctrl+Shift+F** for fullscreen.

---

## Full setup — from scratch

```bash
# 1. Clone the starter
git clone <repo-url> ~/az-starter
cd ~/az-starter

# 2. Confirm inputs are present
ls -la XDJAZv130.UPD az-key.conf

# 3. Install host prerequisites
python3 az.py deps
sudo apt-get install -y cryptsetup-bin ffmpeg xxd x11-utils

# 4. Extract firmware and build shims
python3 az.py setup --firmware "XDJAZv130.UPD" --key-config "az-key.conf"

# 5. Import a decrypted cabinet (image file or directory)
python3 az.py cabinet --cabinet "/path/to/decrypted/cabinet.img"

# 6. Verify
python3 az.py doctor
```

After a successful cabinet import, `doctor` **stops printing**
`LIMITED STARTUP: ...`. That is the indicator the cabinet was accepted.

---

## Running AZ on HDMI

### With a USB library (recommended)

```bash
cd ~/az-starter
pkill -f EP147; pkill -f Xephyr
python3 az.py run --usb "/media/drclab/128 GB"
```

Startup output should include:

```
USB1 read-only snapshot: /media/drclab/128 GB. Restart after unplug/replug; automatic hotplug is not implemented.
AZ running on private display :1.
```

The Xephyr window opens on the HDMI desktop. Focus it and press
**Ctrl+Shift+F** to fullscreen. Stop with **Ctrl+C** in the launching terminal.

### Without a USB (limited, empty SOURCE screen)

```bash
python3 az.py run
```

You'll see the dual-deck blue split — that *is* the SOURCE screen, just
unpopulated because no library source is bound.

### Headless verification

```bash
python3 az.py run --headless --seconds 60
ls -la local/logs/
# view: local/logs/screen.png, player.log, xserver.log
```

---

## Screenshots

The AZ display is a **nested Xephyr** at `:1` by default. Capture a frame:

```bash
DISPLAY=:1 ffmpeg -y -loglevel error -f x11grab \
  -video_size 1280x800 -i :1 -frames:v 1 /tmp/az.png
```

If the resolution differs, check:

```bash
DISPLAY=:1 xdpyinfo | grep dimensions
```

Then use that size in the ffmpeg command. Pull the PNG to your PC:

```cmd
scp drclab@<pi-ip>:/tmp/az.png .
```

---

## Cabinet: encrypted vs decrypted

Check with:

```bash
file /path/to/cabinet.img
```

| Output | Meaning | Usable? |
|--------|---------|---------|
| `Linux rev 1.0 ext4 filesystem data ...` | **Decrypted** | ✅ Yes |
| `LUKS encrypted file, ver 1 [aes, xts-plain64, ...]` | **Encrypted** | ❌ No |

A decrypted cabinet typically shows the following contents when mounted:

```
encryption/
├── bpck.dat
├── cacert.pem
├── crl.pem
├── csdk.dat
├── iv.dat
├── key.dat
├── lsdk.dat
├── serverCert.pem
├── serverPrivateKey.pem
└── wlck.dat
```

These are **device auth tokens and TLS certs** — not library data.
The cabinet provides identity; the **USB provides content**.

Mount a decrypted cabinet manually to inspect:

```bash
sudo mkdir -p /mnt/cab
sudo mount -o ro,loop /path/to/cabinet.img /mnt/cab
ls -la /mnt/cab/
sudo umount /mnt/cab
```

Import it into the starter:

```bash
python3 az.py cabinet --cabinet "/path/to/cabinet.img"
```

The previous cabinet is preserved at `local/cabinet-backup-<id>/cabinet`.

---

## USB requirements

`--usb` accepts **only an existing mounted directory**. The validator rejects:

- `/dev/sdX` (device nodes)
- `/` or `$HOME`
- Anything not readable by your user

Find your mount:

```bash
lsblk -o NAME,SIZE,LABEL,FSTYPE,MOUNTPOINT
ls -la /media/drclab/
```

Expected layout on the stick:

```
<USB root>/
└── PIONEER/
    ├── rekordbox/
    │   ├── export.pdb
    │   └── share/
    └── Contents/            (music files)
```

Build this with **rekordbox** on your PC:

1. Open rekordbox
2. Plug in the USB stick
3. Right-click the device in the sidebar → **Export**
4. Drag tracks / playlists onto it
5. Eject safely, plug into the Pi

Without the `PIONEER/rekordbox/` structure, AZ scans the stick, finds nothing,
and the SOURCE screen stays empty.

---

## Controller (optional)

List MIDI devices:

```bash
python3 controller.py devices
```

Learn a button or click coordinate (use the **actual** device path from the
previous command — `midiC1D0` is just an example):

```bash
python3 controller.py learn --device /dev/snd/midiXXXX --key Escape
python3 controller.py learn --device /dev/snd/midiXXXX --click 400 200
python3 controller.py run   --device /dev/snd/midiXXXX
```

Test without hardware by injecting a message into the running AZ display:

```bash
python3 controller.py test --profile controllers/example.json \
  --message '90 24 7f' --send
```

Limits (per `controllers/README.md`):

- Sends UI clicks / keys — not native jog, tempo, faders, FX, pad, LED
- Coordinate mappings depend on which screen is open
- No auto-injection of initialization messages

---

## Troubleshooting

### Xephyr window isn't visible on HDMI

Bring it to the HDMI monitor:

```bash
# from the desktop, move the window with the titlebar
# or force it fullscreen: focus the window, then Ctrl+Shift+F
```

If Xephyr isn't running at all:

```bash
pgrep -a Xephyr
ls /tmp/.X11-unix/
sudo apt-get install -y xserver-xephyr
```

### `Missing Xephyr. Run python3 az.py deps`

Xephyr isn't installed or isn't on PATH:

```bash
sudo apt-get install -y xserver-xephyr
```

`--xserver` takes a **path or command name**, not extra arguments.
Passing `"-screen 800x480"` causes this error.

### `USB path must be an existing mounted directory, not /dev/sdX`

You passed a device node or an unmounted path. Use the mount point:

```bash
python3 az.py run --usb "/media/drclab/128 GB"
```

### Blue split, empty SOURCE screen

- No USB bound → add `--usb`
- USB has no `PIONEER/rekordbox/` → export properly with rekordbox
- Cabinet was rejected → re-run `python3 az.py doctor`

### `SubCpu::writeData ... [Error] failed to write` flood

**Normal.** No hardware sub-controller attached. The docs explicitly say not
to loosen filesystem permissions to silence this.

### `No key available with this passphrase`

You tried to `cryptsetup luksOpen` the encrypted UPD cabinet with
`az-key.conf`. The firmware key is a different key family from the cabinet's
LUKS master key. Use a **decrypted** cabinet instead.

### `Capture area 1280x800 ... outside the screen size`

You're capturing from the wrong display, or Xephyr isn't running. Check:

```bash
pgrep -a Xephyr
ls -la /tmp/.X11-unix/
DISPLAY=:1 xdpyinfo | grep dimensions
```

Use the actual size and display number in the ffmpeg command.

### `REMOTE HOST IDENTIFICATION HAS CHANGED`

The Pi's SSH host key changed (reflash, new OS). If you're sure it's your Pi:

```bash
ssh-keygen -R 192.168.1.10
```

### `No such file or directory: /dev/snd/midiC1D0`

`C1D0` is an example. Run `python3 controller.py devices` and use the real path.

---

## Files and directories

```
~/az-starter/
├── az.py                    launcher + subcommands
├── az-key.conf              firmware key (keep private)
├── XDJAZv130.UPD            original firmware bundle
├── decrypted-cabinet/       imported cabinet contents
├── az-keys-from-unit/       original device tokens (keep private)
├── controllers/             controller README + example profile
├── tools/                   piopack and helpers
└── local/                   generated runtime state (gitignored)
    ├── build/               compiled shims
    ├── cabinet/             active cabinet
    ├── cabinet-backup-*/    previous cabinet snapshots
    ├── extracted/           ISO, rootfs, kernel, initramfs
    ├── logs/                player.log, xserver.log, screen.png
    ├── rootfs/              working copy of firmware rootfs
    └── state/               runtime state
```

---

## Command reference

| Task | Command |
|------|---------|
| Install host deps | `python3 az.py deps` |
| Initial setup | `python3 az.py setup --firmware XDJAZv130.UPD --key-config az-key.conf` |
| Import cabinet | `python3 az.py cabinet --cabinet "/path/to/cabinet.img"` |
| Check prerequisites | `python3 az.py doctor` |
| Run with USB | `python3 az.py run --usb "/media/drclab/128 GB"` |
| Run limited | `python3 az.py run` |
| Headless test | `python3 az.py run --headless --seconds 60` |
| Show logs | `python3 az.py logs` |
| Clean runtime state | `python3 az.py clean` |
| Rebuild shims | `python3 az.py build` |
| Capture screen | `DISPLAY=:1 ffmpeg -y -loglevel error -f x11grab -video_size 1280x800 -i :1 -frames:v 1 /tmp/az.png` |
| Stop AZ | `Ctrl+C` in the run terminal |
| Kill leftovers | `pkill -f EP147; pkill -f Xephyr` |

---

## Security notes

Never commit or share:

- `az-key.conf` (firmware key)
- `az-keys-from-unit/` (device tokens, TLS private key)
- `decrypted-cabinet/` (device identity material)
- Anything from `local/`

`serverPrivateKey.pem` in particular is a TLS private key associated with a
specific physical unit. Treat it as sensitive and never post it publicly.

---

## Limitations (from the official docs)

- Controller-free, silent-audio startup baseline — **not** a full DJ runtime
- No native jog / tempo / fader / FX / pad / LED support in this starter
- No hotplug on USB — restart AZ after replugging
- No autostart / boot hooks installed
- Cabinet unlocks identity, not library content — that comes from USB
- Blue split SOURCE screen with empty cabinet is the *expected* output for
  limited startup, not a bug
