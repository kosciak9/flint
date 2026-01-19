# vim: set ft=make :

# Flint custom recipes

# Switch from GRUB to systemd-boot (faster boot, no graphics init hang)
switch-to-systemd-boot:
    #!/usr/bin/bash
    set -uo pipefail
    
    echo "=== Switching to systemd-boot ==="
    echo ""
    
    # Check if running on EFI
    if [ ! -d /sys/firmware/efi ]; then
        echo "ERROR: This system is not using EFI. systemd-boot requires EFI."
        exit 1
    fi
    
    # Check if systemd-boot binaries are available
    if [ ! -d /usr/lib/systemd/boot/efi ]; then
        echo "ERROR: systemd-boot-unsigned package is not installed."
        echo "It should be included in Flint. Try: rpm-ostree install systemd-boot-unsigned"
        exit 1
    fi
    
    # Check current bootloader (ignore errors, just informational)
    echo "Current boot configuration:"
    bootctl status 2>/dev/null | head -20 || true
    echo ""
    
    read -p "This will install systemd-boot alongside your current bootloader. Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    
    # Install systemd-boot
    echo "Installing systemd-boot to ESP..."
    if ! sudo bootctl install --esp-path=/boot/efi; then
        echo "ERROR: Failed to install systemd-boot"
        exit 1
    fi
    
    # Create loader.conf (no leading spaces - heredoc indentation issue)
    echo "Configuring loader.conf..."
    sudo tee /boot/efi/loader/loader.conf > /dev/null << 'EOF'
default ostree-*
timeout 3
console-mode auto
editor no
EOF
    
    # Verify installation
    echo ""
    echo "=== Installation complete ==="
    echo ""
    bootctl status 2>/dev/null | head -30 || true
    echo ""
    echo "systemd-boot has been installed."
    echo ""
    echo "Next steps:"
    echo "1. If you use rEFInd: it should auto-detect the new bootloader"
    echo "2. To boot directly to systemd-boot, update your EFI boot order:"
    echo "   sudo efibootmgr -o XXXX  (where XXXX is the systemd-boot entry)"
    echo "3. Reboot to test: systemctl reboot"
    echo ""
    echo "If boot fails, you can recover from rEFInd or a live USB."

# Remove GRUB after switching to systemd-boot (optional cleanup)
remove-grub:
    #!/usr/bin/bash
    set -euo pipefail
    
    echo "=== Remove GRUB from ESP ==="
    echo ""
    
    # Check if systemd-boot is installed
    if ! bootctl is-installed &>/dev/null; then
        echo "ERROR: systemd-boot is not installed. Run 'ujust switch-to-systemd-boot' first."
        exit 1
    fi
    
    echo "This will remove GRUB files from the ESP."
    echo "Make sure systemd-boot is working before proceeding!"
    echo ""
    
    read -p "Have you successfully booted with systemd-boot? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Test systemd-boot first, then run this again."
        exit 0
    fi
    
    # Remove GRUB EFI files
    echo "Removing GRUB from ESP..."
    sudo rm -rf /boot/efi/EFI/fedora/grub* 2>/dev/null || true
    sudo rm -f /boot/efi/EFI/fedora/shimx64.efi 2>/dev/null || true
    sudo rm -f /boot/efi/EFI/fedora/mmx64.efi 2>/dev/null || true
    
    # Remove GRUB from EFI boot entries (keep the fedora entry pointing to systemd-boot)
    echo ""
    echo "Current EFI boot entries:"
    efibootmgr -v
    echo ""
    echo "GRUB files removed. The 'Fedora' EFI entry now uses systemd-boot."
    echo ""
    echo "Note: GRUB package is still installed (needed for rpm-ostree)."
    echo "This just removes it from the boot path."
