# Windows Explorer integration

## Status: implemented, signed-install acceptance still pending

The native extension, launch routing, sparse MSIX build, installer hooks, and signing workflow are implemented. **Compilation is not proof that the command appears in Windows 11 Explorer.** Do not describe this feature as release-ready until the signed installation checks below pass.

## Design

- `src-tauri/windows-shell/ExplorerCommand.cpp`: a small, statically linked C++ COM DLL implementing `IExplorerCommand`, `IClassFactory`, and `IObjectWithSite`. It runs in the packaged COM surrogate, not the Tauri runtime. No DLL self-registration or Explorer registry workaround is used.
- Stable CLSID: `9D3E6AB2-63DC-4B7F-9184-A9F61282543B`.
- Stable package name: `Crynta.Terax.Explorer`. The production publisher must also remain stable across upgrades.
- The manifest registers `Directory` and `Directory\Background`. SDK schema validation rejects `Drive`, so the existing drive verb remains a legacy command.
- Fast `GetState` returns `E_PENDING`; worker-thread eligibility checks use shell attributes. Files, virtual folders, and multiple selections are hidden. Background resolution uses `SID_SFolderView`, `IFolderView`, `IPersistFolder2`, and `SHCreateItemFromIDList`.
- Invocation resolves a filesystem path and starts the installed helper with `CreateProcessW`, an explicit executable path, correctly quoted Unicode arguments, and `CREATE_NO_WINDOW`. It never launches a shell or passes the selected directory through PowerShell. Filesystem validation happens in the helper, outside Explorer's invocation thread.
- The icon references the existing `terax.exe` icon resource.

Installed layout:

```text
terax.exe
terax-cli.exe
shell-extension/
  TeraxExplorer.msix
  identity.json
  install.ps1
  <four-part-version>/TeraxShellExtension.dll
```

Versioned DLL paths avoid replacing the previous version while its COM surrogate still holds it. NSIS uninstall unregisters before deleting files and attempts reboot-time cleanup for locked integration files. MSI retains its existing installation scope; its custom actions impersonate the initiating user and registration runs at commit. An uninstall rollback schedules re-registration after MSI restores its files.

## Launch contract

```text
terax-cli.exe open-directory -- <absolute directory>
```

This is the Windows shell integration entry point, distinct from the ordinary file-opening CLI. It discovers the current user's existing authenticated control endpoint, deliberately ignoring inherited pane credentials. A per-user, per-session mutex serializes Explorer requests, including cold startup. Missing, inaccessible, non-directory, unsupported-Unicode, and oversized paths fail before starting the GUI.

If no live descriptor exists, the helper starts the sibling `terax.exe --open-directory <directory>` using Rust's Windows process APIs. The GUI validates that launch contract before initialization. First-run startup creates one strict local terminal in the requested directory, even when the saved default environment is WSL. Existing workspaces are restored rather than discarded.

The helper waits up to 25 seconds and sends the additive protocol-v1 method `open_directory` only after endpoint discovery. Only `frontend_not_ready` responses are retried; a response timeout is not replayed because the request might already have executed. Concurrent requests waiting for the launch mutex have a 30-second bound.

Rust canonicalizes the directory, checks accessibility, and explicitly authorizes the requested workspace. React handles requests only after workspace hydration, reuses a matching non-private local terminal or local space, and otherwise creates the requested local space/terminal. It shows and unminimizes the window and requests focus; the helper transfers foreground permission when Windows permits it. Windows paths are never routed into WSL terminals.

An explicit directory terminal carries an ephemeral `requireCwd` flag through the existing PTY path. Missing directories produce a startup error rather than silently opening home. The flag is not persisted: ordinary stale-workspace restoration retains its existing fallback behavior.

Windows command-line limits still apply: the full helper command must fit 32,767 UTF-16 code units, directory requests must fit 48 KiB of UTF-8, and control messages remain capped at 64 KiB. UNC and extended-length paths are subject to Windows, ConPTY, and the chosen shell's own support. These require real-machine validation, not just argument-quoting tests.

## Build and development

Normal `pnpm tauri dev` does not require C++ tooling, an MSIX, or a certificate. Debug Cargo builds omit absent generated shell resources.

For an unsigned packaging check on Windows:

```powershell
pnpm build:windows-shell
powershell -NoProfile -File src-tauri/windows-shell/install.test.ps1
```

Build distributable installers with a fresh `pnpm tauri build`, not `tauri bundle` alone after Cargo tests. Tests can overwrite `target/debug/terax.exe` with a development-mode binary that expects `localhost:1420` instead of embedding the UI. Installer compilation alone does not catch this; verify GUI startup without a dev server. Use release installers for normal use to avoid the debug console.

The native build needs Visual Studio 2022 C++ Build Tools, CMake, and a Windows SDK containing MakeAppx and SignTool. x64 is exercised locally; ARM64 build selection is wired but unverified. Generated payloads are ignored by Git. Standard `pnpm tauri build` invokes this Windows-only build automatically; Linux/macOS skip it.

Without a configured publisher the build produces an **unsigned development** package. Installing it does not enable the modern menu: Windows rejects untrusted packages and the installer keeps the legacy menu. No certificate is imported and Developer Mode is never enabled. Sparse packaging uses Microsoft's documented `/nv` option for external executables; MakeAppx still validates the manifest schema.

## Production signing: maintainer action required

In plain language: **Windows needs a trusted signature on the small package that registers the menu.** Signing the outer setup program alone does not sign that inner package.

A SignPath administrator must:

1. Confirm that the project's signing service/policy supports MSIX with the production certificate. This cannot be determined or changed from repository code alone.
2. Create an artifact configuration that signs both files in the `windows-explorer-unsigned` GitHub artifact: `TeraxExplorer.msix` and `TeraxShellExtension.dll`.
3. Set repository variable `SIGNPATH_SHELL_ARTIFACT_CONFIGURATION_SLUG` to that configuration's slug.
4. Set repository variable `TERAX_SHELL_PUBLISHER` to the certificate's **exact Subject**, such as the complete `CN=..., O=..., C=...` string supplied by SignPath. Do not guess it. This is public certificate information, not a private key.
5. Approve the additional signing request during a release, just as for the existing installer signing request.

Tagged Windows releases fail early if these variables are missing. The workflow builds the native payload, obtains signed DLL/MSIX files, verifies both with SignTool, and only then embeds them in NSIS and MSI. `TERAX_SHELL_SIGNED_READY=1` makes the normal pre-build hook verify rather than regenerate those signed bytes. The existing outer installer signing and regenerated Tauri updater signatures remain in their original sequence afterward.

## Installation, failure recovery, and uninstall

Both installers create legacy fallback verbs before attempting modern registration; MSI owns its fallback as declarative component resources, so a policy-blocked PowerShell process does not prevent installation of a usable menu. Both call the installed PowerShell script for **registration only**, using `-File`, not interpolated PowerShell expressions. Windows PowerShell and AppX deployment are built-in Windows facilities; neither is used to launch selected directories.

- Windows 10 retains the existing HKCU directory/background/drive verbs and does not attempt MSIX deployment.
- Windows 11 calls `Add-AppxPackage -ExternalLocation <install directory>`. Windows verifies package trust; the script checks registered identity, version, status, and COM class afterward.
- Successful registration removes the two legacy directory verbs to avoid duplicates. The legacy drive verb remains because the modern manifest does not support `Drive`.
- The script retains a known-good signed MSIX under `%LOCALAPPDATA%\Terax\shell-registration` for post-deployment rollback. Failed deployment leaves the previous registration intact when its DLL still exists. A failed MSI major upgrade that already removed that DLL removes the stale identity and retains the legacy fallback instead.
- Ownership is recorded under `HKCU\Software\Crynta\Terax\Explorer`; an old installation at another location cannot unregister a newer installation's identity.
- Uninstall removes this user's matching identity and integration-owned backup state, not workspaces, credentials, terminal history, or external tool settings. The registration script and NSIS cleanup check the legacy command's installation path; MSI also owns its declarative fallback values as component resources. A failed per-user package removal stops NSIS/MSI file deletion rather than intentionally leaving an orphan identity.
- Integration failures are logged to `%LOCALAPPDATA%\Terax\shell-integration.log`; setup remains usable with the legacy fallback. The shell cache is notified without forcibly restarting Explorer.

**Scope limit:** interactive MSI installation registers the initiating user only. SYSTEM/service-account deployment and automatic registration for every user of a machine-wide MSI are not implemented. The script refuses to register into a service account. NSIS remains the normal no-admin, per-user installation path.

## Evidence and outstanding acceptance gate

Verified on the x64 Windows 11 development host:

- C++ release DLL and tests compile with `/W4 /WX`, static CRT, ASLR/DEP/CFG.
- Real DLL loading, COM lifetime, directory/background selection, file/virtual/multi-selection exclusion, Unicode and metacharacter argument quoting, and `CreateProcessW` forwarding to a test helper pass.
- MakeAppx produces the unsigned sparse package with a valid manifest schema.
- Ten mocked installer lifecycle cases pass, including Windows 10 legacy cleanup, changed publishers, and failed package removal. These do not install anything or test Explorer. Production verification also rejects the unsigned development package.
- Fresh unsigned **release** NSIS and MSI installers compile (4.35 MiB and 5.48 MiB). For local packaging only, updater artifacts were disabled through an ignored configuration override; production signing settings were not changed. Earlier debug installers were re-bundled after Cargo tests and contained a development-server binary: those artifacts are invalid for distribution. Read-only MSI database inspection confirms all three custom actions and the five required payload/helper files.
- The rebuilt release executable embeds the current frontend entry and has PE GUI subsystem 2 (no console). A direct startup smoke check produced a visible workspace window and a successful frontend `identify --json` response without a dev server. This verifies executable startup, not installed-product or Explorer acceptance.
- 1,869 frontend tests pass (one skipped), including directory delivery and focus-denial acknowledgement; 482 Rust workspace tests pass. Type checks and a development Cargo check with the generated Explorer payload absent pass.

Still required on clean Windows 11 installations using **signed release artifacts**, for both installer formats:

- Verify trusted MSIX installation and the visible modern-menu label/icon for a folder and directory background, without opening Show more options.
- Verify files, multiple selections, Libraries, This PC, and other virtual locations do not expose the command.
- Exercise cold/warm starts, repeated clicks, restoration, minimized windows, first-run WSL defaults, Arabic/Unicode, spaces/metacharacters, secondary drives, UNC paths, supported long paths, deleted directories, and access-denied paths.
- Exercise upgrades while the DLL is loaded, same-version repair, changed installation location, registration failure/rollback, MSI rollback, and uninstall. Confirm no orphan package, broken menu, duplicate entry, or unintended data deletion.
- Verify Windows 10 legacy behavior on Windows 10 itself.
- Measure menu latency and verify that Explorer does not need a forced restart. Windows may require sign-out to refresh package registration caches; establish the supported behavior from actual testing.

No production signing approval, trust-store modification, package registration, signed-install test, or real Explorer acceptance test has been performed in this implementation session.

## References

- [Microsoft: packaged File Explorer commands](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/integrate-packaged-app-with-file-explorer)
- [Microsoft: identity with external location](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps)
- [Microsoft: IExplorerCommand::GetState](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-iexplorercommand-getstate)
- [Microsoft: CreateProcessW](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw)
