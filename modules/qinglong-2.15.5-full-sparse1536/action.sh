#!/system/bin/sh
echo "青龙2.15.5全量固定镜像版"
echo "Rootfs: /data/local/ql-rootfs"
echo "存储模式: 1536MB ext4 镜像，避免 /data inode 不足"
echo "已移除自动/手动扩容"
echo ""
df -h /data /data/local/ql-rootfs 2>/dev/null || df -h /data 2>/dev/null
echo ""
echo "如需查看青龙状态: su -c qlctl status"
