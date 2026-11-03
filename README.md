<div align="center">
  <img src="public/logo.png" width="144" height="144" alt="Terax" />
  <h1>Terax</h1>
  <p><strong>A lightweight terminal with a folder explorer and Git tracking. No built-in AI agents.</strong></p>
  <p><a href="https://github.com/slaatarsi/terax-no-ai">Fork repository</a> · <a href="docs/README.md">Documentation</a> · <a href="https://github.com/crynta/terax-ai">Original project</a></p>
</div>

[简体中文](docs/readme/README.zh-CN.md) | [Español](docs/readme/README.es.md) | [Deutsch](docs/readme/README.de.md) | [Français](docs/readme/README.fr.md) | [日本語](docs/readme/README.ja.md) | [한국어](docs/readme/README.ko.md) | [Português](docs/readme/README.pt-BR.md) | [Polski](docs/readme/README.pl.md) | [Русский](docs/readme/README.ru.md) | [Bahasa Indonesia](docs/readme/README.id.md) | [हिन्दी](docs/readme/README.hi.md)

## About this fork

This version of **Terax** is forked from [crynta/terax-ai](https://github.com/crynta/terax-ai) and modified to remove built-in AI and agent integrations. Credit for the original project goes to Crynta and the upstream contributors. This fork is maintained separately; upstream websites, releases, and community channels do not represent this version.

The focus is simple: **a terminal, a folder explorer, and Git tracking**. There is no built-in AI chat, agent orchestration, provider configuration, AI autocomplete, or voice input. Ordinary CLI programs can still be run manually in the terminal.

Existing conversations, saved provider settings, credentials, and external agent configurations from earlier installations are not loaded or deleted. Previously installed external hooks are not automatically uninstalled.

## Features

- **Terminal:** tabs, horizontal and vertical splits, native shells, search, links, true color, block-based command input, and restored workspace layouts.
- **Folder explorer:** browse folders, search files, rename and manage files, and see live filesystem changes and Git decorations.
- **Git tracking:** working-tree status, diffs, stage/unstage, commits, push, branch display, and history with a commit graph.
- **Retained utilities:** code editing with optional language-server support, Markdown and media viewing, local web previews, themes, and background customization. These are supporting features, not AI integrations.
- **Platforms:** macOS, Linux, Windows, and WSL workspace support. Platform and installer validation limits are documented in the [release-readiness guide](docs/architecture/ghostty-release-readiness.md).

Built with Tauri 2, Rust, `portable-pty`, libghostty-vt WASM, React 19, and TypeScript. WebGPU is the default terminal renderer, with a WebGL fallback. No telemetry or Terax account is required.

## Screenshots

Screenshots are inherited from upstream and may not exactly match this fork's current UI.

![Terminal](docs/terminal.png)
![Folder explorer and source control](docs/source-control.png)

## Installation and updates

Build this fork from source using the instructions below. Do not use upstream installers, `terax-bin`, or the upstream Nix package expecting this AI-free version. No fork-specific signed installer or release availability is guaranteed here.

> **Update warning:** the current updater configuration still points to `crynta/terax-ai` releases and uses the upstream verification key. Accepting an upstream update may replace this fork with the upstream version. Do not accept those updates if you want to keep this AI-free fork. This documentation update does not change updater configuration, application identity, or signing.

Windows shell detection uses `pwsh.exe`, then `powershell.exe`, then `cmd.exe`. Windows Explorer integration is implemented, but signed-install acceptance remains pending; see [Windows Explorer integration](docs/architecture/windows-explorer.md).

## Build from source

Prerequisites: Rust stable, Node 22+, [pnpm](https://pnpm.io), and the [Tauri prerequisites](https://tauri.app/start/prerequisites/) for your platform. Windows shell-extension build requirements are in the [integration guide](docs/architecture/windows-explorer.md).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Production bundle:
pnpm tauri build
```

## Checks

```bash
pnpm lint
pnpm check-types
pnpm test
cd src-tauri
cargo clippy --all-targets --locked -- -D warnings
cargo nextest run --locked
# Without nextest: cargo test --locked
```

## Documentation and contributions

- [Contributor documentation](docs/README.md)
- [Architecture source of truth](TERAX.md)
- [Contributing](CONTRIBUTING.md)
- [Fork direction](ROADMAP.md)
- [Security](SECURITY.md)

Report fork-specific issues and submit pull requests in [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai), not the upstream project.

## License and attribution

[Apache-2.0](LICENSE). This fork retains the original project's license and third-party notices. See [crynta/terax-ai](https://github.com/crynta/terax-ai) for the original project. Upstream signing sponsorship and release assurances do not automatically apply to fork builds.
