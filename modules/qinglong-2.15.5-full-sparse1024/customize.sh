SKIPUNZIP=0
BB=/sbin/.magisk/busybox/busybox
[ -x "$BB" ] || BB=/data/adb/magisk/busybox
[ -x "$BB" ] || BB=/system/bin/busybox
[ -x "$BB" ] || BB=busybox
INSTALL_START_TS="$(date +%s)"
ui_print "- 正在安装青龙 Lite 2.15.5 控制器（全量依赖版）"
ui_print "- 测试说明: 目前仅在小度 X6 / Magisk 30.4 / Android 8.1 / armeabi-v7a 环境实测通过"
ui_print "- 其他设备或其他 Magisk 版本未完整验证，如需使用请自行确认兼容性"
ui_print "- 模块 ID: qinglong_lite_2155"
ui_print "- 模块版本: 2.15.5-lite.1 (2023013001)"
ui_print "- Magisk 版本: $MAGISK_VER ($MAGISK_VER_CODE)"
ui_print "- 设备架构: $ARCH"
ui_print "- 测试设备: 小度 X6"
ui_print "- 目标环境: Magisk 30.4 / Android armv7"
ui_print "- 内置青龙 rootfs: Alpine armv7，基于青龙 2.15.5 (20230130)"
ui_print "- 刷入过程中会自动部署 rootfs"
ui_print "- Rootfs 存储方式: 1024MB 稀疏 ext4 镜像文件，避免 /data inode 耗尽"
ui_print "- 刷入完成后会启用开机自启"
ui_print "- 启动保护已启用: 延迟启动 + 内存检查 + 异常自动停止"

set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/system/bin/qlctl" 0 0 0755
set_perm "$MODPATH/system/bin/qlguard" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "- 正在检查 CPU 架构"
case "$ARCH" in
  arm)
    ui_print "- CPU 架构符合要求: $ARCH"
    ;;
  *)
    abort "! 此模块仅支持 32 位 ARM，当前架构: $ARCH"
    ;;
esac


rebuild_ql_pnpm_links() {
  QL_DIR=/data/local/ql-rootfs/alpine/ql
  [ -d "$QL_DIR/node_modules/.pnpm" ] || return 0
  cd "$QL_DIR" 2>/dev/null || return 0
  mkdir -p node_modules
  for pkgdir in node_modules/.pnpm/*/node_modules/*; do
    [ -e "$pkgdir" ] || continue
    name=$(basename "$pkgdir")
    parent=$(basename "$(dirname "$pkgdir")")
    case "$parent" in
      @*)
        mkdir -p "node_modules/$parent"
        target="node_modules/$parent/$name"
        rel="../.pnpm/$(basename "$(dirname "$(dirname "$pkgdir")")")/node_modules/$parent/$name"
        ;;
      *)
        target="node_modules/$name"
        rel=".pnpm/$(basename "$(dirname "$(dirname "$pkgdir")")")/node_modules/$name"
        ;;
    esac
    [ -e "$target" ] || ln -s "$rel" "$target" 2>/dev/null || true
  done
  return 0
}

ui_print "- 正在检查内置 rootfs 压缩包"
mkdir -p /data/local/ql /data/local/ql/log
rm -f /data/local/ql/ql-rootfs-armv7.tar.gz
if ! unzip -p "$ZIPFILE" "assets/ql-rootfs-armv7.tar.gz" >/data/local/ql/ql-rootfs-armv7.tar.gz 2>/dev/null; then
  abort "! 模块包缺少 assets/ql-rootfs-armv7.tar.gz"
fi
if [ ! -s /data/local/ql/ql-rootfs-armv7.tar.gz ]; then
  abort "! 解出的 rootfs 压缩包为空"
fi
ROOTFS_SIZE="$(du -h /data/local/ql/ql-rootfs-armv7.tar.gz 2>/dev/null | awk '{print $1}')"
ui_print "- 内置 rootfs 大小: ${ROOTFS_SIZE:-unknown}"

ui_print "- 当前 /data 空间占用:"
df -h /data 2>/dev/null | while read line; do ui_print "  $line"; done
ui_print "- 当前 /data inode 状态:"
stat -f /data 2>/dev/null | grep -E 'Blocks|Inodes' | while read line; do ui_print "  $line"; done

ui_print "- 正在准备青龙数据目录"
mkdir -p /data/local/ql /data/local/ql/log

ui_print "- 正在部署青龙 rootfs 到 /data/local/ql-rootfs"
{
  echo "[进度 01/08][12%] ██░░░░░░░░░░░░░░ 停止旧进程并卸载旧挂载点"
  echo "开始安装青龙 Lite rootfs"
  echo "正在停止旧的青龙进程"
  if command -v qlctl >/dev/null 2>&1; then
    qlctl stop >/dev/null 2>&1 || true
  fi
  [ -x /system/bin/qlctl ] && /system/bin/qlctl stop >/dev/null 2>&1 || true
  pkill -f "nginx.conf" 2>/dev/null || true
  pkill -f "PM2" 2>/dev/null || true
  pkill -f "static/build/app.js" 2>/dev/null || true
  pkill -f "static/build/public.js" 2>/dev/null || true
  pkill -f "static/build/schedule.js" 2>/dev/null || true
  "$BB" fuser -k /data/local/ql-rootfs 2>/dev/null || true
  sleep 2
  for target in /data/local/ql-rootfs/alpine/dev/pts /data/local/ql-rootfs/alpine/dev /data/local/ql-rootfs/alpine/sys /data/local/ql-rootfs/alpine/proc; do
    grep -q " $target " /proc/mounts && umount -l "$target" 2>/dev/null
  done
  grep -q " /data/local/ql-rootfs " /proc/mounts && umount -l /data/local/ql-rootfs 2>/dev/null
  sleep 1
  echo "[进度 02/08][25%] ████░░░░░░░░░░░░ 清理旧 rootfs 镜像"
  echo "正在删除旧的 rootfs 镜像"
  chmod -R 777 /data/local/ql-rootfs 2>/dev/null
  rm -rf /data/local/ql-rootfs 2>/dev/null
  rm -f /data/local/ql/rootfs.ext4
  mkdir -p /data/local/ql-rootfs
  DATA_AVAIL_MB=$(df -k /data 2>/dev/null | awk 'END { if (NF == 5) print int($3/1024); else print int($4/1024) }')
  [ -n "$DATA_AVAIL_MB" ] || DATA_AVAIL_MB=0
  echo "当前 /data 可用空间: ${DATA_AVAIL_MB}MB"
  if [ "$DATA_AVAIL_MB" -lt 700 ]; then
    echo "空间不足: 创建 1024MB 稀疏 rootfs 镜像至少建议 /data 可用 450MB，请先卸载旧挂载或清理空间"
    exit 1
  fi
  echo "[进度 03/08][37%] ██████░░░░░░░░░░ 创建 1024MB 稀疏 ext4 rootfs 镜像"
  echo "正在创建 ext4 rootfs 镜像"
  "$BB" dd if=/dev/zero of=/data/local/ql/rootfs.ext4 bs=1M count=0 seek=1024 || exit 1
  mke2fs -F -m 0 /data/local/ql/rootfs.ext4
  echo "[进度 04/08][50%] ████████░░░░░░░░ 挂载 rootfs 镜像"
  echo "正在挂载 ext4 rootfs 镜像"
  "$BB" mount -o loop,rw /data/local/ql/rootfs.ext4 /data/local/ql-rootfs
  if ! grep -q " /data/local/ql-rootfs " /proc/mounts; then
    echo "挂载 rootfs 镜像失败"
    exit 1
  fi
  echo "[进度 05/08][62%] ██████████░░░░░░ 解压青龙 rootfs 压缩包"
  echo "正在解压 rootfs 压缩包"
  tar -xzf /data/local/ql/ql-rootfs-armv7.tar.gz -C /data/local/ql-rootfs
  echo "[进度 06/08][75%] ████████████░░░░ 安装 PM2 修复组件"
  echo "正在安装 pm2 修复组件"
  unzip -p "$ZIPFILE" "assets/pm2-overlay-armv7.tar.gz" | gzip -dc | tar -xf - -C /data/local/ql-rootfs || exit 1
  mkdir -p /data/local/ql-rootfs/alpine/usr/local/bin
  cat > /data/local/ql-rootfs/alpine/usr/local/bin/pm2 <<'EOF'
#!/bin/sh
exec node /root/.local/share/pnpm/global/5/.pnpm/pm2@5.2.0/node_modules/pm2/bin/pm2 "$@"
EOF
  chmod 755 /data/local/ql-rootfs/alpine/usr/local/bin/pm2
  echo "[进度 07/08][87%] ██████████████░░ 解压全量依赖"
  echo "正在解压青龙 2.15.5 全量依赖"
  unzip -p "$ZIPFILE" "assets/ql2155-deps-overlay.tar.gz" | gzip -dc | tar -xf - -C /data/local/ql-rootfs || exit 1
  rm -rf /data/local/ql-rootfs/alpine/root/.local/share/pnpm/store 2>/dev/null
  echo "正在重建 PNPM 依赖链接"
  rebuild_ql_pnpm_links || true
  if unzip -l "$ZIPFILE" "assets/ql-python310-overlay.tar.gz" >/dev/null 2>&1; then
    echo "正在解压 Python3/pip 离线运行时"
    unzip -p "$ZIPFILE" "assets/ql-python310-overlay.tar.gz" | gzip -dc | tar -xf - -C /data/local/ql-rootfs/alpine || exit 1
    /data/local/ql-rootfs/alpine/usr/bin/python3 --version || true
    /data/local/ql-rootfs/alpine/usr/bin/pip3 --version || true
  fi
  if [ ! -x /data/local/ql-rootfs/alpine/bin/busybox ]; then
    echo "Rootfs 无效: 缺少 /alpine/bin/busybox"
    exit 1
  fi
  mkdir -p /data/local/ql-rootfs/alpine/proc /data/local/ql-rootfs/alpine/sys /data/local/ql-rootfs/alpine/dev /data/local/ql-rootfs/alpine/tmp
  chmod 1777 /data/local/ql-rootfs/alpine/tmp 2>/dev/null
  echo "Rootfs 已准备完成"
  echo "正在初始化默认登录账号"
  mkdir -p /data/local/ql-rootfs/alpine/ql/data/config
  cat > /data/local/ql-rootfs/alpine/ql/data/config/auth.json <<'EOF'
{"username":"admin","password":"admin123"}
EOF
  chmod 600 /data/local/ql-rootfs/alpine/ql/data/config/auth.json 2>/dev/null
  echo "[进度 08/08][100%] ████████████████ 检查运行环境并写入诊断日志"
  echo "青龙 Lite 模块: qinglong_lite_2155"
  echo "ABI: $(getprop ro.product.cpu.abi)"
  echo "ABI list: $(getprop ro.product.cpu.abilist)"
  echo "Android: $(getprop ro.build.version.release) SDK $(getprop ro.build.version.sdk)"
  df -h /data /sdcard 2>/dev/null
  stat -f /data | grep -E 'Blocks|Inodes'
  mount -t proc proc /data/local/ql-rootfs/alpine/proc 2>/dev/null
  mount -t sysfs sysfs /data/local/ql-rootfs/alpine/sys 2>/dev/null
  mount -o bind /dev /data/local/ql-rootfs/alpine/dev 2>/dev/null
  "$BB" chroot /data/local/ql-rootfs/alpine /bin/sh -lc "
    export HOME=/root PM2_HOME=/root/.pm2 QL_DIR=/ql PATH=/usr/local/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node_modules/.bin:\$PATH
    echo Rootfs 系统信息:
    [ -f /etc/os-release ] && sed -n '1,8p' /etc/os-release || true
    echo 运行环境版本:
    command -v node >/dev/null 2>&1 && echo node=\$(node -v) || echo node=missing
    command -v npm >/dev/null 2>&1 && echo npm=\$(npm -v) || echo npm=missing
    command -v pnpm >/dev/null 2>&1 && echo pnpm=\$(pnpm -v) || echo pnpm=missing
    command -v pm2 >/dev/null 2>&1 && echo pm2=\$(pm2 -v 2>/dev/null | tail -1) || echo pm2=missing
    command -v nginx >/dev/null 2>&1 && echo nginx=\$(nginx -v 2>&1) || echo nginx=missing
    if [ -d /ql ]; then
      echo 青龙目录: /ql
      [ -f /ql/package.json ] && echo 青龙 package 版本: \$(grep '\"version\"' /ql/package.json | head -1 | sed 's/[\", ]//g')
      [ -f /ql/version.yaml ] && echo 青龙 version.yaml: \$(cat /ql/version.yaml | tr '\n' ' ')
    else
      echo 缺少 /ql 目录
    fi
  "
  for target in /data/local/ql-rootfs/alpine/dev /data/local/ql-rootfs/alpine/sys /data/local/ql-rootfs/alpine/proc; do
    grep -q " $target " /proc/mounts && umount -l "$target" 2>/dev/null
  done
  grep -q " /data/local/ql-rootfs " /proc/mounts && umount -l /data/local/ql-rootfs 2>/dev/null
  echo "__QL_ROOTFS_INSTALL_OK__"
} 2>&1 | tee /data/local/ql/log/install.log
if grep -q "__QL_ROOTFS_INSTALL_OK__" /data/local/ql/log/install.log 2>/dev/null; then
  ui_print "- Rootfs 部署完成"
else
  ui_print "! Rootfs 部署失败"
  ui_print "! 日志: /data/local/ql/log/install.log"
  abort "! 青龙 rootfs 部署失败"
fi

ui_print "- 运行环境检测结果:"
grep -E '青龙 package 版本|青龙 version.yaml|node=|npm=|pnpm=|pm2=|nginx=' /data/local/ql/log/install.log 2>/dev/null | while read line; do
  ui_print "  $line"
done

ui_print "- 安装诊断日志:"
ui_print "  /data/local/ql/log/install.log"

ui_print "- 正在启用开机自启"
touch /data/local/ql/autostart
rm -f /data/local/ql/autostart.disabled-by-guard
echo 0 >/data/local/ql/boot_fail_count
rm -f /data/local/ql/ql-rootfs-armv7.tar.gz

ui_print "- 模块安装完成"
INSTALL_END_TS="$(date +%s)"
INSTALL_COST=$((INSTALL_END_TS - INSTALL_START_TS))
ui_print "- 本次模块安装耗时: ${INSTALL_COST} 秒"
ui_print "- 请重启设备，青龙面板会自动启动"
ui_print "- 启动保护: 开机后等待 45 秒，并检查内存 120 秒"
ui_print "- 如果启动后系统不稳定，保护脚本会自动停止青龙"
ui_print "- 连续 2 次启动失败后会自动关闭开机自启"
ui_print "- 启动日志: /data/local/ql/log/start.log"
ui_print "- 启动保护日志: /data/local/ql/log/guard.log"
