fn main() {
    configure_sidecar();
    configure_shell_integration();
    tauri_build::build()
}

fn configure_shell_integration() {
    if !std::env::var("TARGET").is_ok_and(|target| target.contains("windows")) {
        return;
    }
    const PAYLOAD: &str = "windows-shell/generated/payload/";
    println!("cargo:rerun-if-changed={PAYLOAD}");
    if std::path::Path::new(PAYLOAD)
        .join("TeraxExplorer.msix")
        .is_file()
    {
        return;
    }
    if std::env::var("PROFILE").as_deref() == Ok("release") {
        panic!("Explorer payload missing; run pnpm build:windows-shell before packaging");
    }
    // Ordinary development must not require the C++ toolchain or a signing certificate.
    let mut config = std::env::var("TAURI_CONFIG")
        .map(|value| serde_json::from_str(&value).expect("parse TAURI_CONFIG"))
        .unwrap_or_else(|_| serde_json::json!({}));
    config["bundle"]["resources"][PAYLOAD] = serde_json::Value::Null;
    std::env::set_var(
        "TAURI_CONFIG",
        serde_json::to_string(&config).expect("serialize TAURI_CONFIG"),
    );
}

fn configure_sidecar() {
    let Ok(target) = std::env::var("TARGET") else {
        return;
    };
    let extension = if target.contains("windows") {
        ".exe"
    } else {
        ""
    };
    let path = std::path::PathBuf::from("binaries").join(format!("terax-cli-{target}{extension}"));
    let valid =
        std::fs::metadata(&path).is_ok_and(|metadata| metadata.is_file() && metadata.len() > 0);
    if valid {
        return;
    }
    if std::env::var("PROFILE").as_deref() == Ok("release") {
        panic!(
            "release sidecar {} is missing or empty; run pnpm build:cli before packaging",
            path.display()
        );
    }

    let mut config = std::env::var("TAURI_CONFIG")
        .map(|value| serde_json::from_str(&value).expect("parse TAURI_CONFIG"))
        .unwrap_or_else(|_| serde_json::json!({}));
    config["bundle"]["externalBin"] = serde_json::json!([]);
    std::env::set_var(
        "TAURI_CONFIG",
        serde_json::to_string(&config).expect("serialize TAURI_CONFIG"),
    );
}
