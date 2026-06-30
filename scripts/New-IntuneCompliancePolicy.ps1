<#
.SYNOPSIS
    Deploys the Windows 10/11 compliance policy (CP-WIN-01) to Microsoft Intune via Microsoft Graph.

.DESCRIPTION
    Creates a Windows compliance policy requiring:
      - BitLocker enabled
      - Minimum OS build 22631.6199 (Windows 11 23H2)
      - Antivirus registered and enabled
      - Non-compliance action: Mark immediately
    Assigns the policy to All Devices.

    Part of the Zero Trust Device Trust Enforcement framework.
    Project: https://github.com/lokeshm-it/Project-2-Zero-Trust-Device-Trust-Enforcement

.PARAMETER TenantId
    Microsoft Entra ID tenant ID (GUID).

.PARAMETER AssignToAllDevices
    Switch. When specified, assigns the policy to the All Devices group.

.EXAMPLE
    .\New-IntuneCompliancePolicy.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -AssignToAllDevices

.NOTES
    Author  : Lokesh Karnam
    Version : 1.0
    Requires: Microsoft.Graph.DeviceManagement module
    Scopes  : DeviceManagementConfiguration.ReadWrite.All
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$TenantId,

    [switch]$AssignToAllDevices
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
Write-Log "Checking required modules..."
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
Write-Log "Connecting to Microsoft Graph (tenant: $TenantId)..."
Connect-MgGraph -TenantId $TenantId `
    -Scopes 'DeviceManagementConfiguration.ReadWrite.All' `
    -ErrorAction Stop
Write-Log "Connected."
#endregion

#region — Policy definition
$policyName        = 'CP-WIN-01 - Windows 11 Compliance Baseline'
$policyDescription = 'Zero Trust baseline: BitLocker, AV, minimum OS build 22631.6199. Part of CA-DEV-01 enforcement chain.'

$compliancePolicyBody = @{
    '@odata.type'              = '#microsoft.graph.windows10CompliancePolicy'
    displayName                = $policyName
    description                = $policyDescription
    bitLockerEnabled           = $true
    antivirusRequired          = $true
    antiSpywareRequired        = $true
    osMinimumVersion           = '10.0.22631.6199'
    scheduledActionsForRule    = @(
        @{
            ruleName                      = 'PasswordRequired'
            scheduledActionConfigurations = @(
                @{
                    actionType        = 'block'
                    gracePeriodHours  = 0
                    notificationTemplateId = ''
                }
            )
        }
    )
}
#endregion

#region — Create policy
Write-Log "Creating compliance policy: '$policyName'..."
if ($PSCmdlet.ShouldProcess($policyName, 'Create Intune compliance policy')) {
    try {
        $policy = New-MgDeviceManagementDeviceCompliancePolicy `
            -BodyParameter $compliancePolicyBody `
            -ErrorAction Stop

        Write-Log "Policy created — ID: $($policy.Id)"
    }
    catch {
        Write-Log "Failed to create policy: $_" 'ERROR'
        throw
    }
}
#endregion

#region — Assignment
if ($AssignToAllDevices -and $policy) {
    Write-Log "Assigning policy to All Devices..."

    $assignmentBody = @{
        assignments = @(
            @{
                target = @{
                    '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                }
            }
        )
    }

    if ($PSCmdlet.ShouldProcess($policy.Id, 'Assign compliance policy to All Devices')) {
        try {
            $null = Invoke-MgGraphRequest `
                -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/$($policy.Id)/assign" `
                -Body ($assignmentBody | ConvertTo-Json -Depth 5) `
                -ContentType 'application/json'

            Write-Log "Assignment complete — All Devices."
        }
        catch {
            Write-Log "Assignment failed: $_" 'ERROR'
        }
    }
}
#endregion

Write-Log "Done. Policy '$policyName' is active in Intune."
Write-Log "Next step: validate in Intune > Device compliance > Policies > CP-WIN-01."

Disconnect-MgGraph | Out-Null
