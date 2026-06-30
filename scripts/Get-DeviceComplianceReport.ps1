<#
.SYNOPSIS
    Exports a full device compliance report from Microsoft Intune via Microsoft Graph.

.DESCRIPTION
    Retrieves all managed Windows devices and outputs per-device:
      - Display name, UPN, Entra ID join type, OS version, OS build
      - Compliance state, last check-in, encryption status
      - Intune management agent, ownership

    Exports to CSV. Designed for weekly compliance reviews and recruiter demo.
    Project: https://github.com/lokeshm-it/Project-2-Zero-Trust-Device-Trust-Enforcement

.PARAMETER TenantId
    Microsoft Entra ID tenant ID (GUID).

.PARAMETER OutputPath
    Folder where the CSV report is saved. Defaults to current directory.

.PARAMETER OSFilter
    Filter results to a specific OS. Default 'Windows'. Use 'All' for cross-platform.

.EXAMPLE
    .\Get-DeviceComplianceReport.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -OutputPath "C:\Reports"

.NOTES
    Author  : Lokesh Karnam
    Version : 1.0
    Requires: Microsoft.Graph.DeviceManagement
    Scopes  : DeviceManagementManagedDevices.Read.All
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$TenantId,

    [string]$OutputPath = (Get-Location).Path,

    [ValidateSet('Windows','All')]
    [string]$OSFilter = 'Windows'
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

#region — Module check
$required = @('Microsoft.Graph.Authentication','Microsoft.Graph.DeviceManagement')
foreach ($mod in $required) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Log "Installing $mod..." 'WARN'
        Install-Module $mod -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $mod -ErrorAction Stop
}
#endregion

#region — Connect
Write-Log "Connecting to Microsoft Graph..."
Connect-MgGraph -TenantId $TenantId `
    -Scopes 'DeviceManagementManagedDevices.Read.All' `
    -ErrorAction Stop
Write-Log "Connected."
#endregion

#region — Retrieve devices
Write-Log "Retrieving managed devices (OS filter: $OSFilter)..."

$selectFields = 'deviceName,userPrincipalName,operatingSystem,osVersion,complianceState,' +
                'lastSyncDateTime,isEncrypted,azureADDeviceId,joinType,' +
                'managementAgent,ownerType,id'

if ($OSFilter -eq 'Windows') {
    $filter = "operatingSystem eq 'Windows'"
    $devices = Get-MgDeviceManagementManagedDevice -Filter $filter -All -Property $selectFields
} else {
    $devices = Get-MgDeviceManagementManagedDevice -All -Property $selectFields
}

Write-Log "Retrieved $($devices.Count) device(s)."
#endregion

#region — Build report rows
$report = foreach ($d in $devices) {
    [PSCustomObject]@{
        DeviceName       = $d.DeviceName
        UPN              = $d.UserPrincipalName
        OS               = $d.OperatingSystem
        OSVersion        = $d.OsVersion
        ComplianceState  = $d.ComplianceState
        IsEncrypted      = $d.IsEncrypted
        LastCheckIn      = if ($d.LastSyncDateTime) { $d.LastSyncDateTime.ToString('yyyy-MM-dd HH:mm') } else { 'Never' }
        JoinType         = $d.JoinType
        ManagementAgent  = $d.ManagementAgent
        Ownership        = $d.OwnerType
        EntraDeviceId    = $d.AzureAdDeviceId
        IntuneDeviceId   = $d.Id
    }
}
#endregion

#region — Summary to console
$compliant    = ($report | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
$nonCompliant = ($report | Where-Object { $_.ComplianceState -eq 'noncompliant' }).Count
$encrypted    = ($report | Where-Object { $_.IsEncrypted -eq $true }).Count
$total        = $report.Count

Write-Log "--- Compliance Summary ---"
Write-Log "Total devices  : $total"
Write-Log "Compliant      : $compliant"
Write-Log "Non-compliant  : $nonCompliant"
Write-Log "Encrypted      : $encrypted"
Write-Log "Not encrypted  : $($total - $encrypted)" $(if ($total - $encrypted -gt 0) { 'WARN' } else { 'INFO' })
#endregion

#region — Export
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$timestamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputFile = Join-Path $OutputPath "DeviceCompliance-$timestamp.csv"

$report | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Log "Report saved: $outputFile"
#endregion

Disconnect-MgGraph | Out-Null
