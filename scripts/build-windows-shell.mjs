import { spawnSync } from "node:child_process";

if (process.platform === "win32") {
  const args = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", "src-tauri/windows-shell/build.ps1"];
  if (process.env.TERAX_SHELL_SIGNED_READY === "1") args.push("-VerifySigned");
  const result = spawnSync("powershell.exe", args, { stdio: "inherit" });
  if (result.error) throw result.error;
  process.exit(result.status ?? 1);
}
