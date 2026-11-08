# Jide Remix Tablet Revived

A custom ROM that brings Android 14 (LineageOS 21) to the **Jide Remix Ultra Tablet** (model REMIX SK1WG), the 2015 11.6" NVIDIA Tegra 4 tablet with a keyboard cover.

| Model | Support |
|---|---|
| Remix Ultra Tablet **REMIX SK1WG** (Wi-Fi, 2 GB / 64 GB) | Supported: first release, see below |
| Other Remix devices (Remix Mini, Remix Pro, ...) | Not supported |

Jide left the consumer market in July 2017 and ended Remix OS, and the last firmware it shipped is Remix OS 2.0.305 (Android 5.1.1, June 2016). The tablet still works, but it is very slow (Remix OS and Google Play services on 2 GB of RAM and an old eMMC) and nothing on it gets security updates any more. This project puts a clean, lightweight Android on it, with the hardware that makes the tablet useful: the 1920x1080 screen with GPU acceleration, touch, Wi-Fi, Bluetooth, audio, sensors and the keyboard cover.

There are no Google services: the system is LineageOS's "mini" Wi-Fi tablet set, and the stock 1000 MB system partition is kept as it is.

> **Status: first release.** LineageOS 21 installs with fastboot and runs day to day: smooth at the panel's full 1920x1080, with Wi-Fi, Bluetooth audio, speaker, headphones, microphone, sensors and the keyboard cover. Known limits: **the camera does not work yet**, SELinux is permissive, and updates are installed by re-flashing. Download it from [Releases](../../releases/latest), then follow [Install](#install).

## What works

| Area | Status |
|---|---|
| Boot to the home screen | Works, from the flashed boot partition |
| Display, 1920x1080, GPU | Works, through NVIDIA's own Tegra 4 graphics drivers from Remix OS with compatibility shims. SurfaceFlinger composes on the GPU (NVIDIA's overlay path garbles the panel) |
| Touch | Works (FocalTech FT5x06). No double tap to wake: the controller ignores it |
| Smoothness | Smooth scrolling once the everyday apps are compiled, which happens on the device after the first boot |
| Wi-Fi | Works, 2.4 GHz only (the BCM43341 has no 5 GHz). No hotspot, no Wi-Fi Direct |
| Bluetooth | Works: Bluetooth headphones play through A2DP (AAC/SBC, encoded in software). The chip has no address of its own, so the first boot makes a random one |
| Audio | Speaker, wired headphones (the speaker switches off while they are plugged in) and the internal microphone work. A headset microphone is never selected |
| Media playback | Works through Android's Codec2 software codecs. NVIDIA's hardware video decoders are not used (they need Android 5.1 libraries) |
| Web browser and WebView apps | Work on the GPU through ANGLE |
| Sensors | Accelerometer, gyroscope, compass and light sensor are listed. Adaptive brightness works |
| Backlight | Works, off when the screen sleeps |
| Keyboard cover | Closing the cover puts the tablet to sleep; opening it does not wake it (the power key does). The keyboard and touchpad work (plain USB HID) |
| Camera | **Not working yet**: the stock camera driver needs Android 5.1 libraries. A V4L2 driver is in progress: the back camera already sends frames to the Tegra's CSI receiver, the images do not reach memory yet |
| Security | SELinux is permissive and the security patch level is from early 2025. Builds are signed with the project's own release keys |
| Updates | By re-flashing (data kept); there is no over-the-air update |

The bring-up log, with every problem found and how it was fixed, is in [docs/BRINGUP.md](docs/BRINGUP.md).

## Hardware

| Part | Details |
|---|---|
| SoC | NVIDIA Tegra 4 (T114), 4x Cortex-A15 up to 1.8 GHz, 32-bit |
| Board | NVIDIA `macallan` reference platform (shared with the Asus Transformer Pad TF701T) |
| RAM / storage | 2 GB / 64 GB eMMC, microSD slot |
| Display | 11.6" 1920x1080, DSI |
| Touch | FocalTech FT5x06 |
| Wi-Fi / Bluetooth | Broadcom BCM43341 |
| Audio | TI TLV320AIC325x |
| Sensors | MPU-3050 gyroscope, KXTF9 accelerometer, AK8963 compass, CM3217 light sensor |
| Keyboard cover | Plain USB HID over the pogo contacts (keyboard + touchpad), a Hall switch for the lid |
| Video out | None: the SoC's HDMI block (and its HDA audio device) is there, but the tablet has no HDMI connector |
| Stock kernel | NVIDIA Linux 3.4.108 |
| Bootloader | Unlocked, unsigned images boot (`fastboot boot` works without flashing) |

## Install

Installing replaces Remix OS and **erases everything on the tablet** (apps, accounts, files). The bootloader of the REMIX SK1WG is already unlocked, so there is nothing to unlock: you only need fastboot.

### What you need

- A Jide Remix Ultra Tablet, model **REMIX SK1WG**, with the battery at 50% or more. Other Remix devices are different hardware.
- A PC with Android's [platform-tools](https://developer.android.com/tools/releases/platform-tools) (`fastboot`). On Windows, also Google's USB driver for the bootloader ([how](docs/INSTALL.md#2-what-you-need)).
- A good USB cable, plugged into the PC itself, not a hub.
- The latest **`...-sk1wg-images.zip`** from [Releases](../../releases/latest), extracted. It holds `boot.img`, `system.img` and `system_ext.img`.
- Recommended: Jide's official Remix OS 2.0.305 images, to go back to stock one day ([how](docs/INSTALL.md#7-going-back-to-remix-os)).

### Steps

1. **Start the bootloader.** Switch the tablet off (hold Power for 10-15 s if it does not respond). Hold **Volume Up + Power** until the bootloader menu appears, then pick **"Fastboot Protocol"** on screen. Without that last step every fastboot command times out.
2. **Check the connection.** In a terminal, in the folder with the images:
   ```
   fastboot devices
   ```
   The tablet must be listed. `fastboot getvar product` should answer `Macallan`.
3. **Flash and wipe:**
   ```
   fastboot flash boot boot.img
   fastboot -S 256M flash system system.img
   fastboot -S 256M flash cache system_ext.img
   fastboot format:ext4 userdata
   fastboot reboot
   ```
   `system_ext` goes to the stock **cache** partition on purpose: the system partition is too small for both. `-S 256M` sends the large images in pieces.
4. **First boot.** It takes several minutes: Android compiles the apps on the tablet. Then the setup wizard starts.

**Updating** to a newer release: the same commands without `fastboot format:ext4 userdata`, so your data stays.

**Going back to Remix OS**: flash Jide's official images, see [docs/INSTALL.md](docs/INSTALL.md#7-going-back-to-remix-os).

**Backup**: only your own files and photos, which the wipe erases. Nothing else is needed: the install writes only boot, system, cache and userdata, which Jide's official images restore, and never touches the bootloader or the tablet's other partitions.

### Warnings
- Flashing a custom system always has some risk. You do it at your own risk.
- **Never flash or erase the bootloader** (`fastboot flash bootloader`). A bad bootloader is the one thing fastboot cannot fix.
- **Never write the `USP` (staging) partition.** On NVIDIA devices the bootloader installs a bootloader update it finds there at the next boot; a bad one is a hard brick.
- **Never run `fastboot oem lock`.** A relocked bootloader may refuse to boot anything but signed stock images.
- **Never choose "Forced Recovery"** in the bootloader menu. It puts the Tegra in its USB recovery mode (APX), and there is no tested way back from there for this tablet.
- Never repartition, and leave the `dtb` partition alone. This project only ever writes boot, recovery, system, cache and userdata.
- Try every new kernel or recovery with `fastboot boot` first: it runs from RAM and writes nothing.

## For developers

- [docs/TECHNICAL.md](docs/TECHNICAL.md): the source trees and branches, how to build, the blobs, the partitions, the mini recovery, debugging tips and the gaps before a release.
- [docs/BRINGUP.md](docs/BRINGUP.md): the bring-up notes: kernel gaps, graphics, partitions, Wi-Fi, audio, media, performance, code review.
- [docs/INSTALL.md](docs/INSTALL.md): testing on a tablet, and going back to Remix OS.

Repositories:
- this one: docs, `manifests/`, `tools/` and the mini recovery sources (`minirecovery/`);
- the device tree: [android_device_jide_sk1wg](https://github.com/simoneluconi/android_device_jide_sk1wg) (branch `lineage-21.0`), at `device/jide/sk1wg`;
- the kernel: [android_kernel_jide_sk1wg](https://github.com/simoneluconi/android_kernel_jide_sk1wg) (branch `sk1wg`), a fork of TerenceWSK's community CM13 kernel for this tablet;
- frameworks/base: branch `sk1wg` of [android_frameworks_base](https://github.com/simoneluconi/android_frameworks_base/tree/sk1wg) (the Galaxy Camera's `gd1` plus a boot animation fix).

Related: [Galaxy Camera Revived](https://github.com/simoneluconi/GalaxyCameraRevived), the sibling project (LineageOS 21 on the Samsung Galaxy Camera). Its fixes for old 3.4 kernels in bionic, system/core, adb, unwinding, the frameworks and the launcher are used here as they are.

## Credits

This port stands on the work of many people:
- **[TerenceWSK](https://github.com/TerenceWSK)**: the CyanogenMod 13 kernel and device tree for the SK1WG, the base of our kernel.
- **[Jide Technology](https://github.com/JideTechnology)**: the published Remix OS kernel source (`remixos-kernel`, branch `jide_sk1w`).
- **NVIDIA**: the open Linux 3.4 kernel for the Tegra 4 `macallan` reference board.
- **LineageOS contributors** of the Tegra 4 kernel for the NVIDIA Shield Portable (`android_kernel_nvidia_roth`, `lineage-15.1`), where most of our Android 8+ kernel backports come from.
- **[html6405](https://github.com/html6405)**: the LineageOS 21 trees for Exynos 4412 devices, with kernel backports (getrandom, memfd_create, binder security contexts, timerfd alarms) and the gralloc0 HIDL adapters used here.
- **[LineageOS-UL](https://github.com/LineageOS-UL)** ("LineageOS for Ultra Legacy devices"): the Android 14 base patched for old kernels and hardware.
- **LineageOS, AOSP and CyanogenMod contributors**: among others the Android emulator's audio HAL that ours is built from, and LineageOS's power HAL.
- The XDA users who documented the tablet's fastboot and recovery.

## Licences

| Part | Licence |
|---|---|
| Kernel (fork of TerenceWSK's CM13 kernel, NVIDIA Linux 3.4) | GPL-2.0 |
| Device tree (`device/jide/sk1wg`, including the AOSP-derived audio, health and graphics adapters) | Apache-2.0 |
| Tools (`tools/`), the mini recovery sources (`minirecovery/`) and the manifests | Apache-2.0 ([text](LICENSES/Apache-2.0.txt)) |
| Documentation (`docs/`, this README) | CC BY 4.0 ([text](LICENSES/CC-BY-4.0.txt)) |

The licence of each path is declared in [`REUSE.toml`](REUSE.toml).

Jide's and NVIDIA's proprietary files (firmware, drivers, libraries) are **not** in these repositories. They are extracted from the official Remix OS firmware when the system is built.

This project is not affiliated with Jide Technology or NVIDIA. "Jide", "Remix" and "Remix OS" are trademarks of their respective owners; "NVIDIA" and "Tegra" are trademarks of NVIDIA Corporation.
