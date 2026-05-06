#!/system/bin/sh
MODDIR=${0%/*}
AUTOSTART_FILE=/data/local/ql/autostart

resetprop -w sys.boot_completed 0

if [ -f "$AUTOSTART_FILE" ]; then
  mkdir -p /data/local/ql/log
  sh /system/bin/qlguard >>/data/local/ql/log/boot.log 2>&1 &
fi
