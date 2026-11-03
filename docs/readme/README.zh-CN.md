# Terax

**轻量终端，配备文件夹浏览器和 Git 状态跟踪。不包含内置 AI 智能体。**

此版本基于 [crynta/terax-ai](https://github.com/crynta/terax-ai) 分叉并修改，在 [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai) 中独立维护。原项目由 Crynta 和上游贡献者开发。

## 功能

- 原生终端，支持标签页、分屏、搜索和 Shell 集成。
- 文件夹浏览器，支持搜索、文件管理和实时更新。
- Git 状态、差异、暂存、提交、推送和图形化历史。
- 保留编辑器、可选语言服务器、预览和主题作为辅助工具。

没有内置 AI 聊天、智能体、AI 服务商配置、AI 自动补全或语音输入。仍可在终端中手动运行 CLI 程序。旧版 AI 数据和外部钩子不会被加载，也不会被自动删除。

## 从源码构建

需要 Rust stable、Node 22+、pnpm 以及对应平台的 [Tauri 前置依赖](https://tauri.app/start/prerequisites/)。

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# 生产构建：
pnpm tauri build
```

**注意：** 更新配置目前仍指向上游发布。接受更新可能会将本分叉替换为上游版本。不要将上游安装包或软件包视为本无 AI 版本。本分叉不保证拥有独立的代码签名。

完整说明和分发限制见[英文 README](../../README.md)。另请参阅[文档](../README.md)、[贡献指南](../../CONTRIBUTING.md)和[安全说明](../../SECURITY.md)。请在本分叉仓库中反馈问题。

采用 [Apache-2.0](../../LICENSE) 许可证，保留原项目的署名和第三方声明。
