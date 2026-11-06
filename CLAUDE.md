# JideRemixTabletRevived

Goal: run a modern, lightweight Android on the **Jide Remix Ultra Tablet (REMIX SK1WG)**. Jide is gone and the last firmware is Remix OS 2.0.305 (Android 5.1.1, June 2016). Same playbook as `../GalaxyCameraRevived` (LineageOS port, repo-shaped for GitHub, proprietary blobs never committed).

Talk to the user in Italian. Everything written to disk (code, docs, commits, file names) is in English.

Private serials and local setup: @CLAUDE.local.md

## Device (from the firmware, 2026-11-05)

- **SoC**: NVIDIA Tegra 4 (T114), 4x Cortex-A15, 2 GB RAM, 11.6" 1920x1080, armv7 32-bit only.
- **Board**: NVIDIA reference platform **`macallan`** (same base as the Asus Transformer Pad TF701T). Product `sk1wg`, `ro.board.platform=tegra`.
- **Kernel**: NVIDIA 3.4 tree, `3.4.108-g64375a4` (2.0.305) / `3.4.108-g5149328` (1.5). Built from `device/tegra-kernel`, board files `arch/arm/mach-tegra/board-macallan-*.c`. No embedded IKCONFIG; read `/proc/config.gz` on the device. Kernel is LZO-compressed (lzop stream at offset 6540 in the zImage).
- **Boot images**: Android v0 header, base 0x10000000, pagesize 2048, empty cmdline.
- **Partitions** (`fstab.macallan`, eMMC `sdhci-tegra.3`): APP=/system, CAC=/cache, UDA=/data, MDA=crypto footer. microSD on `sdhci-tegra.2`.
- **Hardware on this unit** (read from the running tablet, 2026-11-05; dumps in `device-dump/stock-2.0.305/runtime/`):
  - Tegra 114 rev A02, SKU 0x5, CPU up to 1810.5 MHz (EDP limit 1606 MHz at boot), RAM 1941 MB at 2048M, VPR 96M carveout.
  - Touch: **FocalTech ft5x06** at i2c-1 0x38 (device ID 0x59, 1000 Hz). The Himax driver is built in but fails to probe (not fitted).
  - Display: DSI panel (`tegradc.0: DSI`), bootloader framebuffer `tegrafb`. The kernel also contains a SN65DSI86 DSI-to-eDP bridge driver; which path this panel uses is still to be confirmed.
  - **Keyboard dock**: pogo contacts carry plain **USB**. It enumerates on `tegra-ehci.2` as "Android USB Keyboard", VID 1017 PID 1006 (HID keyboard + mouse/touchpad). Standard HID, no custom driver.
  - Wi-Fi/BT: Broadcom BCM43341 (`bcmdhd`, USI WM-BAN-BM-13).
  - Audio codec: TI TLV320AIC325x at i2c-0 0x18 (cmdline still says `audio_codec=rt5640`, the reference-board default).
  - Sensors: MPU3050 gyro (0x68) + KXTF9 accel (0x0e) + AK8963 compass (0x0d), CM3217 light sensor, CW2015 fuel gauge (i2c-1 0x62). PMIC on i2c-4 0x58-0x5a.
  - eMMC: Samsung `CWBC3R` 64 GB (manfid 0x15). Not an Exynos "superbrick" part, and this is not an Exynos kernel.
  - HALs: `gralloc/hwcomposer/camera/audio.primary/gps.tegra.so`, NVIDIA blobs in `/vendor/lib` (libnvrm, libnvmm, nvavp firmware).
- **Why stock is slow** (snapshot 30 min after boot): load average 14, 37% I/O wait, Play Store at 43% CPU, MemFree 44 MB. GMS + Remix OS on 2 GB and an old eMMC.
- **Not rooted** (no su; `/proc/cmdline` and by-name are not readable from adb shell, but `dmesg` is and contains the cmdline).
- **Fastboot**: VID 0955 PID 7000. Windows needs the Google USB driver ("Android Bootloader Interface", installed via "Have Disk"; Device Manager shows it under "SAMSUNG Android Phone" because the Samsung driver named that class first). Key combo to reach the bootloader from power-off: **Volume Up + Power** (hold Power 10-15 s first to force a power-off). After `adb reboot bootloader` or the combo, **select "Fastboot Protocol" in the on-screen menu**, otherwise every command times out (`AdbWriteEndpointSync ... (121)`).
- **Bootloader (2026-11-05)**: `version-bootloader 1.0`, product `Macallan`, **`unlocked: yes`, `secure: no`**. No unlock step needed, and unsigned images boot. Use `fastboot boot <img>` (RAM only, writes nothing) for every first test of a new kernel or recovery.
- **GPT** (by-name): SOS=p1 (recovery, starts at sector 45056), DTB=p2, LNX=p3 (boot), APP=p4, CAC=p5, MSC=p6, USP=p7, MDA=p8, BMP=p9, LBP=p10, CHG=p11, FBP=p12, FCG=p13 (boot logo/charger pictures), UDA=p14.
- **Fastboot partition names**: bootloader (6 MB), recovery (8 MB), boot (8 MB), **dtb** (4 MB), system (1000 MB), cache (768 MB), userdata (~56 GB). Full output: `device-dump/stock-2.0.305/runtime/fastboot-getvar-all.txt`.
- **Updates** only ever contained boot.img, recovery.img and system.img (no bootloader). XDA users reflashed 1.5 via fastboot and installed CWM, so the bootloader is fastboot-capable; unlock state not yet verified on this unit.

## Plan

Target **LineageOS 21 directly** (user decision 2026-11-05), on the LineageOS-UL legacy-kernel base as in GalaxyCameraRevived; fall back to 18.1 only if NVIDIA's T114 blobs prove unusable on 14. Repo is meant for GitHub; the kernel goes out as a public GPL fork with our branch.

## Kernel sources (cloned in WSL, `~/android/sk1wg/`)

- `kernel-jide-sk1w`: **official Jide source**, github.com/JideTechnology/remixos-kernel branch `jide_sk1w`, 3.4.108, head 7be277c (2016-05-12). The stock build g64375a4 is not in the public history. Its `keenhi_t40_sk1w_defconfig` selects MACH_TB610N, but the stock kernel uses only `board-macallan-*.c` (checked in the stock Image), so that defconfig does not match stock.
- `kernel-cm13-sk1wg`: **community CM13 kernel**, github.com/TerenceWSK/cm_android_kernel_jide_sk1wg_sk1w branch `cm-13.0`, 3.4.112, single "sk1wg kernel bring up" import plus stable updates and SELinux backports. `cyanogenmod_sk1wg_defconfig` (MACH_MACALLAN, FT5X06, AIC325X, CW2015, CM3217, BCMDHD built in). **Current base.**
- `device-cm13-sk1wg`: TerenceWSK/cm_android_device_jide_sk1wg_sk1w branch `cm13.0` (BoardConfig, fstab, init, proprietary-files list, sepolicy).
- Patch source for Android 8+ kernel requirements: LineageOS/android_kernel_nvidia_roth `lineage-15.1` (Tegra 4, has macallan board files).
- Toolchain: AOSP `arm-linux-androideabi-4.9` (pie-release) in `~/android/toolchains/`. Host tools of a 3.4 tree need `HOSTCFLAGS=... -fcommon` (old dtc). Full build of cm13 kernel: ~80 s.

## Our kernel branch `sk1wg` (2026-11-06)

In `~/android/sk1wg/kernel-cm13-sk1wg`, on top of `origin/cm-13.0`; to become a public GitHub fork. Defconfig **`lineageos_sk1wg_defconfig`**, LOCALVERSION `-sk1wg`.
- From roth `lineage-15.1` (cherry-picked with `-x`): ambient capabilities, the binder series (64-bit ABI, binder/hwbinder/vndbinder, scatter-gather, fd arrays), kuid/userns, the new UID routing (FRA_UID_RANGE; the old Android-6 FRA_UID_START/END version reverted first), no_new_privs (in atomic_flags), the full seccomp-bpf series with TSYNC and the seccomp syscall. Skipped as already in 3.4.112: `for_each_thread()` (list in `~/android/sk1wg/roth-skipped.txt`).
- From html6405 (via format-patch, the GitHub fetch stalls): getrandom (adapted: no `prandom_reseed_late` here), memfd_create plus the sealing definitions only (as html6405), ARM 8-byte `get_user()` (by hand; needed by the 64-bit binder ABI on 32-bit ARM).
- Ours: ARM syscalls 384 getrandom, 385 memfd_create (**382 renameat2 reserved, not backported**: html6405's patch does not fit our fs/namei.c); removed a stale uncompilable `cpuset_can_attach` (CPUSETS was never on before).
- Not done: eBPF (html6405's 415 commits; LineageOS-UL copes without), renameat2, sdcardfs, O_TMPFILE, PR_SET_VMA.
- **Stock Remix OS needs the 32-bit binder ABI**: test it with a variant built with `CONFIG_ANDROID_BINDER_IPC_32BIT=y` (`out-sk1wg-ipc32`). LineageOS 21 needs `=n` (the defconfig default).
- Tested 2026-11-06 with that variant (`fastboot boot`): Remix OS boots in 2.5 min (battery 98%), binder + hwbinder + vndbinder nodes, seccomp on, Wi-Fi, audio, touch. The `gpio_ensure_requested` warnings from `kai_sensor_power_on` (camera) also appear on the stock kernel.

## Test results (2026-11-05)

- `fastboot boot` works with the stock boot.img, our mini recovery, and our kernel.
- **cm13 kernel (`3.4.112-cyanogenmod+`, our GCC 4.9 build) boots stock Remix OS 2.0.305** (stock ramdisk, `tools/repack-boot.sh`): boot_completed in ~8 min (app re-optimisation), Wi-Fi connects, both ALSA cards (tegra-aic325x, HDA HDMI), ft5x06 input, SurfaceFlinger 1920x1080. Logs in `device-dump/test-runs/`.
- Our kernel has `persistent_ram` (ram console): check `/proc/last_kmsg` after a crash.
- Stock already logs `nvaudio_avp: Failed to open AVP driver` etc.? Not yet compared; check before blaming the kernel.

## Mini recovery (`minirecovery/`, `tools/build-minirecovery.sh`)

- Our busybox script is PID 1 (stock 5.1 init would load SELinux and confine everything). Stock static adbd, static Alpine busybox, setuid `su`, `reboot-to`, `backup-critical`. Run it **only with `fastboot boot`**.
- adbd drops to uid shell and keeps only CAP_SETUID/SETGID in the bounding set: `su` can read block devices but cannot mount or reboot. **`rootrun <cmd>`** runs a command as PID 1 with all capabilities (`rootrun reboot-to bootloader`).
- No devtmpfs in these kernels: mdev fills /dev; init opens up /dev/null, ptmx etc. and gives /dev/android_adb to group adb.
- Static ARM helpers are built in an `--platform linux/arm/v7` Alpine container (Docker Desktop emulation).
- **Backup taken 2026-11-05**: `device-dump/backup-2026-11-05/` (boot0/boot1, the 22 MB area before the GPT, every partition except APP/CAC/UDA, the stock DTB decompiled, md5sums verified). LNX and SOS match the stock 2.0.305 images. **USP is empty** (no pending bootloader blob). DTB partition holds a real FDT ("NVIDIA Tegra114 macallan evaluation board").

## Files

- `device-dump/firmware/1.5/` and `device-dump/firmware/2.0.305/`: the two official images (untracked, never commit).

## Anti-brick rules

- Never flash or erase the bootloader or any partition other than boot (LNX), recovery (SOS), system (APP), cache (CAC), data (UDA). Never `fastboot flash bootloader`, never `fastboot oem lock` (relocking with a custom system may refuse to boot). Leave `dtb` alone until we know whether the stock kernel reads it.
- Never choose "Forced Recovery" (APX/RCM) in the bootloader menu unless we have a tested nvflash/fusée path.
- **Never write USP (`/staging`)**: on NVIDIA devices the bootloader applies a "blob" (bootloader/BCT update) found there at the next boot. A bad blob is a hard brick.
- Keep the stock 2.0.305 boot/recovery/system images: fastboot can always restore them.
- State the risk and get the user's explicit OK before any step that writes to the device.
