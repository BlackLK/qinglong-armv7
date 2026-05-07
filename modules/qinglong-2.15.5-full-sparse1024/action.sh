#!/system/bin/sh
echo "青龙2.15.5全量固定镜像版"
echo "Rootfs: /data/local/ql-rootfs"
echo "存储模式: 1024MB ext4 镜像，避免 /data inode 不足"
echo "已移除自动/手动扩容"
echo ""
df -h /data /data/local/ql-rootfs 2>/dev/null || df -h /data 2>/dev/null
echo ""
echo "如需查看青龙状态: su -c qlctl status"

echo ""
echo "正在尝试启动/检查青龙..."
if [ -x /system/bin/qlctl ]; then
  sh /system/bin/qlctl start
  sh /system/bin/qlctl status
elif [ -x /data/adb/modules/qinglong_lite_2155/system/bin/qlctl ]; then
  sh /data/adb/modules/qinglong_lite_2155/system/bin/qlctl start
  sh /data/adb/modules/qinglong_lite_2155/system/bin/qlctl status
else
  echo "未找到 qlctl"
fi
