param(
    [Parameter(Mandatory=$true)][ValidateSet('Install', 'Uninstall')][string]$Action,
    [Parameter(Mandatory=$true)][string]$InstallDir
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$InstallDir = [IO.Path]::GetFullPath($InstallDir)
if ($InstallDir.Length -gt [IO.Path]::GetPathRoot($InstallDir).Length) { $InstallDir = $InstallDir.TrimEnd('\') }
$logDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Terax'
$stateKey = 'HKCU:\Software\Crynta\Terax\Explorer'
$backup = Join-Path $logDir 'shell-registration/known-good.msix'
$deployed = $false
$previous = $null
$menuKeys = @('Directory\shell\OpenInTerax', 'Directory\Background\shell\OpenInTerax', 'Drive\shell\OpenInTerax')
function Write-Log([string]$Message) {
    Write-Output $Message
    try {
        New-Item $logDir -ItemType Directory -Force | Out-Null
        Add-Content (Join-Path $logDir 'shell-integration.log') "$(Get-Date -Format o) $Action $Message"
    } catch { Write-Warning 'Could not write Explorer integration log' }
}
function Set-LegacyMenu {
    foreach ($relative in $menuKeys) {
        $key = "HKCU:\Software\Classes\$relative"
        New-Item "$key\command" -Force | Out-Null
        Set-Item $key -Value 'Open in Terax'
        New-ItemProperty $key -Name Icon -Value ('"{0}\terax.exe",0' -f $InstallDir) -Force | Out-Null
        New-ItemProperty $key -Name NoWorkingDirectory -Value '' -Force | Out-Null
        Set-Item "$key\command" -Value ('"{0}\terax.exe" --open-directory "%V"' -f $InstallDir)
    }
}
function Remove-LegacyMenu([switch]$KeepDrive, [switch]$OwnedOnly) {
    foreach ($relative in $menuKeys) {
        if ($KeepDrive -and $relative -eq 'Drive\shell\OpenInTerax') { continue }
        if ($OwnedOnly) {
            $key = Get-Item "HKCU:\Software\Classes\$relative\command" -ErrorAction SilentlyContinue
            if (-not $key -or $key.GetValue('') -notin @(('"{0}\terax.exe" --open-directory "%V"' -f $InstallDir), ('"{0}\terax.exe" "%V"' -f $InstallDir))) { continue }
        }
        Remove-Item "HKCU:\Software\Classes\$relative" -Recurse -Force -ErrorAction SilentlyContinue
    }
}
function Refresh-Shell {
    try {
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class TeraxShellRefresh { [DllImport("shell32.dll")] public static extern void SHChangeNotify(uint e, uint f, IntPtr a, IntPtr b); }'
        [TeraxShellRefresh]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    } catch { Write-Log 'Explorer cache notification failed; sign out and back in to refresh.' }
}
try {
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if ($sid -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
        Write-Warning 'Explorer registration requires an interactive installing user; service-account MSI deployment is not supported.'
        if ($Action -eq 'Uninstall') { exit 0 }
        exit 1
    }
    $identity = Get-Content (Join-Path $InstallDir 'shell-extension/identity.json') -Raw | ConvertFrom-Json
    if ($identity.name -ne 'Crynta.Terax.Explorer') { throw 'Unexpected shell package identity' }
    $previous = Get-ItemProperty $stateKey -ErrorAction SilentlyContinue
    if ($previous -and (-not $previous.PSObject.Properties['InstallDir'] -or -not $previous.PSObject.Properties['Publisher'] -or -not $previous.PSObject.Properties['Version'])) {
        Write-Log 'Ignoring an incomplete integration ownership record.'
        $previous = $null
    }
    if ($Action -eq 'Uninstall') {
        # An older installation must not unregister a newer installation at another location.
        if ($previous -and $previous.InstallDir -eq $InstallDir) {
            Get-AppxPackage -Name $identity.name | Where-Object { $_.Publisher -eq $previous.Publisher } | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName }
            Remove-Item $stateKey -Force
            Remove-Item (Split-Path $backup) -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log 'Per-user Explorer identity removed.'
        }
        Remove-LegacyMenu -OwnedOnly
        Refresh-Shell
        exit 0
    }
    Set-LegacyMenu
    $os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ([int]$os.CurrentBuildNumber -lt 22000) { Write-Log 'Windows 10: legacy menu retained.'; exit 0 }
    if ($identity.version -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Invalid shell package version' }
    if ($previous -and $previous.Publisher -ne $identity.publisher) { throw 'Changing the Explorer publisher requires an explicit package migration' }
    foreach ($file in @('terax.exe', 'terax-cli.exe', "shell-extension/$($identity.version)/TeraxShellExtension.dll")) {
        if (-not (Test-Path (Join-Path $InstallDir $file) -PathType Leaf)) { throw "Required integration file is missing: $file" }
    }
    $package = Join-Path $InstallDir 'shell-extension/TeraxExplorer.msix'
    # Deployment verifies the MSIX signature and trust. Never install a certificate or enable Developer Mode.
    Add-AppxPackage -Path $package -ExternalLocation $InstallDir -ErrorAction Stop
    $deployed = $true
    $registered = Get-AppxPackage -Name $identity.name | Where-Object { $_.Publisher -eq $identity.publisher -and $_.Version.ToString() -eq $identity.version -and $_.Architecture.ToString() -eq $identity.arch -and $_.Status -eq 'Ok' }
    if (-not $registered) { throw 'Explorer package registration could not be verified' }
    $manifest = Get-AppxPackageManifest -Package $registered.PackageFullName
    $com = $manifest.Package.Applications.Application.Extensions.Extension | Where-Object { $_.Category -eq 'windows.comServer' }
    $class = $com.ComServer.SurrogateServer.Class | Where-Object { $_.Id -eq '9D3E6AB2-63DC-4B7F-9184-A9F61282543B' }
    if (-not $class -or $class.Path -ne "shell-extension\$($identity.version)\TeraxShellExtension.dll") { throw 'Explorer COM registration does not match this installation' }
    New-Item (Split-Path $backup) -ItemType Directory -Force | Out-Null
    Copy-Item $package "$backup.pending" -Force
    New-Item $stateKey -Force | Out-Null
    New-ItemProperty $stateKey -Name InstallDir -Value $InstallDir -Force | Out-Null
    New-ItemProperty $stateKey -Name Publisher -Value $identity.publisher -Force | Out-Null
    New-ItemProperty $stateKey -Name Version -Value $identity.version -Force | Out-Null
    Move-Item "$backup.pending" $backup -Force
    Remove-LegacyMenu -KeepDrive
    Refresh-Shell
    Write-Log 'Windows 11 Explorer command registered for this user. Explorer may require sign-out to refresh its cache.'
} catch {
    Write-Log "Explorer integration failed: $($_.Exception.Message)"
    if ($Action -eq 'Install') {
        # Deployment failures preserve the previous package; post-deployment failures need explicit rollback.
        $oldDllAvailable = $previous -and (Test-Path (Join-Path $previous.InstallDir "shell-extension/$($previous.Version)/TeraxShellExtension.dll"))
        if ($deployed) {
            try {
                if ($oldDllAvailable -and (Test-Path $backup)) {
                    Add-AppxPackage -Path $backup -ExternalLocation $previous.InstallDir -ForceUpdateFromAnyVersion -ErrorAction Stop
                    New-ItemProperty $stateKey -Name InstallDir -Value $previous.InstallDir -Force | Out-Null
                    New-ItemProperty $stateKey -Name Publisher -Value $previous.Publisher -Force | Out-Null
                    New-ItemProperty $stateKey -Name Version -Value $previous.Version -Force | Out-Null
                    Write-Log 'Previous Explorer identity restored.'
                } else {
                    Get-AppxPackage -Name $identity.name | Where-Object { $_.Publisher -eq $identity.publisher } | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName }
                    Remove-Item $stateKey -Force -ErrorAction SilentlyContinue
                }
            } catch { Write-Log "Explorer rollback failed: $($_.Exception.Message)" }
        } elseif ($previous -and -not $oldDllAvailable) {
            # An MSI major upgrade may already have removed the previous version's DLL.
            try {
                Get-AppxPackage -Name $identity.name | Where-Object { $_.Publisher -eq $previous.Publisher } | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName }
                Remove-Item $stateKey -Force
                Write-Log 'Removed stale Explorer identity; legacy menu restored.'
            } catch { Write-Log "Stale identity cleanup failed: $($_.Exception.Message)" }
        }
        try { Set-LegacyMenu; Write-Log 'Legacy Open in Terax remains available under Show more options.' } catch { Write-Log "Legacy menu failed: $($_.Exception.Message)" }
    } elseif ($previous -and $previous.InstallDir -eq $InstallDir) {
        try { Set-LegacyMenu } catch { Write-Log "Legacy menu recovery failed: $($_.Exception.Message)" }
    }
    exit 1
}
