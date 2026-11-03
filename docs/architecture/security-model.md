# Security model

This guide elaborates on `TERAX.md`, the architecture source of truth.

Terax runs user-selected shells and tools and reads and writes local files. It has no built-in AI tools, provider proxy, credential service, agent detection, or agent hook installer.

## Boundaries

- **IPC**: native commands are registered in `src-tauri/src/lib.rs`. Plugin APIs are allowlisted in `src-tauri/capabilities/default.json`. Child preview webviews must not gain main-window capabilities.
- **Workspace and processes**: `WorkspaceRegistry` in `modules/workspace.rs` tracks authorized directories. `authorize_spawn_cwd` checks tool execution; `authorize_user_spawn_cwd` admits a user-selected terminal directory. Git commands retain workspace authorization. The registry is not a sandbox for commands the user explicitly runs in their shell.
- **Filesystem**: native commands validate paths and retain their mutation, conflict, symlink, and traversal checks. Editor saves check disk modification times rather than silently overwriting external changes. Copy operations stage items and publish without replacing an existing destination.
- **Terminal output**: PTY output is untrusted. OSC 7 paths and OSC 52 clipboard payloads are validated. OSC 133 supplies command boundaries, not permission to execute a command. Terminal rerun requires the complete command originally submitted through Terax. Agent-specific OSC markers no longer trigger app actions.
- **PTY transport**: the multiplexed URI scheme validates origin, live per-webview tokens, body sizes, framing, and acknowledgment boundaries. Invalid progress cannot grant output credit. See `pty-transport-v2.md`.
- **CLI control plane**: local control requests retain authentication, caller targeting, bounded framing, and command validation. `open_directory` explicitly grants workspace authorization for its validated target, equivalent to choosing a terminal directory; ordinary editor `open` remains read-only with respect to authorization. Token holders have this directory-opening authority. See `cli-control.md`.
- **Resource limits**: one-shot formatter commands retain timeout and output bounds. PTY, LSP, and capture processes retain their platform-specific process cleanup.

## Removed AI data

Existing conversations, provider settings, and credentials are not loaded, migrated, or deleted. External agent configurations and previously installed hooks are not automatically edited. New terminals no longer set `TERAX_TERMINAL`, and the agent notification listener is gone. Users may still run external AI CLIs manually as ordinary shell programs.

## Invariants

- Validate every new native command at its trust boundary.
- Preserve workspace authorization and filesystem data-loss protections.
- Never expose privileged APIs to browser preview content.
- Never log credentials or control tokens.
- Do not delete user data or modify external application configuration as part of feature removal.

## See also

- [`TERAX.md`](../../TERAX.md)
- [Two-process model](two-process-model.md)
- [PTY transport](pty-transport-v2.md)
- [CLI control plane](cli-control.md)
