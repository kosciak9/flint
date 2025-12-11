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
# Build EWW (Elkowar's Wacky Widgets)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    rust cargo \
    gtk3-devel gtk-layer-shell-devel pango-devel gdk-pixbuf2-devel \
    libdbusmenu-gtk3-devel cairo-devel glib2-devel \
    && dnf clean all

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    git clone --depth 1 https://github.com/elkowar/eww.git && \
    cd eww && \
    cargo build --release --no-default-features --features=wayland && \
    install -Dm755 target/release/eww /build/out/bin/eww && \
    rm -rf /build/src/eww

# -----------------------------------------------------------------------------
# Build eww-niri-workspaces
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    git clone --depth 1 https://github.com/druskus20/eww-niri-workspaces.git && \
    cd eww-niri-workspaces && \
    cargo build --release && \
    install -Dm755 target/release/eww-niri-workspaces /build/out/bin/eww-niri-workspaces && \
    rm -rf /build/src/eww-niri-workspaces

# -----------------------------------------------------------------------------
# Build end-rs (EWW Notification Daemon)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y dbus-devel && dnf clean all

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    git clone --depth 1 https://github.com/Dr-42/end-rs.git && \
    cd end-rs && \
    cargo build --release && \
    install -Dm755 target/release/end-rs /build/out/bin/end-rs && \
    rm -rf /build/src/end-rs

# -----------------------------------------------------------------------------
# Build wluma (Adaptive brightness)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    clang clang-devel llvm-devel \
    vulkan-devel libdrm-devel libv4l-devel \
    && dnf clean all

ARG WLUMA_VERSION=4.10.0
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    git clone --depth 1 https://github.com/maximbaz/wluma.git && \
    cd wluma && \
    WLUMA_VERSION=${WLUMA_VERSION} cargo build --release && \
    install -Dm755 target/release/wluma /build/out/bin/wluma && \
    rm -rf /build/src/wluma

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
# Build swaylock-effects
# -----------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
    meson \
    wayland-devel wayland-protocols-devel libxkbcommon-devel \
    cairo-devel gdk-pixbuf2-devel pam-devel scdoc \
    && dnf clean all

RUN git clone --depth 1 https://github.com/jirutka/swaylock-effects.git && \
    cd swaylock-effects && \
    meson setup build --prefix=/usr && \
    ninja -C build && \
    DESTDIR=/build/out ninja -C build install && \
    rm -rf /build/src/swaylock-effects

# -----------------------------------------------------------------------------
# Build starship (cross-shell prompt)
# -----------------------------------------------------------------------------
# Uses rust/cargo already installed for eww
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
        # Session utilities
        swaybg swayidle wlsunset brightnessctl wl-clipboard \
        # Shell & CLI tools
        zsh zoxide fzf bat btop neovim trash-cli pass \
        # Git (core only)
        git \
        # Containers
        podman-compose \
        # Networking
        tailscale syncthing \
        # Runtime deps for source-built packages
        # EWW runtime
        gtk3 gtk-layer-shell pango gdk-pixbuf2 libdbusmenu-gtk3 cairo glib2 \
        # Vicinae runtime
        qt6-qtbase qt6-qtsvg qt6-qt5compat qt6-qtwayland qtkeychain-qt6 nodejs \
        layer-shell-qt abseil-cpp libqalculate protobuf minizip \
        # Swaylock-effects runtime
        libxkbcommon \
        # Wluma runtime
        vulkan-loader libdrm libv4l \
        # GPG/Keyring integration
        # gnome-keyring is required for the Secret portal (Flatpak apps storing credentials)
        gnome-keyring pinentry-gnome3 \
        # File manager - also used by xdg-desktop-portal-gnome for file picker dialogs
        nautilus \
        # Fonts
        overpass-fonts \
    && \
    # Remove unwanted packages from base image
    # - toolbox: we use distrobox only
    # - waybar: we use eww instead (pulled in as niri weak dep)
    # - mako: we use end-rs (EWW notification daemon) instead
    rpm-ostree override remove toolbox waybar mako && \
    # Copy built binaries from builder stage
    cp -r /tmp/builder-out/usr/bin/* /usr/bin/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/bin/* /usr/bin/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/usr/share/* /usr/share/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/share/* /usr/share/ 2>/dev/null || true && \
    # Copy cmark-gfm libraries (built from source)
    cp -r /tmp/builder-out/usr/lib64/* /usr/lib64/ 2>/dev/null || true && \
    cp -r /tmp/builder-out/lib64/* /usr/lib64/ 2>/dev/null || true && \
    # Copy systemd user services (e.g., vicinae.service)
    mkdir -p /usr/lib/systemd/user && \
    cp -r /tmp/builder-out/usr/lib/systemd/user/* /usr/lib/systemd/user/ 2>/dev/null || true && \
    # Copy config files
    cp -r /tmp/files/usr/etc/* /usr/etc/ 2>/dev/null || true && \
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
