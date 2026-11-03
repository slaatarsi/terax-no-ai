param([switch]$VerifySigned)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $root 'tauri.conf.json') -Raw | ConvertFrom-Json
$version = "$($config.version).0"
if ($version -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Shell packages require a numeric four-part version' }
$arch = if ($env:TERAX_CLI_TARGET -like 'aarch64-*') { 'arm64' } else { 'x64' }
if ($env:TERAX_CLI_TARGET -and $env:TERAX_CLI_TARGET -notmatch '^(x86_64|aarch64)-pc-windows-msvc$') { throw 'Unsupported Explorer architecture' }
$generated = Join-Path $PSScriptRoot 'generated'
$payload = Join-Path $generated 'payload'
$native = Join-Path $root "target/windows-shell-$arch"
$kits = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots').KitsRoot10
$sdk = Get-ChildItem (Join-Path $kits 'bin') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'x64/makeappx.exe') } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $sdk) { throw 'Windows 10/11 SDK packaging tools are required' }
$signtool = Join-Path $sdk.FullName 'x64/signtool.exe'
if ($VerifySigned) {
    $identity = Get-Content (Join-Path $payload 'identity.json') -Raw | ConvertFrom-Json
    if ($identity.version -ne $version -or $identity.arch -ne $arch -or $identity.publisher -ne $env:TERAX_SHELL_PUBLISHER) { throw 'Signed shell payload does not match this release' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $payload 'TeraxExplorer.msix'))
    try {
        $entry = $archive.GetEntry('AppxManifest.xml')
        if (-not $entry) { throw 'Signed MSIX has no manifest' }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { $signedManifest = [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
        $id = $signedManifest.Package.Identity
        if ($id.Name -ne $identity.name -or $id.Publisher -ne $identity.publisher -or $id.Version -ne $version -or $id.ProcessorArchitecture -ne $arch) { throw 'Signed MSIX identity does not match this release' }
    } finally { $archive.Dispose() }
    foreach ($file in @('TeraxExplorer.msix', "$version/TeraxShellExtension.dll")) {
        & $signtool verify /pa (Join-Path $payload $file)
        if ($LASTEXITCODE -ne 0) { throw "Untrusted or unsigned shell artifact: $file" }
    }
    exit 0
}
$cmake = Get-Command cmake.exe -ErrorAction SilentlyContinue
if ($cmake) { $cmake = $cmake.Source } else {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = & $vswhere -latest -version '[17.0,18.0)' -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $cmake = Join-Path $vs 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
}
$platform = if ($arch -eq 'arm64') { 'ARM64' } else { 'x64' }
& $cmake -S $PSScriptRoot -B $native -G 'Visual Studio 17 2022' -A $platform
if ($LASTEXITCODE -ne 0) { throw 'Explorer CMake configuration failed' }
& $cmake --build $native --config Release
if ($LASTEXITCODE -ne 0) { throw 'Explorer native build failed' }
if ($arch -eq 'x64') {
    & (Join-Path (Split-Path $cmake) 'ctest.exe') --test-dir $native -C Release --output-on-failure
    if ($LASTEXITCODE -ne 0) { throw 'Explorer native tests failed' }
}
# Never silently treat a development publisher as a production signing identity.
$publisher = $env:TERAX_SHELL_PUBLISHER
if (-not $publisher) { $publisher = 'CN=Terax Development'; Write-Warning 'Building an unsigned development MSIX; installers will retain the legacy menu.' }
if (Test-Path $generated) { Remove-Item $generated -Recurse -Force }
$package = Join-Path $generated 'package'
$assets = Join-Path $package 'Assets'
New-Item $assets, (Join-Path $payload $version) -ItemType Directory -Force | Out-Null
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Image]::FromFile((Join-Path $root 'icons/128x128.png'))
try {
    foreach ($entry in @(@('StoreLogo', 50), @('Square150x150Logo', 150), @('Square44x44Logo', 44))) {
        $image = New-Object System.Drawing.Bitmap($icon, [System.Drawing.Size]::new($entry[1], $entry[1]))
        try { $image.Save((Join-Path $assets "$($entry[0]).png"), [System.Drawing.Imaging.ImageFormat]::Png) } finally { $image.Dispose() }
    }
} finally { $icon.Dispose() }
$manifest = (Get-Content (Join-Path $PSScriptRoot 'AppxManifest.xml.in') -Raw).Replace('@VERSION@', $version).Replace('@ARCH@', $arch).Replace('@PUBLISHER@', [System.Security.SecurityElement]::Escape($publisher))
[System.IO.File]::WriteAllText((Join-Path $package 'AppxManifest.xml'), $manifest, [System.Text.UTF8Encoding]::new($false))
# Sparse packages reference external executables; Microsoft's packaging recipe requires /nv.
& (Join-Path $sdk.FullName 'x64/makeappx.exe') pack /d $package /p (Join-Path $payload 'TeraxExplorer.msix') /nv /o
if ($LASTEXITCODE -ne 0) { throw 'Sparse MSIX packaging failed' }
Copy-Item (Join-Path $native 'Release/TeraxShellExtension.dll') (Join-Path $payload "$version/TeraxShellExtension.dll")
Copy-Item (Join-Path $PSScriptRoot 'install.ps1') $payload
@{ name = 'Crynta.Terax.Explorer'; publisher = $publisher; version = $version; arch = $arch } | ConvertTo-Json | Set-Content (Join-Path $payload 'identity.json') -Encoding UTF8
Write-Host "Explorer payload: $payload"
