# Screenshots Placement Guide

Maps every source file from `C:\Back\SOP-ZTs\Project_2\` to its repository destination.

---

## Screenshot Mapping

| Source Filename | Destination | What It Shows |
|---|---|---|
| `Appendix_A.1_ Intune Device Enrolled.png` | `images/A1-device-enrolled/01-device-enrolled-compliant.png` | PTC_01 enrolled in Intune: Managed by Intune, Compliant, Windows 11 23H2 |
| `Appendix_A.2_ Intune Device Auto Enrollment.png` | `images/A2-auto-enrollment/02-mdm-auto-enrollment-scope-all.png` | MDM auto-enrolment — scope set to All |
| `Appendix_A.3_ Device Compliance Status.png` | `images/A3-compliance-status/03-noncompliant-bitlocker-missing.png` | PTC_01 Noncompliant — BitLocker not enabled (correct detection) |
| `Appendix_A.4_ Device Compliance Policy Report Only.png` | `images/A4-ca-report-only/04-ca-dev-01-report-only.png` | CA-DEV-01 Require Compliant Device — Report-only state |
| `Appendix_A.5_ Defender Page.png` | `images/A5-defender-connection/05-defender-connector-active.png` | Defender for Endpoint connector: Enabled, last sync 10 Jan 2026 |
| `Appendix_A.6_ Device Compliance Policy Enabled.png` | `images/A6-ca-enforced/06-ca-dev-01-enforced.png` | CA-DEV-01 — State: On (enforced) |

---

## PDF Exports

| Source Filename | Destination |
|---|---|
| `Windows Compliance Polcy.pdf` | `exports/Windows-Compliance-Policy.pdf` |
| `Disk Encryption Policy.pdf` | `exports/Disk-Encryption-Policy.pdf` |

---

## Quick Copy (PowerShell)

```powershell
$Src  = "C:\Back\SOP-ZTs\Project_2"
$Dest = "C:\Back\SOP-ZTs\Microsoft 365 Infrastructure Portfolio\Project-2-Zero-Trust-Device-Trust-Enforcement"

Copy-Item "$Src\Appendix_A.1_ Intune Device Enrolled.png"         "$Dest\images\A1-device-enrolled\01-device-enrolled-compliant.png"
Copy-Item "$Src\Appendix_A.2_ Intune Device Auto Enrollment.png"  "$Dest\images\A2-auto-enrollment\02-mdm-auto-enrollment-scope-all.png"
Copy-Item "$Src\Appendix_A.3_ Device Compliance Status.png"       "$Dest\images\A3-compliance-status\03-noncompliant-bitlocker-missing.png"
Copy-Item "$Src\Appendix_A.4_ Device Compliance Policy Report Only.png" "$Dest\images\A4-ca-report-only\04-ca-dev-01-report-only.png"
Copy-Item "$Src\Appendix_A.5_ Defender Page.png"                  "$Dest\images\A5-defender-connection\05-defender-connector-active.png"
Copy-Item "$Src\Appendix_A.6_ Device Compliance Policy Enabled.png" "$Dest\images\A6-ca-enforced\06-ca-dev-01-enforced.png"

Copy-Item "$Src\Windows Compliance Polcy.pdf"  "$Dest\exports\Windows-Compliance-Policy.pdf"
Copy-Item "$Src\Disk Encryption Policy.pdf"    "$Dest\exports\Disk-Encryption-Policy.pdf"
```
