# Flint

An opinionated custom Fedora Atomic image built on [Universal Blue](https://universal-blue.org/)'s Silverblue, featuring [niri](https://github.com/YaLTeR/niri) as the window manager.

This is my personal daily-driver system with a curated set of software tailored to my workflow.

## What's Included

### Window Manager

- **niri** - Scrollable-tiling Wayland compositor
- **xwayland-satellite** - X11 app compatibility layer

### Login

- **greetd** + **tuigreet** - Minimal TUI login manager
- **fprintd** - Fingerprint authentication

### Shell & Widgets

- **AGS** (Aylur's GTK Shell) - TypeScript/JSX-based bar, widgets, and notifications
- **Astal** libraries including niri IPC bindings

### Launcher

- **Vicinae** - Raycast-like application launcher

### Terminal

- **Ghostty** - GPU-accelerated terminal emulator

### Session Utilities

- **swaybg** - Wallpaper
- **hypridle** / **hyprlock** - Idle management and screen locker
- **wlsunset** - Blue light filter
- **brightnessctl** - Backlight control
- **wl-clipboard** - Clipboard utilities

### Desktop Integration

- **nautilus** - File manager
- **gnome-keyring** - Secrets and credentials storage
- **xdg-desktop-portal** stack - Screen sharing, file pickers, etc.

### CLI Tools

- **zsh** + **starship** - Shell and prompt
- **neovim** - Editor
- **zoxide**, **fzf**, **bat**, **btop** - Modern CLI utilities
- **yadm** - Dotfile management
- **pass** - Password manager
- **trash-cli** - Safe file deletion

### Containers

- **podman-compose** - Container orchestration
- **distrobox** - Development containers (from base image)

### Development

- **caddy** - Fast, multi-platform web server for local dev servers

### Networking

- **tailscale** - VPN mesh
- **syncthing** - File synchronization

## Usage

### Rebase from Fedora Silverblue

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/kosciak/flint:latest
systemctl reboot
```

### Build Locally

```bash
./scripts/build-local.sh
```

## License

MIT
