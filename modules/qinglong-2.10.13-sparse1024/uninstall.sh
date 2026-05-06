#!/system/bin/sh
MODDIR=${0%/*}

if [ -x "$MODDIR/system/bin/qlctl" ]; then
  "$MODDIR/system/bin/qlctl" stop >/dev/null 2>&1
fi
