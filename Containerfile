# =============================================================================
# Flint - Custom Fedora Atomic + Niri Image
# =============================================================================
# Multi-stage build with per-package dependency installation for better caching:
#   Stage 0 (ctx)     - Copy local files/scripts into build context
#   Stage 1 (builder) - Build packages from source (split for caching)
#   Stage 2 (final)   - Assemble final image on ublue-os base
# =============================================================================

ARG FEDORA_VERSION=43
ARG UBLUE_IMAGE=ghcr.io/ublue-os/base-main

# =============================================================================
# Stage 0: Context - copy local files
# =============================================================================
FROM scratch AS ctx
COPY files/ /files/
COPY scripts/ /scripts/

# =============================================================================
# Stage 1: Builder - compile packages from source
# =============================================================================
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS builder

# Create output directories
RUN mkdir -p /build/{src,out/bin,out/share,out/lib64}
WORKDIR /build/src

# -----------------------------------------------------------------------------
# Base build tools (shared by all)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    gcc gcc-c++ make git curl wget tar xz pkg-config \
    && dnf clean all

# -----------------------------------------------------------------------------
# Build Astal libraries (required by AGS)
# Using PR #70 branch for native niri support
# Dependencies: astal-io -> astal3/astal4 -> feature libs -> notifd/niri
# Feature libs: wireplumber, tray, battery, network, mpris, bluetooth,
#               powerprofiles, apps
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    meson vala valadoc gobject-introspection-devel wayland-protocols-devel \
    gtk3-devel gtk-layer-shell-devel \
    gtk4-devel gtk4-layer-shell-devel \
    json-glib-devel libsoup3-devel \
    gdk-pixbuf2-devel \
    # Additional deps for Astal feature libraries
    wireplumber-devel \
    NetworkManager-libnm-devel \
    && dnf clean all

# Build appmenu-glib-translator (required by AstalTray)
RUN git clone --depth 1 https://github.com/rilian-la-te/vala-panel-appmenu.git && \
    cd vala-panel-appmenu/subprojects/appmenu-glib-translator && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig && \
    rm -rf /build/src/vala-panel-appmenu

# Clone astal from PR #70 branch (feat/niri) for native niri IPC support
RUN git clone --depth 1 --branch feat/niri https://github.com/sameoldlab/astal.git

# Build astal-io (base I/O library)
RUN cd astal/lib/astal/io && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

# Build astal3 (GTK3 widgets)
RUN cd astal/lib/astal/gtk3 && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

# Build astal4 (GTK4 widgets)
RUN cd astal/lib/astal/gtk4 && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

# Build Astal feature libraries (wireplumber, tray, battery, network, mpris,
# bluetooth, powerprofiles, apps)
# All use DBus or have deps already installed above
RUN cd astal/lib/wireplumber && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/tray && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/battery && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/network && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/mpris && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/bluetooth && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/powerprofiles && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

RUN cd astal/lib/apps && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

# Build astal-notifd (notification daemon)
RUN cd astal/lib/notifd && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig

# Build astal-niri (niri IPC - from PR #70)
RUN cd astal/lib/niri && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    ldconfig && \
    rm -rf /build/src/astal

# -----------------------------------------------------------------------------
# Build AGS (Aylur's GTK Shell)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y npm golang gjs && dnf clean all

RUN git clone --depth 1 https://github.com/aylur/ags.git && \
    cd ags && \
    # Patch: use versioned .so.0 for LD_PRELOAD (unversioned .so is in -devel package)
    sed -i "s|libgtk4-layer-shell.so'|libgtk4-layer-shell.so.0'|" meson.build && \
    npm install && \
    meson setup build --prefix=/usr && \
    meson install -C build && \
    DESTDIR=/build/out meson install -C build && \
    rm -rf /build/src/ags

# -----------------------------------------------------------------------------
# Build cmark-gfm (GitHub Flavored Markdown - needed by Vicinae)
# Install system-wide so vicinae can find headers, then copy libs to output
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y cmake && dnf clean all

RUN git clone --depth 1 https://github.com/github/cmark-gfm.git && \
    cd cmark-gfm && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMARK_SHARED=ON \
        -DCMARK_STATIC=OFF \
        .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    # Copy libs to output for final image (cmark installs to /usr/lib on Fedora)
    cp -P /usr/lib/libcmark-gfm*.so* /build/out/lib64/ && \
    rm -rf /build/src/cmark-gfm

# -----------------------------------------------------------------------------
# Build Vicinae (Qt6 launcher)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    cmake ninja-build \
    qt6-qtbase-devel qt6-qtsvg-devel qt6-qt5compat-devel qt6-qtwayland-devel \
    qtkeychain-qt6-devel rapidfuzz-cpp-devel \
    openssl-devel protobuf-devel protobuf-compiler libqalculate-devel \
    layer-shell-qt-devel abseil-cpp-devel \
    wayland-devel libxkbcommon-devel libX11-devel libxcb-devel \
    minizip-devel \
    nodejs npm jq \
    && dnf clean all

RUN git clone --depth 1 https://github.com/vicinaehq/vicinae.git && \
    cd vicinae && \
    mkdir build && cd build && \
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DUSE_SYSTEM_LAYER_SHELL=ON \
        .. && \
    ninja && \
    DESTDIR=/build/out ninja install && \
    rm -rf /build/src/vicinae

# -----------------------------------------------------------------------------
# Build starship (cross-shell prompt)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y rust cargo && dnf clean all

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    git clone --depth 1 https://github.com/starship/starship.git && \
    cd starship && \
    cargo build --release && \
    install -Dm755 target/release/starship /build/out/bin/starship && \
    rm -rf /build/src/starship

# -----------------------------------------------------------------------------
# Build yadm (dotfiles manager)
# -----------------------------------------------------------------------------
# No build deps - it's a shell script
RUN git clone --depth 1 https://github.com/yadm-dev/yadm.git && \
    install -Dm755 yadm/yadm /build/out/bin/yadm && \
    rm -rf /build/src/yadm

# -----------------------------------------------------------------------------
# Build Hyprland ecosystem (hypridle + hyprlock)
# Dependencies: hyprutils -> hyprlang -> hyprgraphics -> hyprwayland-scanner -> hypridle/hyprlock
# -----------------------------------------------------------------------------

# Install shared build dependencies for hypr* ecosystem
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    cmake \
    wayland-devel wayland-protocols-devel \
    cairo-devel pango-devel \
    libxkbcommon-devel \
    pam-devel \
    sdbus-cpp-devel \
    mesa-libgbm-devel libdrm-devel mesa-libGL-devel mesa-libEGL-devel \
    pugixml-devel \
    pixman-devel libjpeg-turbo-devel libwebp-devel libpng-devel \
    librsvg2-devel file-devel \
    && dnf clean all

# Build hyprland-protocols (Fedora version is too old)
RUN git clone --depth 1 https://github.com/hyprwm/hyprland-protocols.git && \
    cd hyprland-protocols && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build && \
    DESTDIR=/build/out cmake --install build && \
    cmake --install build && \
    rm -rf /build/src/hyprland-protocols

# Build hyprutils (base library, no hypr deps)
RUN git clone --depth 1 https://github.com/hyprwm/hyprutils.git && \
    cd hyprutils && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    cmake --install build && \
    ldconfig && \
    rm -rf /build/src/hyprutils

# Build hyprwayland-scanner (code generator, needs pugixml)
RUN git clone --depth 1 https://github.com/hyprwm/hyprwayland-scanner.git && \
    cd hyprwayland-scanner && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    cmake --install build && \
    rm -rf /build/src/hyprwayland-scanner

# Build hyprlang (config language, needs hyprutils)
RUN git clone --depth 1 https://github.com/hyprwm/hyprlang.git && \
    cd hyprlang && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    cmake --install build && \
    ldconfig && \
    rm -rf /build/src/hyprlang

# Build hyprgraphics (graphics utilities, needs hyprutils)
RUN git clone --depth 1 https://github.com/hyprwm/hyprgraphics.git && \
    cd hyprgraphics && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    cmake --install build && \
    ldconfig && \
    rm -rf /build/src/hyprgraphics

# Build hypridle (idle daemon)
RUN git clone --depth 1 https://github.com/hyprwm/hypridle.git && \
    cd hypridle && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    rm -rf /build/src/hypridle

# Build hyprlock (screen locker)
RUN git clone --depth 1 https://github.com/hyprwm/hyprlock.git && \
    cd hyprlock && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j$(nproc) && \
    DESTDIR=/build/out cmake --install build && \
    rm -rf /build/src/hyprlock

# =============================================================================
# Stage 2: Final image
# =============================================================================
FROM ${UBLUE_IMAGE}:${FEDORA_VERSION}

ARG FEDORA_VERSION=43

# Copy build context
COPY --from=ctx /files/ /tmp/files/
COPY --from=ctx /scripts/ /tmp/scripts/

# Enable COPRs (niri + ghostty)
RUN curl -fsSL "https://copr.fedorainfracloud.org/coprs/yalter/niri/repo/fedora-${FEDORA_VERSION}/yalter-niri-fedora-${FEDORA_VERSION}.repo" \
    -o /etc/yum.repos.d/yalter-niri.repo && \
    curl -fsSL "https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-${FEDORA_VERSION}/scottames-ghostty-fedora-${FEDORA_VERSION}.repo" \
    -o /etc/yum.repos.d/scottames-ghostty.repo

# Install packages and configure system
RUN --mount=type=cache,target=/var/cache \
    --mount=type=bind,from=builder,src=/build/out,dst=/tmp/builder-out \
    # Install Fedora + COPR packages
    rpm-ostree install \
        # Core WM stack (from COPR yalter/niri)
        niri xwayland-satellite \
        # Terminal (from COPR scottames/ghostty)
        ghostty \
        # Login manager
        greetd tuigreet \
        # D-Bus tools (dbus-update-activation-environment for niri session)
        dbus-tools \
        # Fingerprint auth
        fprintd fprintd-pam libfprint \
        # XDG Desktop Portals (needed for Flatpak file pickers, screen sharing, etc.)
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
        # Session utilities (hypridle/hyprlock built from source)
        swaybg wlsunset brightnessctl wl-clipboard \
        # Runtime deps for hypridle/hyprlock (built from source)
        sdbus-cpp \
        # Runtime deps for Astal feature libraries
        wireplumber power-profiles-daemon \
        # Shell & CLI tools
        zsh zoxide fzf fd-find bat btop neovim trash-cli pass \
        # Git (core only)
        git \
        # Containers
        podman-compose \
        # Networking
        tailscale syncthing \
        # Runtime deps for source-built packages
        # AGS runtime (GTK4 + layer shell)
        gtk4 gtk4-layer-shell gtk3 gtk-layer-shell gjs \
        # Vicinae runtime
        qt6-qtbase qt6-qtsvg qt6-qt5compat qt6-qtwayland qtkeychain-qt6 nodejs \
        layer-shell-qt abseil-cpp libqalculate protobuf minizip \

        # GPG/Keyring integration
        # gnome-keyring is required for the Secret portal (Flatpak apps storing credentials)
        gnome-keyring pinentry-gnome3 \
        # File manager - also used by xdg-desktop-portal-gnome for file picker dialogs
        nautilus \
        # Fonts
        overpass-fonts \
        # Development tools
        caddy \
    && \
    # Remove unwanted packages from base image
    # - toolbox: we use distrobox only
    # - waybar: we use AGS instead (pulled in as niri weak dep)
    # - mako: we use AGS for notifications instead
    rpm-ostree override remove toolbox waybar mako && \
    # Copy built binaries from builder stage
    cp -r /tmp/builder-out/usr/bin/* /usr/bin/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/bin/* /usr/bin/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/usr/share/* /usr/share/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/share/* /usr/share/ 2>/dev/null || true && \
    # Copy libraries (built from source: astal, cmark-gfm, hypr*)
    cp -r /tmp/builder-out/usr/lib64/* /usr/lib64/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/lib64/* /usr/lib64/ 2>/dev/null || true && \
    # Recompile GSettings schemas (astal libraries add new schemas)
    glib-compile-schemas /usr/share/glib-2.0/schemas/ && \
    # Copy systemd user services (e.g., vicinae.service)
    mkdir -p /usr/lib/systemd/user && \
    cp -r /tmp/builder-out/usr/lib/systemd/user/* /usr/lib/systemd/user/ 2>/dev/null || true && \
    # Copy config files (to /etc, not /usr/etc - ostree images use /etc directly)
    cp -r /tmp/files/usr/etc/* /etc/ && \
    cp -r /tmp/files/usr/share/* /usr/share/ 2>/dev/null || true && \
    # Enable greetd via systemd preset (systemctl enable doesn't work at build time)
    mkdir -p /usr/lib/systemd/system-preset && \
    echo "enable greetd.service" > /usr/lib/systemd/system-preset/50-flint.preset && \
    # Brand the OS
    sed -i 's/^NAME=.*/NAME="Flint"/' /usr/lib/os-release && \
    sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Flint"/' /usr/lib/os-release && \
    # Cleanup
    rm -rf /tmp/files /tmp/scripts && \
    rpm-ostree cleanup -m && \
    ostree container commit

# Validate the image
RUN bootc container lint
