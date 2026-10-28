# 桌面方案回退说明

当前 v1.0.2 恢复第一版取舍：**保留原 MuMu 桌面，停用应用中心，下载改用浏览器或自行导入。**

MuMu 6.8.8.0 中预装的 app.lawnchair 是 MuMu 定制桌面，包含游戏推广栏，并使用应用中心提供的推广小组件。停用应用中心可以阻断相关推广来源，但也会影响商店下载及部分导入联动。

曾尝试的“保留应用中心 + Fossify Launcher 1.10.0”方案不再作为当前推荐。Fossify 该版本主屏幕固定竖屏，在本机 MuMu 中出现变窄、布局不符合使用需求的问题；强制横屏也未达到用户预期。

本机现已切回 app.lawnchair/.LawnchairLauncher，撤销后来添加的方向强制设置，并停用应用中心。原应用和布局保留，Fossify 没有被卸载。

若你也手动应用过旧说明中的桌面更换及强制横屏，可按自己实际的备份恢复。以下命令仅适用于默认桌面原本为上述 MuMu 定制桌面、方向原值为 false / free 的实例：

```powershell
& 'E:\MuMuPlayer\nx_main\adb.exe' -s 127.0.0.1:16384 shell cmd package set-home-activity --user 0 app.lawnchair/.LawnchairLauncher
& 'E:\MuMuPlayer\nx_main\adb.exe' -s 127.0.0.1:16384 shell wm set-ignore-orientation-request false
& 'E:\MuMuPlayer\nx_main\adb.exe' -s 127.0.0.1:16384 shell wm user-rotation free
& 'E:\MuMuPlayer\nx_main\adb.exe' -s 127.0.0.1:16384 shell input keyevent 3
```

安装目录、实例端口及原始设置必须以自己机器为准。Apply.cmd 只应用当前补丁，不会自动切换桌面或调整方向。
