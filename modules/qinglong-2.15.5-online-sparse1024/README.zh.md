# 青龙 Lite 2.15.5 Magisk 模块（联网依赖版）

适用于小度 X6 等 32 位 ARM/armeabi-v7a 设备。

## 特点

- 基于青龙 2.15.5 (20230130)
- 兼容 Magisk 30.4
- 刷入时自动部署 Alpine armv7 rootfs
- 刷入时联网执行 `pnpm install --prod` 安装青龙依赖
- 安装日志带中文说明
- 重启后自动启动青龙面板
- 使用 ext4 镜像存放 rootfs，减少 `/data` inode 压力
- 带启动保护，防止低内存设备开机卡死

## 重要路径

```text
/data/local/ql-rootfs/alpine
/data/local/ql/rootfs.ext4
/data/local/ql/log/install.log
/data/local/ql/log/install-deps.log
/data/local/ql/log/start.log
/data/local/ql/log/guard.log
```

## 面板地址

```text
http://设备IP:5700
```

## 常用命令

```sh
su
qlctl status
qlctl doctor
qlctl logs
qlctl start
qlctl stop
qlctl restart
```

## 说明

这个版本不内置完整 `node_modules`，会在刷入模块时联网下载并安装依赖。刷入完成后请重启设备，重启后青龙面板会直接启动。
