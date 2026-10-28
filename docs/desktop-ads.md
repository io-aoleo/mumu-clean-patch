# 保留下载功能并去掉桌面推广

在 MuMu 6.8.8.0 / 安卓 15 的本机排查中，名为 `app.lawnchair` 的预装桌面包含 MuMu 定制的 `searchAdListView` 推广栏，并绑定应用中心提供的“广告轮播”和“每日发现”小组件。

因此不能仅凭 Lawnchair 的包名就认为预装桌面没有广告。停用整个 `com.mumu.store` 虽会让这些广告消失，也会影响商店下载；补丁 v1.0.1 已取消这种做法，并恢复该应用的默认启用状态。

需要保留下载又避免桌面推广时，可使用与 MuMu 定制桌面独立的启动器。本机采用 [Fossify Launcher 官方版](https://github.com/FossifyOrg/Launcher/releases/tag/1.10.0)：

- 版本：1.10.0，包名 `org.fossify.home`。
- 官方文件：`launcher-16-foss-release.apk`。
- 官方发布页 SHA256：`a603d3d510482feafd73d52a93a1ea9baefd2ca0aae329a14cbf0e21f43638e3`。
- 从官方发布页下载并导入 MuMu，安装后在安卓默认应用中选择 Fossify 为主屏幕。
- 原 MuMu 桌面及布局保留；可在默认应用设置中切回。
- 新桌面向上滑动可打开应用列表，原有应用和数据保留。

这会改变桌面布局。进入 MuMu 应用中心后，它自身的推荐页面仍可能显示推广；更换桌面不等于修改应用中心内容。

`Apply.cmd` 不会自动下载或更换启动器。独立桌面的安装与切换是可选的额外步骤。未在其他电脑上完成验证。
