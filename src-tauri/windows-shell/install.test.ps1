# Pure mocked lifecycle tests: never register packages, change trust, or write the registry.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'install.ps1'))
# Keep exit semantics scoped to this test invocation rather than terminating the test runner.
$run = [scriptblock]::Create($source.Replace('exit 0', 'return').Replace('exit 1', 'throw "registration failed"'))
$script:identity = @{ name = 'Crynta.Terax.Explorer'; publisher = 'CN=Test'; version = '0.9.0.0'; arch = 'x64' }
$script:manifest = [xml]([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'AppxManifest.xml.in')).Replace('@VERSION@', '0.9.0.0').Replace('@ARCH@', 'x64').Replace('@PUBLISHER@', 'CN=Test'))
Add-Type 'using System; public static class TeraxShellRefresh { public static void SHChangeNotify(uint a, uint b, IntPtr c, IntPtr d) {} }'
function Add-Type { param($TypeDefinition) }
function New-Item { param($Path, $ItemType, [switch]$Force) }
function New-ItemProperty { param($Path, $Name, $Value, [switch]$Force) $script:writes.Add("$Name=$Value") }
function Set-Item {
    param($Path, $Value)
    $script:writes.Add("legacy=$Path")
    if ($Path -like '*\command') { $script:legacyCommand = $Value }
}
function Get-Item {
    param($Path, $ErrorAction)
    if (-not $script:legacyCommand) { return $null }
    $key = [pscustomobject]@{}
    $key | Add-Member -MemberType ScriptMethod -Name GetValue -Value { param($Name) return $script:legacyCommand }
    return $key
}
function Remove-Item { param($Path, [switch]$Recurse, [switch]$Force, $ErrorAction) $script:removed.Add($Path) }
function Add-Content { param($Path, $Value) }
function Copy-Item { param($Path, $Destination, [switch]$Force) }
function Move-Item { param($Path, $Destination, [switch]$Force) }
function Test-Path { param($Path, $PathType) return ($script:oldDllExists -or $Path -notlike '*0.8.0.0*TeraxShellExtension.dll') }
function Get-Content { param($Path, [switch]$Raw) return ($script:identity | ConvertTo-Json) }
function Get-ItemProperty {
    param($Path, $ErrorAction)
    if ($Path -like 'HKLM:*') { return @{ CurrentBuildNumber = $script:build } }
    if ($script:previous) { return [pscustomobject]$script:previous }
    return $null
}
function Add-AppxPackage {
    param($Path, $ExternalLocation, [switch]$ForceUpdateFromAnyVersion, $ErrorAction)
    $script:deployments.Add("$Path|$ExternalLocation")
    if ($script:failDeployment -and -not $ForceUpdateFromAnyVersion) { throw 'Untrusted signature (mock)' }
}
function Remove-AppxPackage { param($Package) if ($script:failUninstall) { throw 'Package removal failed (mock)' }; $script:removed.Add("package=$Package") }
function Get-AppxPackage {
    param($Name)
    return [pscustomobject]@{ Publisher = 'CN=Test'; Version = [version]'0.9.0.0'; Architecture = 'X64'; Status = 'Ok'; PackageFullName = 'test-package' }
}
function Get-AppxPackageManifest {
    param($Package)
    if ($script:failVerification) { throw 'Invalid registered manifest (mock)' }
    return $script:manifest
}
function Reset-Test {
    $script:build = 26100
    $script:previous = $null
    $script:failDeployment = $false
    $script:failVerification = $false
    $script:oldDllExists = $true
    $script:legacyCommand = $null
    $script:failUninstall = $false
    $script:writes = [Collections.Generic.List[string]]::new()
    $script:removed = [Collections.Generic.List[string]]::new()
    $script:deployments = [Collections.Generic.List[string]]::new()
}
function Check([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
function Run-Install([bool]$shouldFail = $false) {
    $failed = $false
    try { & $run -Action Install -InstallDir 'C:\Terax' | Out-Null } catch { $failed = $true }
    Check ($failed -eq $shouldFail) 'Unexpected installation result'
}
Reset-Test
$script:build = 19045
Run-Install
Check ($script:deployments.Count -eq 0) 'Windows 10 must never attempt MSIX registration'
Check ($script:writes.Count -gt 0) 'Windows 10 must retain legacy entries'
& $run -Action Uninstall -InstallDir 'C:\Terax' | Out-Null
Check ($script:removed.Count -eq 3) 'Windows 10 MSI uninstall must remove its legacy entries without a modern ownership record'
Reset-Test
Run-Install
Check ($script:deployments.Count -eq 1) 'Windows 11 should register exactly once'
Check ($script:removed.Count -eq 2) 'Only the two directory legacy verbs should be removed'
Check (@($script:removed | Where-Object { $_ -like '*Drive*' }).Count -eq 0) 'Drive legacy menu must survive'
Reset-Test
$script:failDeployment = $true
Run-Install $true
Check ($script:removed.Count -eq 0) 'Failed registration must not remove previous packages or legacy entries'
Reset-Test
$script:previous = @{ InstallDir = 'C:\Terax'; Publisher = 'CN=Test'; Version = '0.8.0.0' }
$script:failVerification = $true
Run-Install $true
Check ($script:deployments.Count -eq 2) 'Post-deployment failure must restore the known-good MSIX'
Reset-Test
$script:previous = @{ InstallDir = 'C:\Terax'; Publisher = 'CN=Test'; Version = '0.8.0.0' }
& $run -Action Uninstall -InstallDir 'C:\Terax' | Out-Null
Check ($script:removed.Contains('package=test-package')) 'Uninstall must unregister the current user package'
Reset-Test
$script:previous = @{ InstallDir = 'D:\NewTerax'; Publisher = 'CN=Test'; Version = '0.8.0.0' }
$script:legacyCommand = '"D:\NewTerax\terax.exe" "%V"'
& $run -Action Uninstall -InstallDir 'C:\Terax' | Out-Null
Check ($script:removed.Count -eq 0) 'An old installation must not unregister a newer installation elsewhere'
Reset-Test
$script:previous = @{ InstallDir = 'C:\Terax'; Publisher = 'CN=Test'; Version = '0.8.0.0' }
$script:failDeployment = $true
$script:oldDllExists = $false
Run-Install $true
Check ($script:removed.Contains('package=test-package')) 'A failed MSI upgrade must not leave a modern command pointing to a deleted DLL'
Reset-Test
$script:previous = @{ InstallDir = 'C:\Terax'; Publisher = 'CN=Other'; Version = '0.8.0.0' }
Run-Install $true
Check ($script:deployments.Count -eq 0) 'A changed publisher must not create a second package family'
Reset-Test
$script:previous = @{ InstallDir = 'C:\Terax'; Publisher = 'CN=Test'; Version = '0.8.0.0' }
$script:failUninstall = $true
$script:legacyCommand = '"C:\Terax\terax.exe" --open-directory "%V"'
$failed = $false
try { & $run -Action Uninstall -InstallDir 'C:\Terax' | Out-Null } catch { $failed = $true }
Check $failed 'Failed package removal must report failure before the installer deletes files'
Check ($script:removed.Count -eq 0) 'Failed removal must leave existing legacy verbs and ownership intact'
Write-Output '10 mocked installer lifecycle cases passed (not an Explorer or signed-install test).'
