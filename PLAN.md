# `flint`

> Custom Fedora Silverblue + Niri Image

## Overview

BlueBuild-based custom Fedora Atomic image with niri as the window manager.

---

## Core WM Stack

| Package | Source | Notes |
|---------|--------|-------|
| `niri` | COPR: `yalter/niri` | Scrollable-tiling Wayland compositor |
| `xwayland-satellite` | Fedora repos | X11 app compatibility |

## Login

| Package | Source | Notes |
|---------|--------|-------|
| `greetd` | Fedora repos | Minimal login manager daemon |
| `tuigreet` | Fedora repos | TUI greeter for greetd |

## Bar/Widgets

| Package | Source | Notes |
|---------|--------|-------|
| `eww` | **Build from source** | Widgets, bar, OSD (via custom widgets) |
| `eww-niri-workspaces` | **Build from source** | Feeds niri workspace info to EWW |
| `end-rs` | **Build from source** | EWW notification daemon |

## Launcher

| Package | Source | Notes |
|---------|--------|-------|
| `vicinae` | **Build from source** | C++/Qt Raycast-like launcher |

## Terminal

| Package | Source | Notes |
|---------|--------|-------|
| `ghostty` | **Build from source** | Fast GPU-accelerated terminal (Zig) |

## Session Utilities

| Package | Source | Notes |
|---------|--------|-------|
| `swaybg` | Fedora repos | Wallpaper |
| `hypridle` | Terra repo | Idle management (lock, screen off, suspend) |
| `hyprlock` | Terra repo | GPU-accelerated screen locker with blur, fingerprint |
| `wlsunset` | Fedora repos | Blue light filter |
| `wluma` | Build from source | Adaptive brightness (Rust) |
| `brightnessctl` | Fedora repos | Backlight control |
| `wl-clipboard` | Fedora repos | Wayland clipboard (`wl-copy`/`wl-paste`) |

## Shell & CLI Tools

| Package | Source | Notes |
|---------|--------|-------|
| `zsh` | Fedora repos | Shell |
| `starship` | Fedora repos | Prompt |
| `zoxide` | Fedora repos | Smart cd |
| `fzf` | Fedora repos | Fuzzy finder |
| `bat` | Fedora repos | Better cat |
| `btop` | Fedora repos | Resource monitor |
| `neovim` | Fedora repos | Editor |
| `yadm` | Fedora repos | Dotfile manager |
| `trash-cli` | Fedora repos | Safe rm |
| `pass` | Fedora repos | Password manager |

## Git

| Package | Source | Notes |
|---------|--------|-------|
| `git` | Fedora repos | Core only, extras in distrobox |

## Containers

| Package | Source | Notes |
|---------|--------|-------|
| `podman-compose` | Fedora repos | |
| `distrobox` | Fedora repos | |

## Networking & Sync

| Package | Source | Notes |
|---------|--------|-------|
| `tailscale` | Fedora repos / COPR | VPN mesh |
| `syncthing` | Fedora repos | File sync |

---

## Build from Source

### Vicinae

**Repo:** <https://github.com/vicinaehq/vicinae>

**Dependencies (Fedora):**

Runtime:

```
qt6-qtbase qt6-qtsvg qt6-qt5compat qtkeychain-qt6 nodejs
```

Build:

```
cmake ninja-build git jq npm gcc-c++ qt6-qtbase-devel qt6-qtsvg-devel qt6-qt5compat-devel qtkeychain-qt6-devel rapidfuzz-cpp-devel
```

**Build steps:**

```bash
git clone https://github.com/vicinaehq/vicinae.git
cd vicinae
mkdir build && cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  ..
ninja
# ninja install (or DESTDIR= for packaging)
```

### EWW

**Repo:** <https://github.com/elkowar/eww>

**Dependencies (Fedora):**

Runtime:

```
gtk3 gtk-layer-shell pango gdk-pixbuf2 libdbusmenu-gtk3 cairo glib2
```

Build:

```
rust cargo gcc gtk3-devel gtk-layer-shell-devel pango-devel gdk-pixbuf2-devel libdbusmenu-gtk3-devel cairo-devel glib2-devel
```

**Build steps:**

```bash
git clone https://github.com/elkowar/eww.git
cd eww
cargo build --release --no-default-features --features=wayland
install -Dm755 target/release/eww /usr/bin/eww
```

---

### eww-niri-workspaces

**Repo:** <https://github.com/druskus20/eww-niri-workspaces>

Helper that outputs niri workspace info as JSON for EWW consumption.

**Dependencies (Fedora):**

```
rust cargo
```

**Build steps:**

```bash
git clone https://github.com/druskus20/eww-niri-workspaces.git
cd eww-niri-workspaces
cargo build --release
install -Dm755 target/release/eww-niri-workspaces /usr/bin/eww-niri-workspaces
```

---

### end-rs (EWW Notification Daemon)

**Repo:** <https://github.com/Dr-42/end-rs>

Notification daemon that renders notifications via EWW widgets.

**Dependencies (Fedora):**

```
rust cargo dbus-devel
```

**Build steps:**

```bash
git clone https://github.com/Dr-42/end-rs.git
cd end-rs
cargo build --release
install -Dm755 target/release/end-rs /usr/bin/end-rs
```

**Usage:**

- Autostart daemon: `end-rs daemon`
- Generate EWW config template: `end-rs generate all`
- Config at `~/.config/end-rs/config.toml`

---

### Wluma

**Repo:** <https://github.com/maximbaz/wluma>

**Dependencies (Fedora):**

```
rust cargo vulkan-devel libdrm-devel wayland-devel
```

**Build steps:**

```bash
git clone https://github.com/maximbaz/wluma.git
cd wluma
cargo build --release
install -Dm755 target/release/wluma /usr/bin/wluma
```

---

### Ghostty

**Repo:** <https://github.com/ghostty-org/ghostty>

GPU-accelerated terminal emulator. Requires Zig 0.13.x (not newer).

**Dependencies (Fedora):**

```
gtk4-devel libadwaita-devel gtk4-layer-shell-devel gettext
```

**Build steps:**

```bash
# Download Zig 0.13.0 (required version)
wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
tar xf zig-linux-x86_64-0.13.0.tar.xz

# Download ghostty source tarball (not git clone)
wget https://release.files.ghostty.org/1.1.3/ghostty-1.1.3.tar.gz
tar xf ghostty-1.1.3.tar.gz
cd ghostty-1.1.3

# Build
../zig-linux-x86_64-0.13.0/zig build -Doptimize=ReleaseFast

# Install
install -Dm755 zig-out/bin/ghostty /usr/bin/ghostty
cp -r zig-out/share/* /usr/share/
```

**Note:** Use source tarball, not git clone - tarballs include preprocessed files.

---

## COPRs and Repos to Enable

```yaml
# In BlueBuild recipe.yml
modules:
  - type: copr
    repos:
      - yalter/niri  # official - maintained by niri author
```

**Terra repo** (for hyprlock/hypridle with latest Hyprland ecosystem deps):
```bash
curl -fsSL "https://terra.fyralabs.com/terra.repo" -o /etc/yum.repos.d/terra.repo
```

---

## Default Configs to Bake In

Place in `files/usr/etc/` (copied to `/etc/` on boot):

- `/etc/greetd/config.toml` — greetd config pointing to tuigreet + niri
- `/etc/niri/config.kdl` — System-wide niri defaults
- `/etc/hypr/hypridle.conf` — Idle management (5m lock, 10m screen off, 30m suspend)
- `/etc/hypr/hyprlock.conf` — Lock screen (blur, clock, fingerprint)
- `/etc/xdg/eww/` — EWW widgets and config

---

## Troubleshooting

### Java/Swing Apps (Ghidra, JetBrains, etc.)

Java GUI apps may have issues on niri via xwayland-satellite. Fix with environment variables:

```bash
# Add to ~/.bashrc or ~/.zshrc
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit

# If still broken, force X11 backend
export GDK_BACKEND=x11
```

Alternatively, set per-app in a wrapper script or `.desktop` file.

---

## Open Questions

All resolved:

- [x] Ironbar vs EWW? → **EWW** (build from source)
- [x] Vicinae build dependencies? → Qt6, cmake, ninja, npm
- [x] EWW build deps? → GTK3 stack + Rust
- [x] eww-niri-workspaces? → Yes, build from source
- [x] git-absorb/git-delta? → Distrobox, not base image
- [x] wluma? → Build from source
- [x] openrgb? → Skipped, doesn't work well
- [x] qtkeychain-qt6? → **In Fedora repos** (`qtkeychain-qt6`, `qtkeychain-qt6-devel`)
- [x] rapidfuzz-cpp? → **In Fedora repos** (`rapidfuzz-cpp-devel`, header-only)

---

## EWW Volume/Brightness OSD

Custom EWW widgets + scripts for OSD. No external daemon needed.

### Scripts

**~/.local/bin/volume.sh**

```bash
#!/bin/bash
case "$1" in
  up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac

VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "true" || echo "false")

eww update volume_value="$VOL" volume_muted="$MUTED"
eww open osd --duration 1500ms
```

**~/.local/bin/brightness.sh**

```bash
#!/bin/bash
case "$1" in
  up)   brightnessctl set 5%+ ;;
  down) brightnessctl set 5%- ;;
esac

BRIGHT=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
eww update brightness_value="$BRIGHT"
eww open osd --duration 1500ms
```

### EWW Widget (eww.yuck)

```lisp
(defvar volume_value 50)
(defvar volume_muted false)
(defvar brightness_value 50)

(defwidget osd-slider [value icon]
  (box :class "osd-container" :orientation "v" :space-evenly false
    (label :class "osd-icon" :text icon)
    (scale :class "osd-scale"
           :orientation "h"
           :min 0 :max 100
           :value value)))

(defwidget osd []
  (box :class "osd" :orientation "v" :space-evenly false
    (osd-slider :value volume_value 
                :icon {volume_muted ? "󰖁" : 
                       volume_value > 50 ? "󰕾" : 
                       volume_value > 0 ? "󰖀" : "󰕿"})
    (osd-slider :value brightness_value :icon "󰃠")))

(defwindow osd
  :monitor 0
  :geometry (geometry :x "0%" :y "80%" :anchor "center")
  :stacking "overlay"
  :exclusive false
  (osd))
```

### EWW Style (eww.scss)

```scss
.osd {
  background: rgba(30, 30, 46, 0.9);
  border-radius: 12px;
  padding: 16px 24px;
  min-width: 200px;
}

.osd-icon {
  font-size: 24px;
  color: #cdd6f4;
  margin-bottom: 8px;
}

.osd-scale {
  min-width: 180px;
  min-height: 8px;
  
  trough {
    background: #45475a;
    border-radius: 4px;
    min-height: 8px;
  }
  
  highlight {
    background: #89b4fa;
    border-radius: 4px;
  }
  
  slider { all: unset; }
}
```

### Niri Keybinds (config.kdl)

```kdl
binds {
    XF86AudioRaiseVolume { spawn "~/.local/bin/volume.sh" "up"; }
    XF86AudioLowerVolume { spawn "~/.local/bin/volume.sh" "down"; }
    XF86AudioMute { spawn "~/.local/bin/volume.sh" "mute"; }
    XF86MonBrightnessUp { spawn "~/.local/bin/brightness.sh" "up"; }
    XF86MonBrightnessDown { spawn "~/.local/bin/brightness.sh" "down"; }
}
```

---

## Build Pipeline

### Repo Structure

```
niri-silverblue/
├── Containerfile
├── build-packages.sh     # builder stage script
├── files/
│   └── usr/
│       └── etc/
│           ├── greetd/config.toml
│           ├── niri/config.kdl
│           └── xdg/eww/
└── .github/
    └── workflows/
        └── build.yml
```

### Multi-stage Build

```
┌─────────────────────────────────────────────────────┐
│ Stage 1: Builder (FROM fedora:41)                   │
│ - Install build deps (rust, cargo, meson, zig...)   │
│ - Build 6 packages from source                      │
│ - Output binaries to /build/out                     │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ Stage 2: Final (FROM ublue-os/silverblue-main)      │
│ - Enable COPRs                                      │
│ - rpm-ostree install Fedora packages                │
│ - COPY --from=builder binaries                      │
│ - COPY config files                                 │
│ - ostree container commit                           │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
              Push to GHCR via GitHub Actions
```

### Deployment

**Rebase existing Silverblue:**

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/youruser/niri-silverblue:latest
```

---

## Bootable USB Generation

Use `bootc-image-builder` to convert the OCI image to a bootable ISO:

```bash
podman run --rm -it --privileged \
  -v ./output:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso \
  ghcr.io/youruser/niri-silverblue:latest
```

Then flash to USB:

```bash
sudo dd if=output/image.iso of=/dev/sdX bs=4M status=progress
```

---

## References

- [BlueBuild docs](https://blue-build.org/)
- [awesome-niri](https://github.com/Vortriz/awesome-niri)
- [niri wiki](https://yalter.github.io/niri/)
- [cyrneko/ublue-niri](https://github.com/cyrneko/ublue-niri)

---

## To consider

- [ ] sticky windows across workspaces -  <https://github.com/probeldev/niri-float-sticky>
- [ ] annotate your screen - <https://github.com/Treeniks/chameleos>
