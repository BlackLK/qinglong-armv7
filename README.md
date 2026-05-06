# QingLong Magisk Lite ARMv7 Modules

这是面向 32 位 ARM 设备的青龙 Magisk 模块整理仓库，当前模板基于小度 X6 / Android 8.1 / Magisk 30.4 / `armeabi-v7a` 实测整理。

## 包列表

| 模块 | 说明 | 推荐程度 |
| --- | --- | --- |
| `QL-2.10.13-sparse1536-stuka.zip` | QingLong 2.10.13，1536MB 稀疏 ext4 rootfs | 可用 |
| `QL-2.15.5-full-sparse1536-stuka.zip` | QingLong 2.15.5，全量依赖，1536MB 稀疏 ext4 rootfs | 推荐 |
| `QL-2.15.5-online-sparse1536-stuka.zip` | QingLong 2.15.5，安装时联网下载依赖 | 不推荐作稳定包 |

## 设备支持

仅支持 32 位 ARM：

```text
armeabi-v7a
armeabi
```

不支持 `arm64-v8a`、`x86`、`x86_64`。

## 主要特性

- 使用 `/data/local/ql/rootfs.ext4` 作为 rootfs 镜像。
- rootfs 逻辑大小为 1536MB。
- 使用稀疏 ext4 镜像：`ls` 显示 1.5G，但真实占用随内容增长。
- 避免目录 rootfs 在低 inode 设备上耗尽 inode。
- 移除自动扩容和手动扩容逻辑。
- 默认登录账号：`admin` / `admin123`。
- `qlctl python` 可单独安装 Python3 运行时。

## 目录结构

```text
modules/
  qinglong-2.10.13-sparse1536/
  qinglong-2.15.5-full-sparse1536/
  qinglong-2.15.5-online-sparse1536/
release/
  QL-*.zip
tools/
  build.py
  check.py
```

## GitHub 上传注意

仓库里包含较大的二进制资源：

- `assets/ql-rootfs-armv7.tar.gz`
- `assets/pm2-overlay-armv7.tar.gz`
- `assets/ql2155-deps-overlay.tar.gz`
- `release/*.zip`

其中部分文件超过 GitHub 普通文件 100MB 限制。请使用 Git LFS：

```sh
git lfs install
git lfs track "*.tar.gz" "*.tgz" "*.tar.xz" "*.zip"
git add .gitattributes
```

如果不想使用 Git LFS，可以只上传源码脚本，二进制资源和 release zip 放到 GitHub Releases。

## 打包

在仓库根目录执行：

```sh
python tools/build.py
```

输出文件会生成到：

```text
release/
```

## 校验

```sh
python tools/check.py
```

校验内容包括：

- zip 完整性
- 稀疏镜像创建逻辑
- busybox loop mount
- 默认初始化账号
- `qlctl python` 命令
- 无旧扩容逻辑残留

## 安装

将 zip 放到设备后，在 Magisk 中刷入，或使用：

```sh
su -c 'magisk --install-module /sdcard/Download/QL-2.15.5-full-sparse1536-stuka.zip'
```

刷入后建议重启设备。

## 常用命令

```sh
su -c qlctl status
su -c qlctl start
su -c qlctl stop
su -c qlctl restart
su -c qlctl logs
su -c qlctl doctor
su -c qlctl python
```

## Python 脚本支持

稳定包默认不在刷入阶段联网安装 Python3，避免安装过程卡住。

需要运行 Python 脚本时执行：

```sh
su -c qlctl python
```

它会安装：

```text
python3
py3-pip
py3-requests
py3-yaml
py3-cryptography
py3-certifi
```

## 已知问题

- 在线版依赖 GitHub / npm 网络，可能卡在 `@louislam/sqlite3` 下载，不建议作为稳定包。
- 2.15.5 full 版为当前推荐稳定包。
- 默认密码为公开值，首次登录后建议修改。

## 免责声明

仅在特定 32 位 ARM 环境实测。刷机和 Magisk 模块均有风险，请自行备份并承担风险。
