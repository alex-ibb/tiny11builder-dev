# Tiny11 Dev Edition

> 专为开发者设计的精简 Windows 11 镜像构建工具

## 版本信息

| 项目 | 内容 |
|------|------|
| 版本 | Dev Edition v1.8 |
| 更新日期 | 2026-01-25 |
| 基于 | tiny11maker.ps1 |

---

## 快速开始

```powershell
# 运行构建脚本
.\tiny11maker-dev-build.ps1

# 指定工作磁盘
.\tiny11maker-dev-build.ps1 -ScratchDisk D
```

---

## 版本对比

| 特性 | Maker | **Dev** | Coremaker |
|------|:-----:|:-------:|:---------:|
| **定位** | 标准精简 | **开发者优化** | 极端精简 |
| Edge + WebView2 | ❌ | ✅ | ❌ |
| Windows Update | 自动 | **手动可控** | 禁用 |
| Windows Defender | ✅ | ✅ | ❌ |
| 传统右键菜单 | ❌ | ✅ | ❌ |
| 终端快捷菜单 | ❌ | ✅ | ❌ |
| 视觉效果优化 | 默认 | **性能模式** | 默认 |
| 后台服务精简 | 默认 | **已优化** | 默认 |
| 可维护性 | 高 | 高 | 低 |
| 预计大小 | ~3.5 GB | ~4 GB | ~2.5 GB |

---

## Dev Edition 独有功能

### 1. 保留关键开发组件

| 组件 | 说明 |
|------|------|
| Edge 浏览器 | 前端调试、DevTools |
| Edge WebView2 | 现代桌面应用依赖 |
| Windows Update | 默认禁用，需要时可手动启用 |
| 在线驱动安装 | 支持新硬件即插即用 |

### 2. 额外精简内容

| 移除项 | 节省空间 |
|--------|----------|
| 扩展壁纸包 | ~300-500 MB |
| 微软电脑管家 | ~50 MB |
| 预装 AppX (30+) | ~500 MB |

### 3. 后台服务优化

| 服务 | 状态 | 说明 |
|------|:----:|------|
| Widgets | 禁用 | 节省 ~50-100 MB |
| Xbox 服务 (4个) | 禁用 | 节省 ~20-50 MB |
| Windows Search | 手动 | 节省 ~50-150 MB |
| 遥测服务 (dmwappushservice) | 禁用 | 隐私保护 |
| DiagTrack | 禁用 | 主要遥测服务 |
| 诊断服务 (DPS/WdiServiceHost/WdiSystemHost) | 禁用 | 诊断数据上传 |
| 传真 (Fax) | 禁用 | 无用服务 |
| 远程注册表 (RemoteRegistry) | 禁用 | 安全风险 |
| 地理位置 (lfsvc) | 禁用 | 开发机不需要 |
| 零售演示 (RetailDemo) | 禁用 | 仅商店展示 |
| 搜索突出显示 | 禁用 | 减少网络 |

> **推荐**: 安装 [Everything](https://www.voidtools.com/) 替代 Windows Search，毫秒级响应

### 4. 界面优化

| 项目 | 配置 |
|------|------|
| 右键菜单 | Windows 10 传统风格 |
| 任务栏按钮 | 任务栏已满时合并 |
| 视觉效果 | 性能模式 + 5项关键效果 |
| 文件资源管理器 | 详细列表、无分组、显示隐藏文件/扩展名 |
| 锁屏界面 | 禁用聚焦/天气/新闻/提示 |
| Edge 新标签页 | 空白页，禁用新闻 |

**保留的视觉效果**:
- 字体平滑 (ClearType)
- 窗口阴影
- 菜单淡入
- 鼠标指针阴影
- 图标标签阴影

### 5. 开发者右键菜单

在文件夹或空白处右键可用：

| 菜单项 | 功能 |
|--------|------|
| CMD here | 在当前目录打开命令提示符 |
| PowerShell here | 在当前目录打开 PowerShell |
| PowerShell here (Admin) | 以管理员身份打开 PowerShell |

### 6. Windows Update 控制

| 配置 | 值 |
|------|------|
| 默认状态 | **禁用** (需手动启用) |
| 暂停时间 | 首次开机自动暂停 800 天 |
| 活动时间 | 8:00-20:00 (工作时间不重启) |
| 下载模式 | 仅通知，不自动下载 |

**桌面提供的控制脚本** (需管理员运行):

| 脚本 | 功能 |
|------|------|
| `Enable-WindowsUpdate.ps1` | 启用服务 (暂停仍生效) |
| `Enable-And-Resume-WindowsUpdate.ps1` | 启用并清除暂停，可立即更新 |

---

## Tiny11-Dev-Toolkit

安装后桌面会放置工具包，包含 15 个注册表调整模块：

| # | 功能 | 文件 |
|---|------|------|
| 01 | 传统右键菜单 | Enable.reg / Disable.reg |
| 02 | 任务栏左对齐 | LeftAlign.reg / CenterAlign.reg |
| 03 | 隐藏搜索框 | Hide.reg / Show.reg |
| 04 | 视觉效果 | Performance.reg / Default.reg |
| 05 | CMD 右键菜单 | Add.reg / Remove.reg |
| 06 | PowerShell 右键菜单 | Add.reg / Remove.reg |
| 07 | PowerShell Admin 右键菜单 | Add.reg / Remove.reg |
| 08 | Windows Update 暂停 | Resume.reg |
| 09 | Widgets | Disable.reg / Enable.reg |
| 10 | 搜索突出显示 | Disable.reg / Enable.reg |
| 11 | Xbox 服务 | Disable.reg / Enable.reg |
| 12 | 锁屏优化 | Disable.reg / Enable.reg |
| 13 | Edge 优化 | Optimize.reg / Default.reg |
| 14 | 文件资源管理器 | Developer.reg / Default.reg |
| 15 | 窗口边框颜色 | Enable.reg / Disable.reg |

每个模块都附带 README.md 说明文档。

---

## 移除的应用列表

### 预装 AppX (30+)

Clipchamp、Bing 新闻/天气、Xbox 应用、获取帮助、使用技巧、Office 中心、纸牌游戏、人脉、Power Automate、待办事项、闹钟时钟、邮件日历、反馈中心、地图、录音机、Xbox 相关 (4个)、手机连接、Groove 音乐、电影电视、家庭安全、快速助手、Teams、Cortana、Copilot、Outlook、微软电脑管家

### 保留的应用

照片、截图工具、计算器、Microsoft Store、App Installer (winget)、Windows Terminal、记事本、画图

---

## 注册表配置摘要

### 系统要求绕过 (TPM/CPU/RAM/SecureBoot)
通过 `autounattend-dev.xml` 和 Boot.wim 双重配置。

### Windows Update 策略
```
服务启动类型 = 禁用 (默认)
自动下载 = 否
自动重启 = 否
暂停更新 = 800 天
活动时间 = 8:00-20:00
```

### 视觉效果
```
VisualFXSetting = 3 (自定义)
FontSmoothing = 2 (ClearType)
ListviewShadow = 1
CursorShadow = 1
MenuAnimation = 1
```

### 开发者菜单注册表路径
```
HKCR\Directory\Background\shell\cmdhere
HKCR\Directory\Background\shell\pshere
HKCR\Directory\Background\shell\psadmin
```

---

## 输出文件

| 属性 | 值 |
|------|------|
| 文件名格式 | `tiny11-dev-YYYYMMDD_HHMM.iso` |
| 镜像格式 | WIM (非 ESD) |
| 压缩方式 | max |
| 日志文件 | `tiny11-dev-YYYYMMDD_HHMM.iso.log` |

### 为什么使用 WIM 格式

| 特性 | WIM | ESD |
|------|:---:|:---:|
| 安装速度 | ✅ 快 20-40% | 较慢 |
| CPU 占用 | ✅ 低 | 高 |
| 可编辑性 | ✅ 可挂载修改 | 只读 |
| 文件大小 | 较大 | ✅ 更小 |

---

## 适用场景

### ✅ 推荐使用 Dev Edition

- 软件开发：需要 Edge DevTools、WebView2
- 硬件调试：需要在线驱动、完整系统功能
- 长期生产：需要可维护性、安全更新能力
- 效率优先：需要传统右键菜单、终端快捷键

### ❌ 不推荐

- 追求极致精简 → 使用 Coremaker
- 完全离线环境 → 使用 Coremaker
- 临时测试用途 → 使用 Coremaker

---

## 性能指标

| 指标 | Dev Edition | 原版 Win11 |
|------|:-----------:|:----------:|
| 内存占用 | ~1.5 GB | ~2.5 GB |
| 磁盘占用 | ~13 GB | ~22 GB |
| 后台进程 | 精简 | 较多 |
| 响应速度 | ★★★★★ | ★★★ |

---

## 免责声明

> ⚠️ 本工具仅供学习和研究使用。修改 Windows 镜像可能违反微软服务条款。建议在虚拟机中测试后再用于物理机。定期备份重要数据。

---

**Tiny11 Dev Edition** - 专为开发者设计的精简 Windows 11

构建日期: 2026-01-17 | 版本: 1.7
