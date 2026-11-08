# Kernel for the Jide Remix Ultra Tablet (branch `sk1wg`)

<!-- Draft for the kernel fork. Put it in the sk1wg branch as README.sk1wg.md (or similar), so
     the upstream README stays untouched. Before a release, drop the bring-up aids listed under
     "Bring-up aids" from the defconfig and the device tree. -->

NVIDIA's Linux 3.4 kernel for the Tegra 4 `macallan` board, from [TerenceWSK's CyanogenMod 13 kernel](https://github.com/TerenceWSK/cm_android_kernel_jide_sk1wg_sk1w) for the **Jide Remix Ultra Tablet** (REMIX SK1WG), with what LineageOS 21 (Android 14) needs. Defconfig: `lineageos_sk1wg_defconfig`, version suffix `-sk1wg`.

Project home and docs: https://github.com/simoneluconi/JideRemixTabletRevived

## What the sk1wg branch adds

- **From LineageOS's Tegra 4 kernel** (`android_kernel_nvidia_roth`, `lineage-15.1`, cherry-picked with `-x`): ambient capabilities; the binder series (64-bit ABI, binder/hwbinder/vndbinder, scatter-gather, fd arrays); kuid/userns; UID routing (FRA_UID_RANGE); no_new_privs; seccomp-bpf with TSYNC and the `seccomp` syscall; mount-namespace `setns()` and `/proc/<pid>/ns/*` inode numbers; `mmap_rnd_bits`.
- **From html6405's Exynos 4412 kernel**: getrandom, memfd_create with the sealing definitions, ARM 8-byte `get_user()`, timerfd alarm clocks and CLOCK_BOOTTIME, the binder sender security context.
- **Ours**:
  - syscall wiring (384 getrandom, 385 memfd_create; 382 reserved for renameat2, not backported);
  - `fstat()` on O_PATH file descriptors (bionic's `realpath()`), sub-threads allowed their own `/proc/self/fd`;
  - SELinux reads upstream extended permissions again (the CM13 tree had Android 6's ioctl format);
  - binder: `BC_DEAD_BINDER_DONE` cookie size, transaction size checks;
  - nexthop lookups in the route's own table first (Android's default route on Wi-Fi);
  - a system-heap-only ION device for Codec2 (`CONFIG_ION_SYSTEM_ONLY`), with fixes to the 3.4 ION core;
  - `sw_keys` reports the keyboard cover's lid switch both ways;
  - EMC activity monitor tuning for smooth scrolling;
  - cpuset `allow_attach` and cpus kept across hotplug, `CONFIG_CMDLINE_EXTEND` for FDT boots, `CONFIG_HW_RANDOM`, no console on the debug UART.

Not backported: eBPF, renameat2, sdcardfs, O_TMPFILE, PR_SET_VMA.

## Bring-up aids

- `CONFIG_TEGRA_PANIC_TO_BOOTLOADER`: a panic restarts into fastboot, so the RAM console can be read from a RAM-booted image. With `oops=panic` on the command line (set by the device tree).

Both go before a release.

## Building

In-tree, from the LineageOS 21 tree (`TARGET_KERNEL_SOURCE := kernel/jide/sk1wg`), with GCC 4.9 (`arm-linux-androideabi-4.9`). Standalone:

```
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- HOSTCFLAGS="-fcommon" lineageos_sk1wg_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- HOSTCFLAGS="-fcommon" -j$(nproc) zImage
```

Stock Remix OS 5.1 needs the 32-bit binder ABI: set `CONFIG_ANDROID_BINDER_IPC_32BIT=y` to boot it on this kernel. LineageOS 21 needs it off (the default).

## Safety

Test every build with `fastboot boot` first (RAM only). The anti-brick rules are in the main repo's `docs/INSTALL.md`: never flash the bootloader, never write the `USP` staging partition, never `fastboot oem lock`, never "Forced Recovery".

## Licence

GPL-2.0, as the Linux kernel.
