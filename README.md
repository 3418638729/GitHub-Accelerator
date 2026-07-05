# GitHub Accelerator

一键加速访问 GitHub，解决 DNS 污染导致的访问慢/打不开问题。

## 原理

修改系统 hosts 文件，将 GitHub 相关域名指向可用的 CDN IP，绕过 DNS 污染。

数据来源：[GitHub520](https://github.com/521xueweihan/GitHub520)

## 使用方法

1. 以**管理员身份**运行 `GitHub.bat`
2. 脚本自动完成：
   - 下载最新 IP 列表
   - 更新系统 hosts 文件
   - 刷新 DNS 缓存
   - 打开 GitHub 首页

> 如果 GitHub 访问变慢，重新运行一次即可获取最新 IP。

## 文件说明

| 文件 | 说明 |
|------|------|
| `GitHub.bat` | 主程序，双击以管理员运行 |
