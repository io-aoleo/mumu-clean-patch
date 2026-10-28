# MuMu Clean Patch

MuMu 模拟器去广告、禁更新补丁。**补丁版本 1.0.0，适配 Windows MuMu 6.8.8.0（安卓 15）。**

下载：[补丁包 v1.0.0](https://github.com/io-aoleo/mumu-clean-patch/raw/refs/heads/main/downloads/mumu-clean-patch-v1.0.0-MuMu-6.8.8.0.zip) · [SHA256 校验](downloads/mumu-clean-patch-v1.0.0-MuMu-6.8.8.0.zip.sha256)

这是可检查源码、可恢复的独立脚本补丁，不是反编译或重新分发的 MuMu 安装器，不包含 MuMu 二进制、安卓镜像、用户数据或账号信息。

## 使用

1. 安装 MuMu **6.8.8.0**，启动安卓实例。停止正在进行的更新。
2. 下载本仓库 ZIP 并完整解压；双击 `Apply.cmd`。遇到访问被拒绝时可右键以管理员身份运行。
3. 完全退出并重新打开 MuMu。双击 `Check.cmd` 可查看状态。

脚本自动从注册表查找唯一的 MuMu 安装位置。找不到或有多份安装时，可在 PowerShell 指定：

```powershell
.\Patch.ps1 -Mode Apply -InstallPath 'E:\MuMuPlayer'
```

自定义 Windows 广告缓存位置时另外指定 `-DataPath`。`-SkipAndroid` 可只处理电脑端。

## 修改内容

| 项目 | 方法 | 影响 |
| --- | --- | --- |
| 开屏广告 | 备份 `startupImage`，用只读空文件占住原路径 | 阻止该缓存目录重建 |
| 电脑端推广缓存 | 同样处理 `ProgramAds` | 阻止该缓存目录重建 |
| 更新程序 | 备份 `nx_main/MuMuNxUpdater.exe`，在原路径放只读空文件 | 阻止此更新程序执行，自动和手动更新均受影响 |
| 安卓应用中心 | 已运行实例具有其他默认桌面时，停用 `com.mumu.store` | MuMu 商店下载入口停用，安装应用和数据保留 |

Android 步骤通过 MuMu 自带的 CLI / ADB 完成，不自动安装桌面、不启用 root、不擦除应用数据。若仍使用原 MuMu 桌面，会跳过应用中心停用，避免失去桌面；可先自行安装并选择 Lawnchair 等桌面，再运行补丁。未运行的实例需要启动后再运行补丁。

电脑端 `blocked=True` 表示目标已被阻断；Android 输出 `disabled-user` 或 `package:com.mumu.store` 表示已停用。跳过或失败的 Android 步骤会给出警告，不代表安卓广告已处理。

## 恢复

退出 MuMu 后双击 `Restore.cmd` 恢复缓存目录和原更新程序。启动安卓实例，再运行一次 `Restore.cmd`，恢复应用中心的默认启用状态。原来的第三方默认桌面保持不变。

备份保留在原文件/目录旁，后缀为 `.mumu-clean-backup`。也兼容此前使用 `.disabled-20261028` 后缀的备份。不要删除备份。恢复时只移除经过检查的空占位文件，不覆盖已有非空文件。

## 范围与验证

- 只允许在 6.8.8.0 上应用；其他版本会拒绝。不同版本的广告实现和更新方式可能不同。
- 不修改 Windows 电源设置，不拦截游戏或视频 App 自己的广告。
- 本补丁阻断已定位的缓存路径和更新程序，不保证移除所有广告界面；重新安装、修复或版本升级可能撤销补丁。
- 本机验证：MuMu 6.8.8.0、安卓 15；独立临时目录验证应用/重复应用/恢复和版本检查。未完成其他电脑上的全新安装验证。

MuMu 及相关商标归各自权利人所有。本项目与网易无关联。
