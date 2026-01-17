# 传统右键菜单

## 功能说明

Windows 11 引入了新的简化右键菜单，需要点击"显示更多选项"才能看到完整菜单。此调整直接显示传统的完整菜单。

## 默认状态

**已启用** - 使用传统右键菜单

## 文件说明

- `Enable.reg` - 启用传统右键菜单
- `Disable.reg` - 恢复 Windows 11 新式菜单

## 生效方式

应用后需要**重启资源管理器**或**重启电脑**生效。

快速重启资源管理器：
```powershell
Stop-Process -Name explorer -Force; Start-Process explorer
```
