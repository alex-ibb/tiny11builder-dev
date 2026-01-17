# Xbox 后台服务

## 功能说明

控制 Xbox 相关的 4 个后台服务是否运行。

## 默认状态

**已禁用**

## 受影响的服务

| 服务名 | 说明 |
|--------|------|
| XblAuthManager | Xbox Live 身份验证 |
| XblGameSave | Xbox 云存档 |
| XboxGipSvc | Xbox 外设服务 |
| XboxNetApiSvc | Xbox 网络服务 |

## 文件说明

- `Disable.reg` - 禁用 Xbox 服务 (需管理员权限)
- `Enable.reg` - 启用 Xbox 服务 (需管理员权限)

## 注意事项

- 如果您使用 Xbox 手柄或 Xbox 游戏，请启用这些服务
- 禁用后可节省约 20-50 MB 内存

## 生效方式

应用后需要**重启电脑**生效。
