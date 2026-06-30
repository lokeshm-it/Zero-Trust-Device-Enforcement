<#
.SYNOPSIS
    Backs up BitLocker recovery keys for Entra ID joined Windows devices to Microsoft Entra ID.

.DESCRIPTION
    Iterates through managed Windows devices and triggers BitLocker key backup to
    Entra ID for any device that does not already have keys escrowed.

    For devices already escrowed, confirms key presence and logs.
    Exports a backup status report to CSV.

    Part of the Zero Trust Device Trust Enforcement framework — ensures recovery key
    availability without requiring user access or physical presence.
    Project: https://github.com/lokeshm-it/Project-2-Zero-Trust-Device-Trust-Enforcement

.PARAMETER TenantId
    Microsoft Entra ID tenant ID (GUID).

.PARAMETER OutputPath
    Folder for the CSV status report. Defaults to current directory.

.PARAMETER RunLocal
    Switch. When run on the local machine, uses manage-bde to trigger key backup directly.
    Without this switch, only verifies key escrow status via Graph (read-only audit mode).

.EXAMPLE
    # Audit only — check which devices have keys escrowed
    .\Set-BitLockerBackup.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    # On local device: trigger backup of this machine's BitLocker key to Entra ID
    .\Set-BitLockerBackup.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -RunLocal

.NOTES
    Author  : Lokesh Karnam
    Version : 1.0
    Requires: Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement
              Microsoft.Graph.Identity.DirectoryManagement
    Scopes  : DeviceManagementManagedDevices.Read.All, BitlockerKey.ReadBasic.All
    Local   : Requires admin rights on local machine for manage-bde commands

.LINK
    https://learn.microsoft.com/en-us/mem/intune/protect/encrypt-devices
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$TenantId,

    [string]$OutputPath = (Get-Location).Path,

    [switch]$RunLocal
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region — Logging
function Write-Log {
    param ([string]$Message, [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $(switch ($Level) { 'WARN' { 'Yellow' } 'ERROR' { 'Red' } default { 'Cyan' } })
}
#endregion

#region — Local BitLocker backup (runs on this machine directly)
if ($RunLocal) {
    Write-Log "Local mode: backing up BitLocker keys for all encrypted volumes on this machine..."

    # Ensure admin
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Local mode requires Administrator rights. Re-run as Administrator." 'ERROR'
        exit 1
    }

    $volumes = Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq 'On' }
    if (-not $volumes) {
        Write-Log "No BitLocker-protected volumes found on this machine." 'WARN'
        exit 0
    }

    foreach ($vol in $volumes) {
        $drive = $vol.MountPoint
        Write-Log "Processing volume: $drive (KeyProtectorCount: $($vol.KeyProtector.Count))"

        $recoveryKey = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
        if (-not $recoveryKey) {
            Write-Log "No recovery password found on $drive. Adding one..." 'WARN'
            if ($PSCmdlet.ShouldProcess($drive, 'Add RecoveryPassword protector')) {
                Add-BitLockerKeyProtector -MountPoint $drive -RecoveryPasswordProtector | Out-Null
                $recoveryKey = (Get-BitLockerVolume $drive).KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
            }
        }

        foreach ($protector in $recoveryKey) {
            Write-Log "Backing up key protector $($protector.KeyProtectorId) for drive $drive..."
            if ($PSCmdlet.ShouldProcess($drive, 'BackupToAAD-BitLockerKeyProtector')) {
                try {
                    BackupToAAD-BitLockerKeyProtector -MountPoint $drive -KeyProtectorId $protector.KeyProtectorId
                    Write-Log "Key escrowed to Entra ID for $drive."
                }
                catch {
                    Write-Log "Escrow failed for $drive protector $($protector.KeyProtectorId): $_" 'ERROR'
                }
            }
        }
    }

    Write-Log "Local backup complete. Verify in Entra ID > Devices > [Device] > BitLocker keys."
    exit 0
}
#endregion

#region — Graph audit mode: check escrow status across all managed devices
Write-Log "Graph audit mode: checking BitLocker key escrow status via Microsoft Graph..."

$required = @('Microsoft.Graph.Authentication','Microsoft.Graph.DeviceManagement')
foreach ($mod in $required) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Log "Installing $mod..." 'WARN'
        Install-Module $mod -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $mod -ErrorAction Stop
}

Connect-MgGraph -TenantId $TenantId `
    -Scopes 'DeviceManagementManagedDevices.Read.All','BitlockerKey.ReadBasic.All' `
    -ErrorAction Stop
Write-Log "Connected."

Write-Log "Retrieving Windows managed devices..."
$devices = Get-MgDeviceManagementManagedDevice `
    -Filter "operatingSystem eq 'Windows'" `
    -Property 'deviceName,userPrincipalName,isEncrypted,azureADDeviceId,id' `
    -All

Write-Log "Retrieved $($devices.Count) Windows device(s). Checking key escrow..."

$report = foreach ($device in $devices) {
    $keyStatus = 'Unknown'

    try {
        # Query BitLocker recovery keys escrowed for this device
        $keys = Invoke-MgGraphRequest `
            -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$($device.AzureAdDeviceId)'" `
            -ErrorAction Stop

        $keyCount = ($keys.value | Measure-Object).Count
        $keyStatus = if ($keyCount -gt 0) { "Escrowed ($keyCount key(s))" } else { 'NOT escrowed' }
    }
    catch {
        $keyStatus = "Query failed: $($_.Exception.Message)"
    }

    [PSCustomObject]@{
        DeviceName      = $device.DeviceName
        UPN             = $device.UserPrincipalName
        IsEncrypted     = $device.IsEncrypted
        KeyEscrowStatus = $keyStatus
        EntraDeviceId   = $device.AzureAdDeviceId
        IntuneDeviceId  = $device.Id
    }
}
#endregion

#region — Console summary
$escrowed    = ($report | Where-Object { $_.KeyEscrowStatus -like 'Escrowed*' }).Count
$notEscrowed = ($report | Where-Object { $_.KeyEscrowStatus -eq 'NOT escrowed' }).Count
$total       = $report.Count

Write-Log "--- BitLocker Escrow Summary ---"
Write-Log "Total devices    : $total"
Write-Log "Keys escrowed    : $escrowed"
Write-Log "NOT escrowed     : $notEscrowed" $(if ($notEscrowed -gt 0) { 'WARN' } else { 'INFO' })
#endregion

#region — Export
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$timestamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputFile = Join-Path $OutputPath "BitLockerEscrowStatus-$timestamp.csv"
$report | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Log "Report saved: $outputFile"
#endregion

Disconnect-MgGraph | Out-Null
