# 2.1 — Device Enrolment: Entra ID Join and MDM Auto-Enrolment

## Business Purpose
Before any compliance policy can be applied, a device must have a verified identity in Entra ID and be under Intune management. Entra ID Join establishes the device as a trusted principal in the directory. MDM auto-enrolment hands that device to Intune for policy management. Without these two steps, the device is invisible to the compliance engine and cannot satisfy CA-DEV-01.

---

## Step 1: Entra ID Join the Device

### Purpose
Register the Windows endpoint in Microsoft Entra ID, creating a device identity that Conditional Access can evaluate. This is the foundation of device-based Zero Trust — the device must be a known entity in the directory before it can be assessed.

### Configuration
On the Windows device:

```
Settings → Accounts → Access work or school → Connect
→ Select: Join this device to Microsoft Entra ID
→ Sign in: WillStone@Patchthecloud.onmicrosoft.com
→ Confirm organisation details
→ Restart device
```

### Verification
Open Command Prompt as Administrator and run:
```cmd
dsregcmd /status
```

Expected output confirms join:
```
AzureAdJoined : YES
WorkplaceJoined : NO
DomainJoined : NO
```

### Best Practice
- Use Entra ID Join (not Workplace Join / Register) for corporate-managed devices
- Entra ID Join gives the device a full identity in the directory — required for device compliance evaluation in Conditional Access
- For hybrid environments (on-premises AD + Entra ID), use Hybrid Entra ID Join instead

### Common Mistakes
| Mistake | Consequence |
|---|---|
| Using Workplace Join (Register) instead of Join | Device identity insufficient for CA-DEV-01 compliance requirement |
| Joining with a personal Microsoft account | Device not registered in corporate tenant |
| Not restarting after join | Enrolment token may not apply until restart |

---

## Step 2: MDM Auto-Enrolment

### Purpose
Once the device is Entra ID joined, MDM auto-enrolment automatically registers it with Intune during the join process. This eliminates manual enrolment steps and ensures every joined device immediately comes under Intune management.

### Configuration

**Navigation:** `Intune → Devices → Enrol devices → Automatic enrollment`

| Setting | Value |
|---|---|
| MDM user scope | **All** |
| MDM terms of use URL | https://portal.manage.microsoft.com/TermsofUse.aspx |
| MDM discovery URL | https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc |
| MDM compliance URL | https://portal.manage.microsoft.com/?portalAction=Compliance |
| WIP user scope | None |

> Screenshot evidence: `images/A2-auto-enrollment/02-mdm-auto-enrollment-scope-all.png`

### Verification
Navigate to: `Intune → Devices → Windows → Windows devices`

Expected device record:
| Field | Value |
|---|---|
| Device name | PTC_01 |
| Managed by | Intune |
| Ownership | Personal |
| Compliance | Compliant (after policy applied and BitLocker enabled) |
| OS | Windows 10.0.22631.6199 |
| Primary user | WillStone@Patchthecloud.onmicrosoft.com |

> Screenshot evidence: `images/A1-device-enrolled/01-device-enrolled-intune.png`

### Best Practice
- Set MDM user scope to **All** to ensure every Entra ID joined device is automatically managed
- Do not use scope groups unless there is a specific pilot requirement — unscoped devices become unmanaged silently
- MDM auto-enrolment only triggers on Entra ID Join; devices already joined before this setting was enabled need manual enrolment or re-join

### Common Mistakes
| Mistake | Consequence |
|---|---|
| MDM scope set to None or Some | Devices join Entra ID but are not managed by Intune; compliance cannot be evaluated |
| Custom MDM URLs overriding defaults | Enrolment fails or routes to wrong endpoint |
| Assuming MDM scope retroactively applies | Devices joined before scope change must be re-enrolled |
