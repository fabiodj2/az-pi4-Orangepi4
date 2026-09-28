# AZ 1.30 Starter — Pi 4 + HDMI Setup Notes

Working notes for running the **key-free AZ 1.30 starter** on a Raspberry Pi 4
(ARM64, native — no QEMU), with a decrypted cabinet, a USB music library, and
an HDMI monitor.


---

## Orange Pi 4 LTS port: current status

This fork currently contains only `README.md` and `setup-az.sh` at commit
`0db4bbb`. The referenced `az.py`, `controller.py`, `controllers/` and `tools/`
are **not in this repository**. Cloning it does not provide a runnable AZ
installation. Do not run `setup-az.sh` yet; its prerequisite files are absent.

On the Orange Pi 4 LTS, run the read-only inventory:

```bash
bash scripts/preflight.sh
# Once the complete starter source is available elsewhere:
AZ_SOURCE_DIR=/path/to/complete-starter bash scripts/preflight.sh
```

The preflight prints architecture, kernel, page size, board, tools, loaders,
DRM, ALSA and USB devices. It never mounts, installs or prints key contents.
For the porting matrix, gaps and acceptance criteria, see
[docs/matriz-portabilidade.md](docs/matriz-portabilidade.md).

The first integration target is the Orange Pi 4 LTS with Armbian ARM64. QEMU
can test isolated software logic once `az.py` is available, but the generic
ARM64 `virt` machine does not emulate the RK3399 video, audio or GPIO. A
Raspberry Pi 3 is optional for a Pi-specific reproduction, not a requirement.

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

## Setup status for this fork

**Stop here after `bash scripts/preflight.sh`.** This repository does not contain
`az.py`. The firmware and cabinet inputs are also not included. The original
setup commands cannot run from a clean clone of this fork. Do not type
`git clone <repo-url>`: `<repo-url>` was a placeholder, and the shell treats
angle brackets as input redirection. Likewise, `/path/to/cabinet.img`,
`<pi-ip>`, and `/media/drclab/128 GB` in older notes are examples, not paths
verified on your Orange Pi.

The complete public starter is [xsploit/az-starter](https://github.com/xsploit/az-starter),
verified at commit `9a2108a70ca8cdef08988be22add5a469d678d35` (MIT starter glue;
third-party components retain their own licenses). Clone it separately into
this fork's ignored `upstream/` directory and pin the audited revision:

```bash
cd ~/az-pi4-Orangepi4
git clone https://github.com/xsploit/az-starter.git upstream
(cd upstream && git checkout 9a2108a70ca8cdef08988be22add5a469d678d35)
bash scripts/preflight.sh
```

If `upstream/` already exists, inspect it before cloning. The command above
retrieves source only; it does not install dependencies or run the player.
The upstream README offers three setup inputs: an already extracted rootfs,
an official UPD plus a private key config, or a decrypted ISO/CPIO. A decrypted
cabinet is optional for limited startup; its absence prevents a validated full
Source/library path. These inputs are not supplied by either repository.

Until an input is available and the source has been reviewed, **do not run the historical `python3 az.py ...` commands below**. Installing
`xserver-xephyr` only installs a nested X server; it cannot create the missing
AZ launcher or start display `:1` by itself.

---

## Historical Raspberry Pi reference (not runnable from this fork)

The sections below describe a complete starter installation that is **not**
checked into this repository. They are reference material, not an Orange Pi
runbook. Commands require the missing `az.py`, appropriate inputs, and a
working X session.

### Running AZ on HDMI

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
