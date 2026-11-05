/*
 * Minimal su for the sk1wg mini recovery (same helper as Galaxy Camera
 * Revived's mini recovery).
 *
 * The stock 5.1 adbd is a "user" build: it always drops to the shell uid.
 * This setuid-root helper gives the adb shell uid 0. It is only ever
 * installed in the mini recovery ramdisk, never in a system image.
 *
 * Build: a static ARM binary, e.g. musl:
 *   arm-linux-musleabihf-gcc -static -Os -o su su.c
 *
 * Usage: su            interactive root shell
 *        su -c "cmd"   run one command as root
 */
#include <grp.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (setgid(0) || setgroups(0, NULL) || setuid(0)) {
        perror("su");
        return 1;
    }
    if (argc > 2 && strcmp(argv[1], "-c") == 0)
        execl("/sbin/sh", "sh", "-c", argv[2], (char *)NULL);
    else
        execl("/sbin/sh", "sh", (char *)NULL);
    perror("su: exec /sbin/sh");
    return 1;
}
