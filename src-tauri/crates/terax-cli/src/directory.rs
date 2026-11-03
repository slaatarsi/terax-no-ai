use super::*;
use std::hash::{Hash, Hasher};
use std::os::windows::ffi::OsStrExt;
use std::os::windows::process::CommandExt;
use std::path::Path;
use std::time::Instant;
use windows_sys::Win32::Foundation::{CloseHandle, HANDLE, WAIT_ABANDONED, WAIT_OBJECT_0};
use windows_sys::Win32::System::Threading::{
    CreateMutexW, ReleaseMutex, WaitForSingleObject, CREATE_NO_WINDOW,
};
use windows_sys::Win32::UI::WindowsAndMessaging::{
    AllowSetForegroundWindow, MessageBoxW, MB_ICONERROR, MB_OK,
};

pub(super) fn parse(mut args: Vec<OsString>) -> Result<Action, CliError> {
    if args.first().is_some_and(|arg| arg == "--") {
        args.remove(0);
    }
    if args.len() != 1 {
        return Err(usage_error("open-directory requires exactly one directory"));
    }
    let path = PathBuf::from(&args[0]);
    if !path.is_absolute() {
        return Err(usage_error("directory must be an absolute filesystem path"));
    }
    let path = std::fs::canonicalize(path)
        .map_err(|e| usage_error(format!("cannot resolve directory: {e}")))?;
    if !path.is_dir() {
        return Err(usage_error("path is not a directory"));
    }
    std::fs::read_dir(&path).map_err(|e| usage_error(format!("directory is inaccessible: {e}")))?;
    if !path.to_str().is_some_and(|value| value.len() <= 48 * 1024) {
        return Err(usage_error(
            "directory exceeds the supported Unicode path limit",
        ));
    }
    Ok(Action::OpenDirectory(path))
}

struct LaunchLock(HANDLE);
impl Drop for LaunchLock {
    fn drop(&mut self) {
        unsafe {
            ReleaseMutex(self.0);
            CloseHandle(self.0);
        }
    }
}

fn launch_lock(cache: &Path) -> Result<LaunchLock, CliError> {
    let mut hash = std::collections::hash_map::DefaultHasher::new();
    cache.hash(&mut hash);
    let name: Vec<u16> = format!("Local\\Terax.DirectoryOpen.{:016x}\0", hash.finish())
        .encode_utf16()
        .collect();
    unsafe {
        let handle = CreateMutexW(std::ptr::null(), 0, name.as_ptr());
        if handle.is_null() {
            return Err(io_error(std::io::Error::last_os_error()));
        }
        match WaitForSingleObject(handle, 30_000) {
            WAIT_OBJECT_0 | WAIT_ABANDONED => Ok(LaunchLock(handle)),
            _ => {
                CloseHandle(handle);
                Err(CliError::new(
                    "launch_busy",
                    "Another directory request is still starting Terax. Try again shortly.",
                    EXIT_UNAVAILABLE,
                ))
            }
        }
    }
}

fn discover(path: &Path) -> Result<Option<ControlDescriptor>, CliError> {
    let file = match std::fs::File::open(path) {
        Ok(file) => file,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(e) => return Err(io_error(e)),
    };
    let descriptor: ControlDescriptor = serde_json::from_reader(file.take(4096))
        .map_err(|e| CliError::new("invalid_descriptor", e.to_string(), EXIT_PROTOCOL))?;
    if !process_is_alive(descriptor.pid) {
        return Ok(None);
    }
    validate_endpoint(descriptor, true).map(Some)
}

pub(super) fn open(path: &Path) -> Result<(), CliError> {
    let path = path
        .to_str()
        .ok_or_else(|| usage_error("directory contains unsupported Unicode"))?;
    let cache = dirs::cache_dir().ok_or_else(|| usage_error("cannot locate user cache"))?;
    let _lock = launch_lock(&cache)?;
    let discovery = cache.join("terax/control.json");
    let mut endpoint = discover(&discovery)?;
    let mut child = None;
    if endpoint.is_none() {
        let exe = env::current_exe().map_err(io_error)?;
        let gui = exe
            .parent()
            .ok_or_else(|| usage_error("cannot locate Terax installation"))?
            .join("terax.exe");
        if !gui.is_file() || gui == exe {
            return Err(usage_error("Terax application is missing; reinstall Terax"));
        }
        child = Some(
            std::process::Command::new(&gui)
                .arg("--open-directory")
                .arg(path)
                // Tells the GUI this launch is the helper's cold start, not a shell verb to delegate.
                .env("TERAX_DIRECTORY_HELPER", "1")
                .current_dir(gui.parent().unwrap())
                .creation_flags(CREATE_NO_WINDOW)
                .spawn()
                .map_err(io_error)?,
        );
    }
    let deadline = Instant::now() + Duration::from_secs(25);
    let id = request_id();
    loop {
        if Instant::now() >= deadline {
            return Err(CliError::new(
                "startup_timeout",
                "Terax did not finish starting. Open Terax and try again.",
                EXIT_UNAVAILABLE,
            ));
        }
        if let Some(process) = child.as_mut() {
            if process.try_wait().map_err(io_error)?.is_some() {
                return Err(CliError::new(
                    "startup_failed",
                    "Terax exited before opening the directory",
                    EXIT_UNAVAILABLE,
                ));
            }
        }
        if let Some(target) = endpoint.as_ref() {
            // Transfer the shell user's foreground permission to the existing GUI process.
            unsafe {
                AllowSetForegroundWindow(target.pid);
            }
            let request = ControlRequest {
                protocol: PROTOCOL_VERSION,
                id: id.clone(),
                token: target.token.clone(),
                method: terax_control_protocol::METHOD_OPEN_DIRECTORY.into(),
                params: json!({ "path": path }),
                caller: CallerContext::default(),
            };
            let response = send_request(&target.address, &request)?;
            if response.ok {
                return Ok(());
            }
            let error = response
                .error
                .ok_or_else(|| usage_error("invalid directory-open response"))?;
            if error.code != "frontend_not_ready" {
                return Err(CliError::new(error.code, error.message, EXIT_REQUEST));
            }
        }
        std::thread::sleep(Duration::from_millis(100));
        endpoint = discover(&discovery)?;
    }
}

pub(super) fn show_error(message: &str) {
    let message: Vec<u16> = std::ffi::OsStr::new(message)
        .encode_wide()
        .chain(Some(0))
        .collect();
    let title: Vec<u16> = "Open in Terax\0".encode_utf16().collect();
    unsafe {
        MessageBoxW(
            std::ptr::null_mut(),
            message.as_ptr(),
            title.as_ptr(),
            MB_OK | MB_ICONERROR,
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn directory_arguments_preserve_unicode_and_metacharacters() {
        let root = tempfile::tempdir().unwrap();
        let path = root.path().join("مشروع & spaces (test)");
        std::fs::create_dir(&path).unwrap();
        let expected = std::fs::canonicalize(&path).unwrap();
        assert_eq!(
            parse(vec!["--".into(), path.into_os_string()]).unwrap(),
            Action::OpenDirectory(expected)
        );
        assert!(parse(vec!["relative".into()]).is_err());
        assert!(parse(vec![]).is_err());
        assert!(parse(vec![root.path().join("deleted").into_os_string()]).is_err());
        let file = root.path().join("file");
        std::fs::write(&file, "test").unwrap();
        assert!(parse(vec![file.into_os_string()]).is_err());
    }
    #[test]
    fn stale_discovery_does_not_target_another_process() {
        let root = tempfile::tempdir().unwrap();
        let path = root.path().join("control.json");
        assert!(discover(&path).unwrap().is_none());
        std::fs::write(
            &path,
            serde_json::to_vec(&ControlDescriptor {
                protocol: PROTOCOL_VERSION,
                address: "127.0.0.1:1".into(),
                token: "a".repeat(64),
                pid: 0,
                app_version: "test".into(),
            })
            .unwrap(),
        )
        .unwrap();
        assert!(discover(&path).unwrap().is_none());
        std::fs::write(&path, "corrupt").unwrap();
        assert!(discover(&path).is_err());
    }
}
