/*
 * reboot-to: reboot with a reason string, for the sk1wg mini recovery.
 *
 * busybox "reboot" cannot pass a reason, and there is no Android init to
 * handle "adb reboot bootloader". NVIDIA's 3.4 kernel turns the reason
 * "bootloader" into the flag that makes the bootloader stop in fastboot,
 * and "recovery" into a boot of the recovery partition.
 *
 * Build: a static ARM binary, e.g. musl:
 *   gcc -static -Os -o reboot-to reboot-to.c   (on armv7 Alpine)
 *
 * Usage (as root): reboot-to [bootloader|recovery|""]
 */
#include <linux/reboot.h>
#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    const char *reason = argc > 1 ? argv[1] : "";

    sync();
    syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2,
            LINUX_REBOOT_CMD_RESTART2, reason);
    perror("reboot-to");
    return 1;
}
