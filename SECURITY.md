# Security

This AI-agent-free Terax fork runs shells and accesses local files and Git repositories. It is forked from [crynta/terax-ai](https://github.com/crynta/terax-ai); fork-specific reports belong to [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai), not upstream's security email.

## Reporting

Use this fork's [private vulnerability reporting page](https://github.com/slaatarsi/terax-no-ai/security/advisories/new) if private reporting is enabled. If it is unavailable, ask the fork maintainer for a private contact method without disclosing vulnerability details publicly. Do not include tokens, private files, or exploit details in a public issue.

Include the affected commit, OS and architecture, impact, and minimal reproduction steps. No response-time or supported-release guarantee is established for this fork. Retest against the latest fork revision when possible.

## Scope

- Rust backend: PTY lifecycle, filesystem access, Git commands, workspace authorization, IPC, and plugins.
- Frontend handling of untrusted terminal output, file content, links, and preview navigation.
- Authenticated local CLI control and Windows Explorer integration.
- Packaging, release provenance, and updater configuration.

Report dependency vulnerabilities to their maintainers as well. Terax cannot protect against an already-compromised host or commands deliberately run with your permissions.

## Security boundaries

- The webview reaches host operations through allow-listed Tauri APIs; it has no Node runtime.
- Workspace authorization, path validation, bounded transport, and terminal escape-sequence handling remain security-critical.
- A terminal command runs with your user permissions. Review commands before running them.
- No built-in AI providers, agent tools, API-key management, or agent approval system remain. Manually launched CLI tools have their own network and credential behavior.
- Earlier AI conversations, provider settings, credentials, and external hooks are not loaded or automatically removed. Review old installations separately if cleanup is required.

## Updates and distribution

The updater still targets upstream `crynta/terax-ai` releases with the upstream verification key. A valid upstream signature does not establish that an update is this AI-free fork. Accepting it may replace the fork with upstream. Do not accept upstream updates if you intend to retain this version.

Application and installer identities are also inherited. Do not assume fork and upstream installations are isolated. Fork-specific signing, update infrastructure, and packaged-install validation must be established before making independent release assurances.

See the [security model](docs/architecture/security-model.md), [release gates](docs/architecture/ghostty-release-readiness.md), and [Windows Explorer guide](docs/architecture/windows-explorer.md).
