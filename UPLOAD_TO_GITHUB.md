# 上传到 GitHub

## 1. 必须先安装 Git LFS

因为本仓库包含超过 100MB 的 rootfs 压缩包和 release zip，普通 GitHub push 会失败。

```sh
git lfs install
git lfs track "*.tar.gz" "*.tgz" "*.tar.xz" "*.zip"
```

仓库已包含 `.gitattributes`，正常情况下只需要确认 Git LFS 已安装。

## 2. 初始化仓库

在本目录执行：

```sh
git init
git add .
git commit -m "Initial QingLong Magisk Lite modules"
```

## 3. 关联你的 GitHub 仓库

把下面地址换成你自己的仓库地址：

```sh
git branch -M main
git remote add origin https://github.com/你的用户名/你的仓库名.git
git push -u origin main
```

## 4. 如果不想用 Git LFS

可以只上传源码，删除或不提交这些文件：

```text
modules/*/assets/*.tar.gz
release/*.zip
```

然后把 `release/*.zip` 单独上传到 GitHub Releases。

## 5. 上传前本地校验

```sh
python tools/build.py
python tools/check.py
```

`tools/check.py` 全部为 `True` 后再发布。
