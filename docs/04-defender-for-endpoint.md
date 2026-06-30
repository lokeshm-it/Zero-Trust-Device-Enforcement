# 2.4 — Microsoft Defender for Endpoint Integration

## Business Purpose
Compliance policies evaluate static device properties (BitLocker enabled, OS version, antivirus running). But they cannot detect active threats — a device can be technically compliant while actively compromised. Microsoft Defender for Endpoint adds **real-time risk signals** to the device trust model. When Defender detects a threat, the device risk score increases, and Conditional Access can block or restrict access automatically.

---

## Integration Architecture

```
Windows Device
    ↓ (Defender agent — built into Windows 10/11)
Microsoft Defender for Endpoint
    ↓ (Connector — Intune ↔ Defender)
Microsoft Intune
    ↓ (Machine Risk Score in compliance policy)
Conditional Access
    ↓ (Block if risk > acceptable threshold)
Access denied / granted
```

---

## Configuration: Enable Defender–Intune Connector

### Step 1: Enable in Microsoft Defender Portal

**Navigation:** `security.microsoft.com → Settings → Endpoints → Advanced features`

| Setting | Value |
|---|---|
| Microsoft Intune connection | **On** |

### Step 2: Enable in Intune

**Navigation:** `Intune → Endpoint security → Microsoft Defender for Endpoint`

| Setting | Value |
|---|---|
| Connect Windows devices version 10.0.15063 and above to Microsoft Defender for Endpoint | **On** |
| Allow Microsoft Defender for Endpoint to enforce Endpoint Security configurations | **On** |

### Verification

| Field | Value |
|---|---|
| Connection status | **Enabled** |
| Last synchronised | **10/01/2026 21:34:59** |
| Platforms connected | Windows, iOS, Android |

> Screenshot evidence: `images/A5-defender-connection/05-defender-connector-active.png`

---

## Device Onboarding Verification

After enabling the connector, verify device onboarding in the Defender portal:

**Navigation:** `security.microsoft.com → Assets → Devices`

Expected for `PTC_01`:
| Field | Expected Value |
|---|---|
| Onboarding status | Onboarded |
| Risk level | Low |
| Managed by | Intune |
| Exposure level | Low |

---

## Machine Risk Score in Compliance Policy (Production Recommendation)

The SOP notes that while the Defender connector is active, a **Machine Risk Score** condition is not yet included in the compliance policy for Windows. This is a recommended next step.

To add it to the compliance policy:

**Navigation:** `Intune → Devices → Compliance policies → Windows Compliance Policy → Edit → Device Health`

| Setting | Recommended Value |
|---|---|
| Require the device to be at or under the machine risk score | **Low** |

With this setting, a device that Defender rates as Medium, High, or Clear risk is immediately marked non-compliant, and CA-DEV-01 blocks access.

> **Note from Defender connector UI:** "The Microsoft Defender for Endpoint connector is active for Windows, iOS, and Android but a risk assessment is not included in a compliance policy for these platforms. To protect devices on these platforms, click here to set up a compliance policy with the Machine Risk Score settings configured in the Microsoft Defender for Endpoint section."

This notice confirms the connector is working and is a prompt to add risk score enforcement — documented here as a future improvement.

---

## Validation

1. Navigate to: `Intune → Endpoint security → Microsoft Defender for Endpoint`
2. Confirm Connection status: **Enabled**
3. Confirm Last synchronised timestamp is recent
4. In Defender portal, confirm `PTC_01` appears in Assets → Devices with status: Onboarded

---

## Best Practices

- Enable the Defender–Intune connector before deploying the compliance policy — the connector must be active for risk signals to reach Intune
- Always add Machine Risk Score to the compliance policy in production — this activates the behavioural trust layer
- Set risk level to **Low** — Medium allows moderately compromised devices to retain access
- Review Defender device inventory weekly for any devices with elevated or High risk scores

---

## Security Notes

Without the Machine Risk Score in the compliance policy, Defender for Endpoint provides **visibility without enforcement**. The device is monitored and alerts are generated, but a compromised device that still has BitLocker and Antivirus enabled would still appear compliant. Adding the risk score closes this gap.

---

## Common Mistakes

| Mistake | Consequence | Prevention |
|---|---|---|
| Enabling connector in Intune only (not Defender portal) | Sync fails; devices not onboarded | Enable in both portals |
| Skipping Machine Risk Score in compliance policy | Defender sends data but compliance is not risk-aware | Add risk score setting to compliance policy |
| Not verifying device onboarding | Device appears in Intune but not in Defender | Check Assets → Devices in Defender portal |
| Setting risk threshold to Medium or High | Moderately or highly compromised devices retain access | Always use Low as the minimum acceptable risk |
