# Website Portfolio Card — Project 2

## Short Description (for card subtitle)
Zero Trust device enforcement using Microsoft Intune, BitLocker, and Conditional Access in a Microsoft 365 Business Premium environment.

## 150-Word Portfolio Summary
This project implements the device trust layer of the Zero Trust security model using Microsoft Intune as the MDM authority. The lab environment runs a Windows 11 23H2 device (PTC_01) joined to Microsoft Entra ID with automatic Intune enrollment configured for all users. A Windows compliance policy (CP-WIN-01) enforces BitLocker encryption, antivirus registration, and a minimum OS build of 22631.6199. Devices that fail any check are marked non-compliant immediately, blocking access via Conditional Access policy CA-DEV-01. BitLocker is deployed through Intune Endpoint Security using XTS-AES 128-bit encryption, with recovery keys escrowed to Entra ID automatically. The Microsoft Defender for Endpoint–Intune connector is active, enabling risk-based device signals as a future expansion point. All policies were validated through the Report-only → validate → enforce methodology, with the device progressing from non-compliant to compliant after BitLocker remediation.

## Key Technologies
- Microsoft Intune (MDM)
- Microsoft Entra ID (Entra ID Join)
- BitLocker (XTS-AES 128)
- Conditional Access — CA-DEV-01
- Microsoft Defender for Endpoint
- Windows 11 23H2
- Microsoft Graph PowerShell

## Card Metadata
| Field | Value |
|---|---|
| Status | Live |
| Difficulty | Advanced |
| Estimated Reading Time | 12 min |
| Zero Trust Pillar | Devices |
| Licence | MIT |

## Portfolio Card Copy (HTML/site use)
**Zero Trust Device Trust Enforcement**
Enforce device compliance using Intune MDM, BitLocker encryption with Entra ID key escrow, and Conditional Access. Covers the complete lifecycle: enrolment → compliance policy → disk encryption → CA enforcement.
`Intune` · `BitLocker` · `Conditional Access` · `Defender for Endpoint`
