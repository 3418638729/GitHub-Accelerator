# GitHub Accelerator

一键加速访问 GitHub，解决 DNS 污染导致的访问慢/打不开问题。

## 原理

修改系统 hosts 文件，将 GitHub 相关域名指向可用的 CDN IP，绕过 DNS 污染。

数据来源：[GitHub520](https://github.com/521xueweihan/GitHub520)

## 功能

- **双击运行**：自动打开 GitHub + 更新 hosts（需要管理员权限）
- **开机加速**：登录后 30 秒，计划任务静默更新（无需操心）
- **智能缓存**：同一天不重复下载，开机仅 0.3 秒
- **网络检测**：网络未就绪时跳过，使用上次缓存
- **双重保障**：下载失败自动用缓存，缓存缺失用内置 IP

## 使用方法

| 方法 | 说明 |
|------|------|
| **双击 `GitHub.bat`** | 打开 GitHub + 自动更新（推荐） |
| `GitHub.bat /install` | 安装开机计划任务 |
| `GitHub.bat /uninstall` | 卸载计划任务 + 清除缓存 |
| `GitHub.bat /check` | 检查当前状态 |
| `GitHub.bat /startup` | 静默更新模式（计划任务调用） |

## 文件说明

| 文件 | 说明 |
|------|------|
| `GitHub.bat` | 主程序，双击运行 |
| `gh520_launcher.vbs` | 开机静默启动器（自动生成在桌面） |

## 更新日志

### v2（优化版）
- curl.exe 原生下载，告别 PowerShell 启动慢
- 24 小时缓存机制，开机仅 0.3 秒
- 网络就绪检查，不阻塞开机
- VBS 静默启动器，计划任务零窗口
- 智能检测 GitHub 连通性，不通自动更新
- 三重故障保障：在线 > 缓存 > 内置 IP
