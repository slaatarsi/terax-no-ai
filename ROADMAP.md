# Fork direction

This Terax version is an AI-agent-free fork of [crynta/terax-ai](https://github.com/crynta/terax-ai), maintained in [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai).

## Scope

A lightweight terminal with a folder explorer and Git tracking. Keep shell compatibility, terminal correctness, responsive file browsing, clear Git status, and low resource use at the center of every change.

The existing editor, optional language servers, Markdown/media viewers, web previews, themes, and workspace layouts remain supporting utilities. Their presence is not a plan to turn this fork into an IDE or an agent workspace.

## Current capabilities

- Native PTY shells, tabs, split panes, shell integration, and workspace restoration.
- libghostty-vt terminal model with WebGPU and WebGL rendering.
- Folder browsing, search, file management, and live filesystem updates.
- Git status, decorations, diffs, staging, commits, push, and commit history.
- Windows Explorer integration code, with signed-install validation still pending.

Implementation is not proof of release readiness. See the [release gates](docs/architecture/ghostty-release-readiness.md) and [Windows integration prerequisites](docs/architecture/windows-explorer.md).

## Priorities

- Fix reproducible terminal, explorer, and Git bugs with regression coverage.
- Verify rendering, shell behavior, and resource usage on macOS, Linux, Windows, and WSL.
- Keep documentation and translations aligned with this fork.
- Establish fork-specific release, update, signing, and application-identity configuration before claiming independent packaged distribution. The updater currently targets upstream; see the [README warning](README.md#installation-and-updates).

These are direction and validation priorities, not promised features or delivery dates.

## Out of scope

- Built-in AI chat, agents, orchestration, provider integrations, AI autocomplete, voice input, and AI tool/skill marketplaces.
- Reintroducing agent detection, automatic agent hooks, or agent background services.
- Heavyweight IDE infrastructure, unbounded background indexing, and full-browser functionality.
- Telemetry or required accounts.

Users may run ordinary CLI programs manually, but this fork does not manage AI agents for them.

## Contributions

Discuss substantial changes in this fork's [issues](https://github.com/slaatarsi/terax-no-ai/issues) before implementation. Follow [CONTRIBUTING.md](CONTRIBUTING.md). Upstream's roadmap and maintainer decisions do not define this fork's scope.
