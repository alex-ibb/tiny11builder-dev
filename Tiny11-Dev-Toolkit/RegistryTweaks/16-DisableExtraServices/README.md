# 16 - 额外服务优化 (Extra Services Optimization)

禁用开发者环境中不需要的后台服务，减少内存占用、网络活动和安全风险。

## 包含的服务

| 服务名 | 中文名称 | 默认启动类型 | 禁用原因 | 恢复值 |
|--------|---------|:-----------:|---------|:------:|
| **DiagTrack** | 已连接的用户体验和遥测 | 自动 (2) | 主遥测服务，持续收集使用数据上传微软 | Manual (3) |
| **DoSvc** | 传递优化 | 自动 (2) | P2P 更新分发，会使用上行带宽给其他设备传文件 | Manual (3) |
| **SysMain** | SysMain (旧称 SuperFetch) | 自动 (2) | 预读缓存，SSD 环境下无意义且占内存 | Manual (3) |
| **Fax** | 传真 | Manual (3) | 现代环境几乎不用 | Manual (3) |
| **RemoteRegistry** | 远程注册表 | 禁用 (4) | 允许远程修改注册表，安全风险 | 禁用 (4)¹ |
| **lfsvc** | 地理位置服务 | Manual (3) | 台式开发机不需要定位 | Manual (3) |
| **RetailDemo** | 零售演示服务 | Manual (3) | 仅商店展示机使用 | Manual (3) |
| **DPS** | 诊断策略服务 | 自动 (2) | 问题检测，会上传诊断数据² | 自动 (2) |
| **WdiServiceHost** | 诊断服务主机 | Manual (3) | DPS 的下游服务² | Manual (3) |
| **WdiSystemHost** | 诊断系统主机 | Manual (3) | DPS 的下游服务² | Manual (3) |

> ¹ RemoteRegistry 的 Windows 默认值本身就是禁用 (4)，Enable.reg 保持不变  
> ² 禁用 DPS 链（DPS + WdiServiceHost + WdiSystemHost）后，Windows 内置疑难解答工具将无法使用

## 使用方法

| 操作 | 文件 | 需要管理员 |
|------|------|:---------:|
| 禁用所有服务 | `Disable.reg` | ✅ |
| 恢复到默认 | `Enable.reg` | ✅ |

1. 右键点击 .reg 文件 → "以管理员身份合并" 或直接双击
2. 在确认对话框中点击"是"
3. **重启电脑**使更改生效

## 影响说明

### 禁用后无影响的功能 ✅
- Windows Update 手动更新（不受 DoSvc 禁用影响）
- 正常上网、浏览器、开发工具
- 系统通知、声音、蓝牙、打印（非传真）
- 事件查看器基本功能

### 禁用后会受影响的功能 ⚠️
- **Windows 疑难解答**（网络诊断、音频修复等）→ 运行 Enable.reg 恢复 DPS 链即可
- **可靠性监视器**停止记录新事件
- **位置服务**（地图定位等）不可用

### 不会受影响的常见误解 ❌
- ❌ "禁用 SysMain 会让系统变慢" → SSD 上没有明显差别，反而减少后台写入
- ❌ "禁用 DoSvc 会导致无法更新" → 只是关闭 P2P 分发，WU 本身正常工作
- ❌ "禁用 DiagTrack 会导致系统不稳定" → 纯数据收集服务，无系统功能依赖

## 依赖关系图

```
DiagTrack ──(独立)
DoSvc ──(独立)
SysMain ──(独立)
Fax ──(独立)
RemoteRegistry ──(独立)
lfsvc ──(独立)
RetailDemo ──(独立)

DPS (诊断策略服务)
 ├── WdiServiceHost (诊断服务主机)
 └── WdiSystemHost (诊断系统主机)
     └── 影响: Windows 疑难解答工具
```
