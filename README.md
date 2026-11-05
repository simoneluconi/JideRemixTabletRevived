# Jide Remix Tablet Revived

An effort to bring a modern, lightweight Android (**LineageOS 21 / Android 14**) to the **Jide Remix Ultra Tablet** (model REMIX SK1WG), the 2015 11.6" NVIDIA Tegra 4 tablet with a keyboard dock.

Jide closed down, and the last firmware it shipped is Remix OS 2.0.305 (Android 5.1.1, June 2016). The tablet still works, but it is very slow and nothing on it gets security updates any more. The goal is a clean system without the Remix OS and Google Play services overhead, with the hardware that makes the tablet useful: the touchscreen, Wi-Fi, Bluetooth, audio and the keyboard dock.

> **Status: research.** Nothing to install yet. The hardware has been identified and the device is confirmed to have an unlocked bootloader. No builds exist.

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
| Keyboard dock | Plain USB HID over the pogo contacts (keyboard + touchpad) |
| Stock kernel | NVIDIA Linux 3.4.108 |
| Bootloader | Unlocked, unsigned images boot (`fastboot boot` works without flashing) |

## Plan

1. A 3.4 kernel for the tablet, based on NVIDIA's open `macallan` kernel sources (Asus TF701T, NVIDIA Shield Portable), plus the Remix-specific board changes. Jide never published this tablet's kernel source.
2. A recovery image, tested with `fastboot boot` (it runs from RAM and writes nothing).
3. LineageOS 21 on the LineageOS-UL base for legacy kernels, with NVIDIA's Tegra 4 graphics and media blobs. A software-rendering fallback keeps the system usable while the graphics drivers are being adapted.

## Safety

The only partitions this project will ever write are boot, recovery, system, cache and userdata. The official images for Remix OS 1.5 and 2.0.305 can restore these with fastboot. The bootloader and NVIDIA's `USP` staging partition are never touched, because a bad bootloader is the one thing that cannot be fixed.

## Related

- [Galaxy Camera Revived](https://github.com/simoneluconi/GalaxyCameraRevived): the sibling project, LineageOS 21 on the Samsung Galaxy Camera.

## Licences

To be decided before the first release. The proprietary Jide and NVIDIA files (firmware, blobs) are **not** in this repository; they are extracted from the official firmware at build time.

This project is not affiliated with Jide Technology or NVIDIA. "NVIDIA" and "Tegra" are trademarks of NVIDIA Corporation.
