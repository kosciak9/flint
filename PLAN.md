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
| `ags` | **Build from source** | GTK4 shell framework (bar, widgets, notifications) |
| `astal` | **Build from source** | Backend libraries for AGS (system queries, bindings) |
| `astal-notifd` | **Build from source** | Notification daemon library (replaces mako/dunst) |
| `astal-niri` | **Build from source** | Niri IPC bindings (workspaces, windows) - from PR #70 |

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

### AGS (Aylur's GTK Shell)

**Repo:** <https://github.com/aylur/ags>

TypeScript/JSX-based framework for building GTK4 desktop shells. Handles bar, widgets, OSD, and notifications in a React-like syntax.

**Dependencies (Fedora):**

Runtime:

```
gtk4 gtk4-layer-shell gtk3 gtk-layer-shell gjs
```

Build (AGS):

```
npm meson ninja golang gobject-introspection-devel gtk3-devel gtk-layer-shell-devel gtk4-devel gtk4-layer-shell-devel
```

Build (Astal libraries - required by AGS):

```
meson vala valadoc gobject-introspection-devel wayland-protocols-devel json-glib-devel libsoup3-devel
```

**Build steps:**

First build Astal libraries (using PR #70 branch for niri support):

```bash
# Clone from PR #70 branch for native niri IPC support
git clone --branch feat/niri https://github.com/sameoldlab/astal.git
cd astal

# Build astal-io (base I/O library)
cd lib/astal/io
meson setup build --prefix=/usr
meson install -C build

# Build astal3 (GTK3 widgets)
cd ../gtk3
meson setup build --prefix=/usr
meson install -C build

# Build astal4 (GTK4 widgets)
cd ../gtk4
meson setup build --prefix=/usr
meson install -C build

# Build astal-notifd (notification daemon)
cd ../../notifd
meson setup build --prefix=/usr
meson install -C build

# Build astal-niri (niri IPC bindings)
cd ../niri
meson setup build --prefix=/usr
meson install -C build
```

Then build AGS:

```bash
git clone https://github.com/aylur/ags.git
cd ags
npm install
meson setup build --prefix=/usr
meson install -C build
```

**Usage:**

- Initialize project: `ags init -d ~/.config/ags`
- Run project: `ags run ~/.config/ags/app.tsx`
- Generate types: `ags types -u -d ~/.config/ags`

**Features:**

- TypeScript/JSX syntax similar to React/Solid
- Built-in bindings for battery, mpris, network, bluetooth, tray, niri workspaces, etc. via Astal
- Native notification daemon (astal-notifd) - no need for mako/dunst
- Native niri IPC (astal-niri) - workspaces, windows, outputs
- CSS/SCSS styling with GTK4 CSS support
- Hot reload during development

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
- `/etc/xdg/ags/` — AGS shell config (bar, widgets, notifications)

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

- [x] Ironbar vs EWW vs AGS? → **AGS** (build from source, TypeScript/JSX, GTK4)
- [x] Vicinae build dependencies? → Qt6, cmake, ninja, npm
- [x] AGS build deps? → GTK4 stack + Astal libraries + npm/meson
- [x] git-absorb/git-delta? → Distrobox, not base image
- [x] wluma? → Build from source
- [x] openrgb? → Skipped, doesn't work well
- [x] qtkeychain-qt6? → **In Fedora repos** (`qtkeychain-qt6`, `qtkeychain-qt6-devel`)
- [x] rapidfuzz-cpp? → **In Fedora repos** (`rapidfuzz-cpp-devel`, header-only)

---

## AGS Volume/Brightness OSD

AGS provides built-in bindings for WirePlumber (audio) and can query brightness directly. No external scripts needed - everything is handled in TypeScript.

### Example OSD Component (app.tsx)

```tsx
import { Astal } from "ags/gtk4"
import { createBinding } from "ags/binding"
import WirePlumber from "gi://AstalWp"

function OSD() {
  const { TOP } = Astal.WindowAnchor
  const wp = WirePlumber.get_default()
  const speaker = wp?.audio.defaultSpeaker

  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")

  const icon = () => {
    if (muted()) return "󰖁"
    const vol = volume() * 100
    if (vol > 50) return "󰕾"
    if (vol > 0) return "󰖀"
    return "󰕿"
  }

  return (
    <window
      visible={false}
      name="osd"
      anchor={TOP}
      cssClasses={["osd"]}
    >
      <box orientation="vertical">
        <label label={icon} cssClasses={["osd-icon"]} />
        <slider
          value={volume}
          min={0}
          max={1}
          cssClasses={["osd-scale"]}
        />
      </box>
    </window>
  )
}
```

### AGS Style (style.css)

```css
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
}

.osd-scale trough {
  background: #45475a;
  border-radius: 4px;
  min-height: 8px;
}

.osd-scale highlight {
  background: #89b4fa;
  border-radius: 4px;
}

.osd-scale slider {
  all: unset;
}
```

### Niri Keybinds (config.kdl)

AGS can handle media keys directly via Astal bindings, or use `ags request` to trigger OSD:

```kdl
binds {
    XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    XF86MonBrightnessUp { spawn "brightnessctl" "set" "5%+"; }
    XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
}
```

AGS automatically reacts to WirePlumber changes via reactive bindings.

---

## AGS Niri Workspaces

Using `astal-niri` (from PR #70), you get native niri IPC bindings for workspaces, windows, and outputs.

### Example Workspaces Widget

```tsx
import { Astal } from "ags/gtk4"
import { createBinding } from "ags/binding"
import Niri from "gi://AstalNiri"

function Workspaces() {
  const niri = Niri.get_default()
  const workspaces = createBinding(niri, "workspaces")
  const focusedWorkspace = createBinding(niri, "focused-workspace")

  return (
    <box cssClasses={["workspaces"]}>
      {workspaces((ws) =>
        ws.map((workspace) => (
          <button
            cssClasses={[
              "workspace",
              focusedWorkspace()?.id === workspace.id ? "focused" : "",
            ]}
            onClicked={() => niri.focus_workspace(workspace.id)}
          >
            <label label={String(workspace.idx)} />
          </button>
        ))
      )}
    </box>
  )
}
```

### Available Niri Bindings

- `niri.workspaces` - List of all workspaces
- `niri.focused-workspace` - Currently focused workspace
- `niri.windows` - List of all windows
- `niri.focused-window` - Currently focused window
- `niri.outputs` - List of outputs/monitors
- `niri.focus_workspace(id)` - Focus a workspace
- `niri.focus_window(id)` - Focus a window

---

## AGS Notifications

Using `astal-notifd`, AGS acts as its own notification daemon. No need for mako, dunst, or end-rs.

### Example Notification Center

```tsx
import { Astal } from "ags/gtk4"
import { createBinding } from "ags/binding"
import Notifd from "gi://AstalNotifd"

function NotificationPopup() {
  const notifd = Notifd.get_default()
  const notifications = createBinding(notifd, "notifications")

  return (
    <window
      name="notifications"
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      cssClasses={["notification-popup"]}
    >
      <box orientation="vertical" spacing={8}>
        {notifications((notifs) =>
          notifs.slice(0, 5).map((n) => (
            <box cssClasses={["notification"]} orientation="vertical">
              <box cssClasses={["notification-header"]}>
                <label label={n.app_name} cssClasses={["app-name"]} />
                <button
                  cssClasses={["close-btn"]}
                  onClicked={() => n.dismiss()}
                >
                  <label label="×" />
                </button>
              </box>
              <label label={n.summary} cssClasses={["summary"]} />
              <label label={n.body} cssClasses={["body"]} />
            </box>
          ))
        )}
      </box>
    </window>
  )
}
```

### Notification Properties

- `n.app_name` - Application name
- `n.summary` - Notification title
- `n.body` - Notification body text
- `n.app_icon` - Application icon
- `n.image` - Notification image (if any)
- `n.urgency` - low, normal, critical
- `n.actions` - Available actions
- `n.dismiss()` - Dismiss the notification
- `n.invoke(action_id)` - Invoke an action

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
│           └── xdg/ags/
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
