# Magisk 30 QingLong Lite Template

This template follows the Magisk Developer Guides module structure.

Official reference:

- https://topjohnwu.github.io/Magisk/guides.html

## Files

- `module.prop`: module metadata.
- `customize.sh`: installer customization script sourced by Magisk installer.
- `service.sh`: late_start service script. It starts the boot guard when `/data/local/ql/autostart` exists.
- `uninstall.sh`: stops QingLong during module removal.
- `system/bin/qlctl`: QingLong deploy/start/stop/status command.
- `system/bin/qlguard`: delayed boot startup guard with memory checks and autostart fail-safe.

## Rootfs path

This controller expects rootfs at:

```text
/data/local/ql-rootfs
```

QingLong project path inside rootfs:

```text
/ql
```

## Commands

```sh
su
qlctl status
qlctl doctor
qlctl start
qlctl stop
qlctl restart
qlctl logs
qlctl shell
qlctl enable-autostart
qlctl disable-autostart
```

## Magisk action button

Clicking this module in Magisk runs `action.sh`. It shows current status and the commands you should run.

QingLong rootfs is deployed during installation, and autostart is enabled by default.

## Installation behavior

This package includes an Alpine armv7 QingLong rootfs at:

```text
assets/ql-rootfs-armv7.tar.gz
```

You can also replace it with another armv7/armhf rootfs archive at one of these paths:

```text
/sdcard/Download/ql-rootfs-armv7.tar.gz
/sdcard/Download/ql-rootfs-armv7.tar.xz
assets/ql-rootfs-armv7.tar.gz
assets/ql-rootfs-armv7.tar.xz
```

During module installation, `customize.sh` automatically runs:

```sh
qlctl bootstrap-force
touch /data/local/ql/autostart
```

The Magisk install screen prints:

- module id and version;
- Magisk version and detected architecture;
- embedded rootfs package information;
- `/data` storage and inode status;
- rootfs deployment result;
- QingLong, Node.js, npm, pnpm, pm2, and nginx version summary;
- boot guard policy and log paths.

After reboot, `service.sh` automatically runs `qlguard`.

## Boot guard

After reboot, `service.sh` runs `qlguard` instead of starting QingLong immediately.

Guard behavior:

- waits 45 seconds before starting QingLong;
- checks `MemAvailable` before startup;
- monitors memory for 120 seconds after startup;
- stops QingLong if memory is too low;
- increments `/data/local/ql/boot_fail_count` on failed startup;
- disables autostart after 2 failed startups by removing `/data/local/ql/autostart`;
- writes logs to `/data/local/ql/log/guard.log`.

## Package as zip

Zip the contents of this folder directly. `module.prop` must be at the top level of the zip.

Do not put this folder itself as an extra top-level directory inside the zip.

## Notes for low-end 32-bit devices

For armeabi-v7a devices, use an armv7/armhf rootfs. Do not use arm64 rootfs or arm64 Node.js.

This module deploys the embedded rootfs during flashing, but does not run network package installation during flashing.
