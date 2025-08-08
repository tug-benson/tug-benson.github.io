---
layout: post
title:  "Tutorial: Installing Arch Linux in Dual Boot on a 2017 MacBook Pro"
date:   2025-08-08 15:10:00 +0200
parent: Mac
---

This guide summarizes the necessary steps to install Arch Linux in dual boot with macOS on a 15.4-inch 2017 MacBook Pro (Intel chipset), using rEFInd as the boot manager. It is based on an actual installation process and focuses on the method that worked.

## Step 1: Preparation in macOS

The first step is to make space for Arch Linux from within macOS.

1.  **Open Disk Utility**: Launch Disk Utility on macOS.
2.  **Shrink the APFS container**:
    *   Select your main drive (the APFS container, not just the "Macintosh HD" volume).
    *   Click on "Partition".
    *   Reduce the size of the APFS container to free up the desired space for Arch Linux (e.g., 150 GB).
3.  **Manage the new space**: macOS will likely create a new APFS volume in the freed space.
    *   Select this new empty APFS volume.
    *   Click the "—" (minus) button to delete it.
    *   The goal is to have unallocated **free space**. Don't worry if macOS names it an "untitled APFS volume"; Linux tools will know how to handle it.

## Step 2: Creating the Bootable Arch Linux USB Drive

1.  **Download the ISO**: Get the latest Arch Linux ISO image from the [official website](https://archlinux.org/download/).
2.  **Create the USB drive**: Use a tool like `dd`, Etcher, or Rufus to flash the ISO image onto a USB drive.

## Step 3: Booting and Initial Setup

1.  **Boot from the USB drive**: Reboot your Mac while holding down the **Option (⌥)** key. Select the USB drive (usually displayed as "EFI Boot") from the startup menu.
2.  **Choose the boot mode**: In the Arch Linux menu, select the `Arch Linux install medium (x86_64, UEFI)` option.
3.  **Set the keyboard layout**: To make typing easier, switch the keyboard to your layout (the default is US). For other layouts, use `loadkeys`. For example, for a French AZERTY keyboard:
    ```bash
    loadkeys fr
    ```
4.  **Internet Connection**: Ensure you have an internet connection. For this MacBook, a USB-C to Ethernet adapter was used and worked without any additional configuration.

## Step 4: Disk Partitioning

1.  **Identify the disk**: List the disks to find the identifier for your internal SSD.
    ```bash
    lsblk
    ```
    *(The disk was `/dev/nvme0n1` in this case)*.

2.  **Launch the partitioning tool**:
    ```bash
    cfdisk /dev/nvme0n1
    ```
3.  **Partition**:
    *   Navigate to the 150 GB partition (identified as "Apple APFS") and select `Delete`. This will turn it into `Free space`.
    *   On this free space, create your Linux partitions:
        *   **Root Partition (`/`)**: Select `New`, choose the size (e.g., `130G`), and leave the default type as `Linux filesystem`.
        *   **Swap Partition**: On the remaining free space, select `New`, choose the size (e.g., `20G`), then change the `Type` to `Linux swap`.
    *   **Do not touch** the existing small `EFI System` partition (e.g., `/dev/nvme0n1p1`).
    *   Select `Write`, type `yes`, and then `Quit`.

## Step 5: Formatting and Mounting Partitions

1.  **Format the partitions**:
    ```bash
    # Format the root partition as ext4 (adjust p3 if necessary)
    mkfs.ext4 /dev/nvme0n1p3

    # Initialize the swap partition (adjust p4 if necessary)
    mkswap /dev/nvme0n1p4
    ```
2.  **Mount the partitions**:
    ```bash
    # Mount the root partition
    mount /dev/nvme0n1p3 /mnt

    # Enable swap
    swapon /dev/nvme0n1p4

    # Create the mount point for the EFI and mount it
    mkdir -p /mnt/boot
    mount /dev/nvme0n1p1 /mnt/boot
    ```

## Step 6: Base System Installation

1.  **Install base packages**: `linux-firmware` is crucial for hardware support, especially for the Broadcom Wi-Fi.
    ```bash
    pacstrap /mnt base linux linux-firmware
    ```
2.  **Generate fstab**: This file defines how partitions are mounted at boot.
    ```bash
    genfstab -U /mnt >> /mnt/etc/fstab
    ```

## Step 7: System Configuration (chroot)

1.  **Enter the new system**:
    ```bash
    arch-chroot /mnt
    ```
2.  **Set the time zone**:
    ```bash
    ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
    hwclock --systohc
    ```
3.  **Configure the language**:
    ```bash
    # Uncomment your desired locale in /etc/locale.gen, e.g., en_US.UTF-8
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    ```
4.  **Set the console keyboard layout**:
    ```bash
    echo "KEYMAP=us" > /etc/vconsole.conf
    ```
5.  **Set the hostname**:
    ```bash
    echo "my-arch-mac" > /etc/hostname
    ```
6.  **Set the root password**:
    ```bash
    passwd
    ```
7.  **Install essential packages** for post-installation (networking, sudo, editor).
    ```bash
    pacman -S networkmanager sudo nano
    ```
8.  **Enable the network manager** to start on boot.
    ```bash
    systemctl enable NetworkManager
    ```
9.  **Create a user**:
    ```bash
    useradd -m -G wheel your_username
    passwd your_username
    ```
10. **Configure sudo**:
    ```bash
    EDITOR=nano visudo
    ```
    Uncomment the line `%wheel ALL=(ALL:ALL) ALL` to allow users in the `wheel` group to use `sudo`.

## Step 8: Installing and Fixing the Bootloader (rEFInd)

This is the most critical step and the one that caused errors during the initial installation.

1.  **Install rEFInd**:
    ```bash
    pacman -S refind
    refind-install
    ```
2.  **Correct the rEFInd configuration**: `refind-install` might create an incorrect configuration file based on the USB drive's environment. It must be replaced with a configuration pointing to your actual installation.

    *Replace `1c8b680a-3267-484c-9f4c-76b945e9611a` with the UUID of your root partition (`/`), which you can find using `blkid`.*

    ```bash
    # Creates and overwrites the file with the correct configuration for the main boot entry
    echo '"Arch Linux" "root=UUID=1c8b680a-3267-484c-9f4c-76b945e9611a rw initrd=\initramfs-linux.img"' > /boot/refind_linux.conf

    # Adds the fallback boot entry
    echo '"Arch Linux (fallback)" "root=UUID=1c8b680a-3267-484c-9f4c-76b945e9611a rw initrd=\initramfs-linux-fallback.img"' >> /boot/refind_linux.conf
    ```

## Step 9: Finalization

1.  **Exit chroot**:
    ```bash
    exit
    ```
2.  **Unmount the partitions**:
    ```bash
    umount -R /mnt
    ```
3.  **Reboot**:
    ```bash
    reboot
    ```
    Remove the USB drive as soon as the computer restarts.

## Post-installation

On reboot, the rEFInd menu should appear. Choose "Arch Linux" (the icon with Tux the penguin). You should arrive at the console login screen.

*   **Network**: Log in and use `nmtui` to easily configure your Wi-Fi or Ethernet connection.
*   **Graphical Environment**: You are now ready to install a desktop environment, a display server (Xorg or Wayland), graphics drivers, etc.

This tutorial should provide a clear path to successfully replicate the installation.
