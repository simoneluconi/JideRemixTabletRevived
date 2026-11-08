# Testing Jide Remix Tablet Revived (and going back to Remix OS)

There are no public builds yet. This guide is for developers and testers who build the system themselves ([TECHNICAL.md](TECHNICAL.md)) and want to run it on a REMIX SK1WG. Read it once from start to end before touching the tablet.

## 1. The safety rules

The tablet can be brought back to Remix OS with fastboot in almost every case. These rules cover the few cases where it cannot.

1. **Never touch the bootloader.** Never `fastboot flash bootloader` or erase it. If the bootloader breaks, the tablet cannot even reach fastboot.
2. **Never write the `USP` partition** (`/staging`). On NVIDIA devices the bootloader applies a bootloader or BCT update ("blob") that it finds there at the next boot. A bad blob is a hard brick. Nothing in this project writes it, and you should never run tools that do.
3. **Never run `fastboot oem lock`.** The bootloader is unlocked and boots unsigned images; relocked, it may refuse a custom system.
4. **Never pick "Forced Recovery"** in the bootloader menu. It is the Tegra's USB recovery mode (APX), and there is no tested nvflash path for this tablet.
5. **Never repartition**, and leave the `dtb` partition alone. The project only writes boot (LNX), recovery (SOS), system (APP), cache (CAC) and userdata (UDA). The stock layout fits.
6. **RAM-boot first.** Try every new kernel or recovery with `fastboot boot <image>`: it runs from RAM and writes nothing.
7. **Power and cable.** Battery at 50% or more, a known-good data cable in a USB port of the PC itself (not a hub). Never unplug while fastboot is writing.

## 2. What you need

- A Jide Remix Ultra Tablet, model **REMIX SK1WG**. Other Remix devices are different hardware: do not use this build on them.
- A PC with Android's [platform-tools](https://developer.android.com/tools/releases/platform-tools) (`fastboot`, `adb`).
- On Windows, Google's USB driver. The bootloader enumerates as USB `0955:7000`; install the driver for it as "Android Bootloader Interface" with "Have Disk" in Device Manager. If another vendor's Android driver is installed, the device may show up under that vendor's device class: that is fine.
- **Jide's official Remix OS 2.0.305 images** (`boot.img`, `recovery.img`, `system.img`), kept safe before you start: they are your way back. Jide's updates only ever contained these three images.
- Your own build ([TECHNICAL.md](TECHNICAL.md)): `boot.img`, `system.img`, `system_ext.img`, and the mini recovery image.

## 3. Reach the bootloader (no flashing yet)

1. Switch the tablet off. If it does not respond, hold **Power** for 10-15 s to force it off.
2. Hold **Volume Up + Power** until the bootloader menu appears.
3. **Select "Fastboot Protocol"** in the on-screen menu. Without this step every fastboot command times out.
4. Check the connection and the bootloader state:
   ```
   fastboot devices
   fastboot getvar all
   ```
   Expect product `Macallan`, `unlocked: yes` and `secure: no`. If the product is different, stop.

After a software reboot into the bootloader (from the mini recovery, or when a failed boot of a test build restarts into it), fastboot answers right away, without the menu.

Leave the bootloader with `fastboot reboot`.

## 4. Back up the tablet's own partitions

The mini recovery ([TECHNICAL.md](TECHNICAL.md#4-the-mini-recovery)) runs from RAM and only reads the eMMC.

```
fastboot boot minirecovery.img
adb devices
adb shell su -c backup-critical
adb pull /tmp/backup
```

`backup-critical` copies everything on the eMMC except the three big filesystems (system, cache, userdata) into `/tmp/backup`, in RAM: the eMMC boot partitions (where the Tegra's BCT lives), NVIDIA's area before the GPT, the backup GPT, and every other partition (bootloader, boot, recovery, `dtb`, ...). Check the pulled files with `md5sum -c md5sums.txt` inside the backup folder. **Keep the backup private**: it is unique to your tablet, and `cmdline.txt` holds the bootloader's kernel command line with the serial number and a key.

Leave the mini recovery with `adb shell rootrun reboot-to bootloader` (or hold Power to switch off).

## 5. Install the test build on the eMMC

This **erases Remix OS's data** (apps, accounts, files on the internal storage). Remix OS itself comes back with section 7.

From the bootloader in fastboot mode:

```
fastboot -S 256M flash system system.img
fastboot -S 256M flash cache system_ext.img
fastboot format:ext4 userdata
fastboot boot boot.img
```

- `-S 256M` sends the sparse images in 256 MB pieces (`system.img` is about 1 GB).
- `system_ext` goes to the stock **cache** partition (CAC): LineageOS does not need a cache partition, and the 1000 MB system partition is too small for both. The vendor files are inside system.
- The recovery partition keeps Remix OS's recovery.
- The first boot compiles apps on the tablet and takes several minutes. Test builds are `userdebug` with adb on from the first boot, so `adb logcat` works even if the display does not.

The boot image is only RAM-booted here: after a power-off the tablet starts Remix OS's boot image again, which cannot start the LineageOS system. Repeat `fastboot boot boot.img` for each start. Flashing it (`fastboot flash boot boot.img`) is the last step, once a build has proved itself; the project has not done it yet.

If a boot fails, the tablet restarts into the bootloader. RAM-boot the mini recovery and read the kernel and init log in `/proc/last_kmsg`.

## 6. The microSD alternative (eMMC untouched)

A build made with `SK1WG_SDCARD_ROOT=true` mounts system, system_ext and data from a microSD card instead of the eMMC, so Remix OS stays as it is.

1. Partition the card on a PC: p1 at least 1000 MB, p2 at least 800 MB, p3 the rest.
2. Write the raw (unsparsed, `tools/simg2img.py`) `system.img` to p1 and `system_ext.img` to p2; make an empty ext4 filesystem on p3.
3. Put the card in the tablet and run `fastboot boot boot.img` with that build's boot image.

This path has had less testing than the eMMC one ([BRINGUP.md](BRINGUP.md#testing-without-touching-remix-os)).

## 7. Going back to Remix OS

From the bootloader in fastboot mode, with the official 2.0.305 images:

```
fastboot flash system system.img
fastboot flash boot boot.img
fastboot format:ext4 cache
fastboot format:ext4 userdata
fastboot reboot
```

Flash `recovery.img` too if you ever changed the recovery partition. The first Remix OS boot after this takes several minutes.
