# Tiny11 Dev Edition 说明文档

## 版本信息

- **版本**: Dev Edition v1.6
- **发布日期**: 2026-01-05
- **基于**: tiny11maker.ps1
- **审核**: Opus 模型

---

## 三个版本概述

| 版本 | 文件名 | 定位 | 适用场景 |
|------|--------|------|----------|
| **Maker** | tiny11maker.ps1 | 标准精简版 | 普通用户日常使用 |
| **Dev** | tiny11maker-Dev.ps1 | 开发者优化版 | 软件/硬件开发人员 |
| **Coremaker** | tiny11Coremaker.ps1 | 极端精简版 | 测试/虚拟机/研究 |

---

## 功能对比总表

### 保留的组件

| 组件 | Maker | Dev | Coremaker | 说明 |
|------|:-----:|:--------:|:---------:|------|
| **Edge 浏览器** | 否 | 是 | 否 | 开发调试需要 |
| **Edge WebView2** | 否 | 是 | 否 | 现代应用依赖 |
| **照片查看器** | 是 | 是 | 是 | 基本功能 |
| **截图工具** | 是 | 是 | 是 | 基本功能 |
| **画图 (mspaint)** | 是 | 是 | 是 | 系统组件 |
| **计算器** | 是 | 是 | 是 | 基本功能 |
| **Windows Store** | 是 | 是 | 是 | 安装应用 |
| **Windows Terminal** | 是 | 是 | 是 | 终端工具 |

### 系统服务和功能

| 功能 | Maker | Dev | Coremaker | 说明 |
|------|:-----:|:--------:|:---------:|------|
| **Windows Update** | 是 自动 | 是 手动 | 否 禁用 | 系统更新 |
| **在线驱动安装** | 是 | 是 | 否 | 硬件支持 |
| **Windows Defender** | 是 | 是 | 否 | 安全防护 |
| **WinRE (恢复环境)** | 是 | 是 | 否 | 故障恢复 |
| **WinSxS 完整** | 是 | 是 | 否 | 可维护性 |
| **可添加功能** | 是 | 是 | 否 | 扩展性 |

### 精简内容

| 移除项 | Maker | Dev | Coremaker | 说明 |
|--------|:-----:|:--------:|:---------:|------|
| **预装 AppX** | 是 | 是 | 是 | 30+ 应用 |
| **OneDrive** | 是 | 是 | 是 | 云存储 |
| **Teams** | 是 | 是 | 是 | 通讯应用 |
| **Copilot** | 是 | 是 | 是 | AI 助手 |
| **Edge 浏览器** | 是 | 否 | 是 | 浏览器 |
| **微软电脑管家** | 否 | 是 | 否 | PC Manager |
| **扩展壁纸** | 否 | 是 | 是 | ~300-500MB |
| **系统包 (IE/WMP等)** | 否 | 否 | 是 | 系统功能 |

### 后台服务优化

| 服务 | Maker | Dev | Coremaker | 说明 |
|------|:-----:|:--------:|:---------:|------|
| **Windows Search** | 是 自动 | [手动] 手动 | 是 自动 | 文件索引 |
| **Widgets 服务** | 是 运行 | 否 禁用 | 是 运行 | 新闻和兴趣（仅通过策略关闭，不影响系统通知） |
| **搜索突出显示** | 是 启用 | 否 禁用 | 是 启用 | 动态搜索内容 |
| **Xbox 服务** | 是 运行 | 否 禁用 | 是 运行 | 4个后台服务 |
| **遥测服务** | 是 运行 | 否 禁用 | 否 禁用 | 数据收集 |
| **锁屏聚焦** | 是 启用 | 否 禁用 | 是 启用 | 天气/新闻/提示 |
| **Edge 新闻** | 是 启用 | 否 禁用 | 是 启用 | 新标签页内容 |

---

## Dev Edition 独有功能

### 0. 额外精简优化

**仅 Dev Edition 执行：**

| 优化项 | 节省资源 | 说明 |
|--------|----------|------|
| **删除扩展壁纸** | ~300-500 MB 磁盘 | 仅保留基本壁纸 |
| **禁用 Widgets** | ~50-100 MB 内存 | 关闭新闻和兴趣 |
| **禁用搜索突出显示** | 减少网络请求 | 关闭动态搜索内容 |
| **禁用 Xbox 服务** | ~20-50 MB 内存 | 关闭 4 个后台服务 |

**禁用的 Xbox 服务：**
- XblAuthManager (Xbox Live 身份验证)
- XblGameSave (Xbox 云存档)
- XboxGipSvc (Xbox 外设)
- XboxNetApiSvc (Xbox 网络)

### 0.15 是 重要说明：不禁用系统通知服务

Dev Edition **不会**禁用 `WpnService`（Windows Push Notifications）。  
原因：禁用它会影响系统/应用通知（包括部分 UWP 通知），副作用远大于收益。

### 0.1 Windows Search 优化

**Dev Edition 将 Windows Search 设为手动启动：**

| 对比项 | Windows Search | Everything |
|--------|:--------------:|:----------:|
| 搜索速度 | 慢（依赖索引） | **毫秒级** |
| 内存占用 | ~50-150 MB | ~10-30 MB |
| 磁盘 I/O | 高（建立索引） | **极低** |
| 功能 | 内容搜索 | 文件名搜索 |
| 价格 | 内置 | **免费** |

**推荐安装 Everything：**

> 链接： 官方下载：https://www.voidtools.com/zh-cn/downloads/

**Everything 特点：**
- * 毫秒级搜索速度（即时显示结果）
-  极低资源占用（~10 MB 内存）
- 🔧 支持正则表达式搜索
- 📁 实时监控文件变化
-  完全免费，无广告

**注意：** Windows Search 设为手动后，开始菜单搜索可能变慢。如需恢复：
```powershell
# 设置为自动启动
Set-Service -Name "WSearch" -StartupType Automatic
Start-Service -Name "WSearch"
```

### 0.2 🔒 锁屏界面优化

**禁用的锁屏内容：**
| 内容 | 状态 |
|------|:----:|
| Windows 聚焦 (Spotlight) | 否 禁用 |
| 天气信息 | 否 禁用 |
| 新闻推送 | 否 禁用 |
| 趣味知识/提示 | 否 禁用 |
| 欢迎体验 | 否 禁用 |

**效果：** 锁屏界面显示纯净壁纸，无广告干扰。

### 0.3 🌐 Edge 浏览器优化

**禁用的 Edge 功能：**
| 功能 | 状态 | 说明 |
|------|:----:|------|
| 新标签页新闻 | 否 禁用 | 无推送内容 |
| 快速链接推荐 | 否 禁用 | 无网站推荐 |
| 侧边栏 (Copilot) | 否 禁用 | 无 AI 弹窗 |
| 首次运行体验 | 否 跳过 | 无引导流程 |
| 购物助手 | 否 禁用 | 无购物提示 |
| 集锦功能 | 否 禁用 | 简化界面 |
| 关注功能 | 否 禁用 | 无社交推荐 |

**新标签页：** 设为 `about:blank`（空白页）

### 1. 视觉效果优化

**Maker**: 使用系统默认设置  
**Dev**: 最佳性能 + 用户选定的 5 项视觉效果  
**Coremaker**: 无特殊配置（精简后可能丢失部分效果）

**Dev 启用的效果（用户指定）：**
| 效果 | 状态 | 说明 |
|------|:----:|------|
| 平滑屏幕字体边缘 | 是 | ClearType 字体渲染 |
| 在窗口下显示阴影 | 是 | 多窗口层次感 |
| 在单击后淡出菜单 | 是 | 菜单自然过渡 |
| 在鼠标指针下显示阴影 | 是 | 快速定位光标 |
| 在桌面上为图标标签使用阴影 | 是 | 图标文字可读性 |

**已禁用的效果（性能优化）：**
| 效果 | 状态 |
|------|:----:|
| 保存任务栏缩略图预览 | 否 |
| 窗口内的动画控件和元素 | 否 |
| 淡入淡出或滑动菜单到视图 | 否 |
| 滑动打开组合框 | 否 |
| 平滑滚动列表框 | 否 |
| 启用速览 | 否 |
| 任务栏中的动画 | 否 |
| 拖动时显示窗口内容 | 否 |
| 显示缩略图 | 否 |
| 显示亚透明的选择长方形 | 否 |
| 在视图中淡入淡出工具提示 | 否 |
| 在最大化和最小化时显示窗口动画 | 否 |

### 2. 📁 文件资源管理器配置

| 配置项 | Maker | Dev | Coremaker |
|--------|:-----:|:--------:|:---------:|
| 默认视图 | 系统默认 | **详细列表** | 系统默认 |
| 分组显示 | 系统默认 | **禁用** | 系统默认 |
| 隐藏文件 | 隐藏 | **显示** | 隐藏 |
| 文件扩展名 | 隐藏 | **显示** | 隐藏 |

**Dev 效果：**
```
📁 文件资源管理器
├─ 名称              修改日期          类型          大小
├─ .gitignore       2026/01/05        文件          512 B
├─ package.json     2026/01/04        JSON 文件     1 KB
├─ src              2026/01/05        文件夹        --
└─ test.py          2026/01/02        Python 文件   3 KB
```

### 3. 传统右键菜单

| 版本 | 右键菜单样式 |
|------|-------------|
| **Maker** | Windows 11 新式菜单 |
| **Dev** | **Windows 10 传统菜单** 是 |
| **Coremaker** | Windows 11 新式菜单 |

**Dev 配置：**
```powershell
# 禁用 Windows 11 新式菜单
CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 = ""
```

### 4. 🛠️ 开发者右键菜单项

| 菜单项 | Maker | Dev | Coremaker |
|--------|:-----:|:--------:|:---------:|
| CMD here | 否 | 是 | 否 |
| PowerShell here | 否 | 是 | 否 |
| PowerShell here (Admin) | 否 | 是 | 否 |

**Dev 独有功能：**
- 在文件夹上右键 → 快速打开终端
- 在空白处右键 → 在当前目录打开终端
- 支持网络路径（使用 pushd）

### 5. Windows Update 精细控制

| 配置 | Maker | Dev | Coremaker |
|------|:-----:|:--------:|:---------:|
| 服务状态 | 自动 | **默认禁用（需手动启用）** | 禁用 |
| 自动下载 | 是 | **否** | 否 |
| 自动安装 | 是 | **否** | 否 |
| 自动重启 | 是 | **否** | 否 |
| 暂停更新 | 否 | **首次开机自动暂停 800 天** | N/A |
| 手动检查 | 是 | **是（启用/恢复更新后）** | 否 |
| 活动时间 | 默认 | **8:00-20:00** | N/A |

**Dev 优势：**
- 是 完全控制更新时间
- 是 需要时可手动启用更新
- 是 保留在线驱动安装能力
- 是 工作时间内不会重启

**Dev 默认行为（重要）：**
- **Windows Update 默认是"禁用 + 暂停 800 天"**，避免任何自动更新/意外重启
- 桌面提供两个脚本（**需要右键"以管理员身份运行"**）：
  - `Enable-WindowsUpdate.ps1`：启用更新（仍保持"通知下载"模式，且暂停仍生效）
  - `Enable-And-Resume-WindowsUpdate.ps1`：启用并清除暂停（可立即检查更新）

### 6. 移除微软电脑管家

| 版本 | 微软电脑管家 |
|------|:------------:|
| **Maker** | [注意] 可能存在 |
| **Dev** | 是 **已移除** |
| **Coremaker** | [注意] 可能存在 |

**Dev 删除内容：**
- AppX 包：`Microsoft.MicrosoftPCManager_*`
- 文件夹：`Program Files\Microsoft PC Manager`
- 文件夹：`Program Files (x86)\Microsoft PC Manager`

---

## 移除的 AppX 包对比

### 三版本共同移除

| 应用 | 包名前缀 | 说明 |
|------|---------|------|
| Clipchamp | Clipchamp.Clipchamp_ | 视频编辑 |
| Bing 新闻 | Microsoft.BingNews_ | 新闻 |
| Bing 天气 | Microsoft.BingWeather_ | 天气 |
| Xbox 应用 | Microsoft.GamingApp_ | 游戏平台 |
| 获取帮助 | Microsoft.GetHelp_ | 帮助应用 |
| 使用技巧 | Microsoft.Getstarted_ | 教程 |
| Office 中心 | Microsoft.MicrosoftOfficeHub_ | Office |
| 纸牌游戏 | Microsoft.MicrosoftSolitaireCollection_ | 游戏 |
| 人脉 | Microsoft.People_ | 联系人 |
| Power Automate | Microsoft.PowerAutomateDesktop_ | 自动化 |
| 待办事项 | Microsoft.Todos_ | 任务管理 |
| 闹钟时钟 | Microsoft.WindowsAlarms_ | 时钟 |
| 邮件日历 | microsoft.windowscommunicationsapps_ | 邮件 |
| 反馈中心 | Microsoft.WindowsFeedbackHub_ | 反馈 |
| 地图 | Microsoft.WindowsMaps_ | 地图 |
| 录音机 | Microsoft.WindowsSoundRecorder_ | 录音 |
| Xbox TCUI | Microsoft.Xbox.TCUI_ | Xbox |
| 游戏栏 | Microsoft.XboxGamingOverlay_ | 游戏 |
| Xbox 覆盖 | Microsoft.XboxGameOverlay_ | 游戏 |
| Xbox 语音 | Microsoft.XboxSpeechToTextOverlay_ | 语音 |
| 手机连接 | Microsoft.YourPhone_ | 手机 |
| Groove 音乐 | Microsoft.ZuneMusic_ | 音乐 |
| 电影电视 | Microsoft.ZuneVideo_ | 视频 |
| 家庭安全 | MicrosoftCorporationII.MicrosoftFamily_ | 家庭 |
| 快速助手 | MicrosoftCorporationII.QuickAssist_ | 远程 |
| Teams | MicrosoftTeams_, MSTeams_, Microsoft.Windows.Teams_ | 通讯 |
| Cortana | Microsoft.549981C3F5F10_ | 助手 |
| Copilot | Microsoft.Copilot_, Microsoft.Windows.Copilot | AI |
| Outlook | Microsoft.OutlookForWindows_ | 邮件 |

### Dev 额外移除

| 应用 | 包名前缀 | Maker | Dev | Coremaker |
|------|---------|:-----:|:--------:|:---------:|
| **微软电脑管家** | Microsoft.MicrosoftPCManager_ | 否 | 是 | 否 |

### 保留的应用

| 应用 | Maker | Dev | Coremaker |
|------|:-----:|:--------:|:---------:|
| 照片 | 是 | 是 | 是 |
| 截图工具 | 是 | 是 | 是 |
| 计算器 | 是 | 是 | 是 |
| Microsoft Store | 是 | 是 | 是 |
| App Installer (winget) | 是 | 是 | 是 |
| Windows Terminal | 是 | 是 | 是 |
| 记事本 (新版) | 是 | 是 | 是 |
| 画图 | 是 | 是 | 是 |

---

## 系统包移除对比

| 系统包 | Maker | Dev | Coremaker |
|--------|:-----:|:--------:|:---------:|
| Internet Explorer | 是 | 是 | 否 移除 |
| Media Player | 是 | 是 | 否 移除 |
| Windows Defender | 是 | 是 | 否 移除 |
| WordPad | 是 | 是 | 否 移除 |
| Steps Recorder | 是 | 是 | 否 移除 |
| Tablet PC Math | 是 | 是 | 否 移除 |
| 手写识别 | 是 | 是 | 否 移除 |
| OCR 识别 | 是 | 是 | 否 移除 |
| 语音识别 | 是 | 是 | 否 移除 |
| 文字转语音 | 是 | 是 | 否 移除 |
| 扩展壁纸 | 是 | 是 | 否 移除 |
| Kernel LA57 FoD | 是 | 是 | 否 移除 |

**说明：**
- 是 = 保留
- 否 移除 = 从系统中删除

---

## 注册表配置对比

### 三版本共同配置

**绕过系统要求：**
```powershell
# 所有版本都配置
BypassCPUCheck = 1
BypassRAMCheck = 1
BypassSecureBootCheck = 1
BypassStorageCheck = 1
BypassTPMCheck = 1
AllowUpgradesWithUnsupportedTPMOrCPU = 1
```

**禁用赞助应用：** 三版本相同

**启用本地账户：** 三版本相同

**禁用功能：**
| 功能 | Maker | Dev | Coremaker |
|------|:-----:|:--------:|:---------:|
| BitLocker 自动加密 | 是 | 是 | 是 |
| OneDrive 备份 | 是 | 是 | 是 |
| 保留存储 | 是 | 是 | 是 |
| 聊天图标 | 是 | 是 | 是 |
| Copilot | 是 | 是 | 是 |
| 遥测 | 是 | 是 | 是 |
| DevHome 安装 | 是 | 是 | 是 |
| Outlook 安装 | 是 | 是 | 是 |
| Teams 安装 | 是 | 是 | 是 |

### Dev 独有配置

```powershell
# 1. 视觉效果
VisualFXSetting = 3                    # 自定义模式
FontSmoothing = 2                      # ClearType
FontSmoothingType = 2                  # 标准
ListviewShadow = 1                     # 窗口阴影
CursorShadow = 1                       # 鼠标阴影
MenuAnimation = 1                      # 菜单动画

# 2. 文件资源管理器
LogicalViewMode = 1                    # 详细信息
Mode = 4                               # Details 视图
GroupBy = "System.Null"                # 无分组
Hidden = 1                             # 显示隐藏文件
HideFileExt = 0                        # 显示扩展名

# 3. 传统右键菜单
{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 = ""

# 4. 开发者菜单
Directory\Background\shell\cmdhere
Directory\Background\shell\pshere
Directory\Background\shell\psadmin

# 5. Windows Update (默认禁用，需手动启用)
wuauserv\Start = 4                     # 禁用（默认）
UsoSvc\Start = 4                       # 禁用（默认）
WaaSMedicSvc\Start = 4                 # 禁用
NoAutoUpdate = 1                       # 禁用自动下载
NoAutoRebootWithLoggedOnUsers = 1      # 禁止自动重启
# 首次开机自动设置暂停 800 天（通过 SetupComplete.cmd）
ActiveHoursStart = 8                   # 活动开始
ActiveHoursEnd = 20                    # 活动结束
```

### Coremaker 独有配置

```powershell
# 禁用 Windows Update
DoNotConnectToWindowsUpdateInternetLocations = 1
DisableWindowsUpdateAccess = 1
WUServer = "localhost"

# 禁用 Defender
WinDefend\Start = 4
WdNisSvc\Start = 4
WdNisDrv\Start = 4
WdFilter\Start = 4
Sense\Start = 4

# 隐藏设置页面
SettingsPageVisibility = "hide:virus;windowsupdate"

# 删除更新服务
删除 WaaSMedicSVC
删除 UsoSvc
```

---

## 文件系统操作对比

| 操作 | Maker | Dev | Coremaker |
|------|:-----:|:--------:|:---------:|
| 删除 Edge | 是 | 否 | 是 |
| 删除 Edge WebView | 是 | 否 | 是 |
| 删除 OneDrive Setup | 是 | 是 | 是 |
| 删除 PC Manager | 否 | 是 | 否 |
| 删除 WinRE | 否 | 否 | 是 |
| 精简 WinSxS | 否 | 否 | 是 |

---

## 输出文件对比

| 属性 | Maker | Dev | Coremaker |
|------|:-----:|:--------:|:---------:|
| 文件名 | tiny11.iso | tiny11-Dev.iso | tiny11.iso |
| 镜像格式 | install.wim | install.wim | install.esd |
| 压缩方式 | recovery | recovery | max |
| 预计大小 | ~3.5 GB | ~4 GB | ~2.5 GB |

### 关于 WIM 格式

**Dev Edition 使用 WIM 格式（非 ESD），因此镜像体积较大，但有以下优势：**

| 特性 | WIM (Dev/Maker) | ESD (Coremaker/原版) |
|------|:--------------------:|:--------------------:|
| **解压/安装速度** | 更快 (~20-40%) | 较慢 |
| **CPU 占用** | 较低 | 较高 |
| **可编辑性** | 可挂载修改 | 只读 |
| **文件大小** | 较大 | 更小 |
| **压缩算法** | LZX (max) | LZMS |

**为什么选择 WIM：**
- **安装速度更快** - 对老旧硬件/低端 CPU 尤其明显
- **可后续修改** - 使用 DISM 挂载、编辑、再保存
- **CPU 负载低** - 解压时不会导致系统卡顿
- **单实例存储** - 相同文件只存一份，多版本共享节省空间

**体积差异原因：**
1. WIM 比 ESD 体积大约 30%
2. Dev 保留了 Edge + WebView2（约 300-500 MB）
3. 虽删除扩展壁纸，但仅抵消部分体积

> **提示：** 现代存储空间充足，WIM 的安装速度优势和可维护性远比体积节省更有价值。

---

## 性能和指标对比

| 指标 | Maker | Dev | Coremaker | 原版 Win11 |
|------|:-----:|:--------:|:---------:|:----------:|
| 启动时间 | *** | **** | **** | ** |
| 内存占用 | ~1.8 GB | ~1.5 GB | ~1.2 GB | ~2.5 GB |
| 磁盘占用 | ~13 GB | ~13 GB | ~9 GB | ~22 GB |
| 响应速度 | **** | ***** | **** | *** |
| 可维护性 | 是 高 | 是 高 | 否 低 | 是 高 |
| 兼容性 | 是 高 | 是 高 | [注意] 中 | 是 高 |
| 安全性 | 是 高 | 是 高 | 否 低 | 是 高 |
| 后台进程 | 较多 | **精简** | 较多 | 最多 |

**Dev 内存优化来源：**
- 禁用 Widgets：节省 ~50-100 MB
- 禁用 Xbox 服务：节省 ~20-50 MB
- 禁用搜索动态内容：节省 ~10-20 MB
- 最佳性能视觉设置：节省 ~50 MB

---

## 适用场景建议

### Maker - 标准精简版

**是 适合：**
- 普通用户日常使用
- 需要系统自动更新
- 不需要 Edge 浏览器
- 希望简单省心

**否 不适合：**
- 需要 Edge 开发调试
- 需要细粒度控制更新
- 需要开发者工具

### Dev - 开发者优化版

**是 适合：**
- **软件开发人员**
  - 需要 WebView2 开发
  - 使用 Edge 调试工具
  - 需要完整开发环境
  
- **硬件工程师**
  - 经常更换硬件
  - 需要在线驱动安装
  - 需要设备调试
  
- **长期生产使用**
  - 需要系统可维护
  - 需要定期安全更新
  - 需要稳定可靠

**否 不适合：**
- 追求极致精简
- 完全离线环境
- 临时测试用途

### Coremaker - 极端精简版

**是 适合：**
- **极端性能需求**
  - 旧硬件 / 低配设备
  - 最小化资源占用
  
- **虚拟机 / 测试环境**
  - 快速测试用途
  - 临时开发环境
  - 不需要长期维护
  
- **离线 / 隔离环境**
  - 无网络访问
  - 安全隔离环境
  
- **学习研究**
  - 研究系统精简技术
  - 学习 Windows 组件

**否 不适合：**
- 日常生产使用
- 需要系统更新
- 需要安全防护
- 长期使用

---

## 安全性对比

| 安全项 | Maker | Dev | Coremaker |
|--------|:-----:|:--------:|:---------:|
| Windows Update | 是 自动 | 是 手动 | 否 |
| 安全补丁 | 是 自动 | 是 可获取 | 否 无法获取 |
| Windows Defender | 是 | 是 | 否 禁用 |
| 系统恢复 | 是 | 是 | 否 移除 |
| 建议安全软件 | 否 | 否 | **必需** |

---

## 使用方法

### 运行命令

```powershell
# Maker 版
.\tiny11maker.ps1

# Dev 版
.\tiny11maker-Dev.ps1

# Coremaker 版
.\tiny11Coremaker.ps1

# 指定工作磁盘
.\tiny11maker-Dev.ps1 -ScratchDisk D
```

### 运行流程

三个版本流程基本相同：

1. 检查管理员权限
2. 输入 Windows 11 ISO 所在驱动器
3. 复制镜像文件
4. 选择镜像索引
5. 挂载并修改镜像
6. 应用各项配置
7. 卸载并导出镜像
8. 创建 ISO 文件
9. 清理临时文件

**Coremaker 额外步骤：**
- 询问是否启用 .NET 3.5
- 精简 WinSxS 目录
- 导出为 ESD 格式

---

## 快速选择指南

```
你需要什么？
    │
    ├─ 日常使用，自动更新 ──────────────► Maker
    │
    ├─ 开发工作，需要 Edge/WebView2 ────► Dev [推荐]
    │
    ├─ 需要控制更新时间 ────────────────► Dev [推荐]
    │
    ├─ 需要传统右键菜单 ────────────────► Dev [推荐]
    │
    ├─ 需要开发者终端快捷键 ─────────────► Dev [推荐]
    │
    ├─ 极致精简，测试用途 ──────────────► Coremaker
    │
    ├─ 虚拟机 / 临时环境 ───────────────► Coremaker
    │
    └─ 完全离线环境 ────────────────────► Coremaker
```

---

## 版本差异总结

### Maker vs Dev

| 差异 | Maker | Dev |
|------|-------|----------|
| Edge | 否 移除 | 是 保留 |
| WebView2 | 否 移除 | 是 保留 |
| PC Manager | 保留 | 是 移除 |
| 扩展壁纸 | 保留 | 是 移除 |
| Widgets | 是 启用 | 否 禁用 |
| 搜索突出显示 | 是 启用 | 否 禁用 |
| Xbox 服务 | 是 运行 | 否 禁用 |
| Windows Search | 是 自动 | [手动] 手动 |
| 锁屏聚焦/新闻 | 是 启用 | 否 禁用 |
| Edge 新闻推送 | 是 启用 | 否 禁用 |
| 右键菜单 | Win11 新式 | Win10 传统 |
| 终端快捷键 | 否 | 是 CMD/PS/PS Admin |
| 视觉效果 | 默认 | 最佳性能+关键效果 |
| 文件管理器 | 默认 | 详细列表+无分组 |
| Windows Update | 自动 | 手动+800天暂停 |
| 在线驱动 | 是 自动 | 是 手动可用 |

### Dev vs Coremaker

| 差异 | Dev | Coremaker |
|------|----------|-----------|
| Edge | 是 保留 | 否 移除 |
| Windows Update | 是 手动可用 | 否 完全禁用 |
| Defender | 是 保留 | 否 禁用 |
| WinRE | 是 保留 | 否 移除 |
| WinSxS | 是 完整 | 否 极度精简 |
| 系统包 | 是 完整 | 否 大量移除 |
| 可维护性 | 是 高 | 否 低 |
| 输出格式 | WIM | ESD |

---

## 当前版本功能概述

### Dev Edition v1.6 (2026-01-05)

基于 `tiny11maker.ps1` 开发，专为开发者优化的精简 Windows 11 镜像构建工具。

#### 核心保留

| 组件 | 状态 | 说明 |
|------|:----:|------|
| Edge 浏览器 | 是 | 开发调试必需 |
| Edge WebView2 | 是 | 现代应用依赖 |
| Windows Update | 是 | 默认禁用，可手动启用 |
| 在线驱动安装 | 是 | 硬件兼容性 |
| Windows Defender | 是 | 安全防护 |
| 系统恢复环境 | 是 | 故障恢复 |

#### 额外精简

| 项目 | 效果 |
|------|------|
| 微软电脑管家 | 移除 |
| 扩展壁纸 | 移除（节省 ~300-500 MB） |
| 预装 AppX | 移除 30+ 应用 |

#### 后台服务优化

| 服务 | 状态 | 说明 |
|------|:----:|------|
| Widgets | 禁用 | 通过策略，不影响系统通知 |
| 搜索突出显示 | 禁用 | 减少网络请求 |
| Xbox 服务 | 禁用 | 4 个后台服务 |
| Windows Search | 手动 | 推荐使用 Everything |

#### 界面优化

| 项目 | 配置 |
|------|------|
| 视觉效果 | 最佳性能 + 5 项关键效果 |
| 右键菜单 | Windows 10 传统风格 |
| 锁屏界面 | 禁用聚焦/天气/新闻/提示 |
| Edge 新标签页 | 空白页，禁用新闻/侧边栏 |

#### 开发者工具

| 功能 | 说明 |
|------|------|
| CMD here | 右键在当前目录打开 CMD |
| PowerShell here | 右键在当前目录打开 PS |
| PS Admin here | 右键以管理员打开 PS |
| 文件资源管理器 | 详细列表，无分组，显示隐藏文件和扩展名 |

#### Windows Update 控制

| 配置 | 值 |
|------|------|
| 默认状态 | 禁用（需手动启用） |
| 暂停时间 | 首次开机自动暂停 800 天 |
| 活动时间 | 8:00-20:00（工作时间不重启） |

#### 桌面文件

| 文件 | 用途 | 备注 |
|------|------|------|
| `tiny11-dev-说明.md` | 版本说明 | - |
| `Enable-WindowsUpdate.ps1` | 启用更新服务 | 暂停仍生效，需管理员 |
| `Enable-And-Resume-WindowsUpdate.ps1` | 启用并清除暂停 | 可立即更新，需管理员 |

---

## 免责声明

[注意] **重要提示：**

1. 本工具仅供学习和研究使用
2. 修改 Windows 镜像可能违反微软服务条款
3. 使用本工具产生的任何问题，开发者不承担责任
4. 建议在虚拟机中测试后再用于物理机
5. 定期备份重要数据

---

**Tiny11 Dev Edition** - 专为开发者设计的精简 Windows 11

| 版本 | 定位 | 推荐指数 |
|------|------|:--------:|
| Maker | 标准精简 | [推荐][推荐][推荐] |
| **Dev** | **开发者优化** | **[推荐][推荐][推荐][推荐][推荐]** |
| Coremaker | 极端精简 | [推荐][推荐] |

**构建日期**: 2026-01-05  
**版本**: 1.6
