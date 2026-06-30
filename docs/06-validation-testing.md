# 2.6 — Validation and Testing Procedures

## Validation Framework
All policies were validated using the same Report-only → Validate → Enforce methodology as Project 1. The compliance cycle was verified end-to-end: device enrolled → policy applied → non-compliant (expected) → remediated → compliant → CA enforced.

---

## Test Case 1: Device Enrolment

| Field | Detail |
|---|---|
| Test | Entra ID Join PTC_01 and verify Intune enrolment |
| Device | PTC_01 (WillStone@Patchthecloud.onmicrosoft.com) |
| Expected | Device appears in Intune → Managed by Intune |
| Verification | Intune → Devices → Windows → Windows devices |
| Result | PTC_01 visible, Managed by: Intune, Ownership: Personal |

> Evidence: `images/A1-device-enrolled/01-device-enrolled-intune.png`

---

## Test Case 2: Compliance Policy — Noncompliant State

| Field | Detail |
|---|---|
| Test | Apply compliance policy; verify device correctly identified as non-compliant |
| Expected | PTC_01 status: Noncompliant |
| Reason | BitLocker not enabled at time of policy application |
| Verification | Endpoint security → All devices → PTC_01 → Noncompliant |
| Result | Status: Noncompliant — compliance engine working correctly |

> Evidence: `images/A3-compliance-status/03-noncompliant-bitlocker-missing.png`

---

## Test Case 3: BitLocker Remediation → Compliant

| Field | Detail |
|---|---|
| Test | Enable BitLocker on PTC_01; verify compliance state changes |
| Action | Disk Encryption policy applied; BitLocker activated via Intune |
| Expected | PTC_01 status: Compliant |
| Verification | Intune → Devices → Windows → PTC_01 → Compliance: Compliant |
| Recovery key | Confirmed visible in Entra ID → Devices → PTC_01 → BitLocker keys |
| Result | Device compliant after BitLocker confirmed active and key escrowed |

> Evidence: `images/A1-device-enrolled/01-device-enrolled-compliant.png`

---

## Test Case 4: MDM Auto-Enrolment Scope

| Field | Detail |
|---|---|
| Test | Confirm MDM scope set to All |
| Navigation | Intune → Devices → Enrol devices → Automatic enrollment |
| Expected | MDM user scope: All |
| Result | Confirmed — all Entra ID joined devices automatically enrolled |

> Evidence: `images/A2-auto-enrollment/02-mdm-auto-enrollment-scope-all.png`

---

## Test Case 5: Defender for Endpoint Connector

| Field | Detail |
|---|---|
| Test | Verify Defender–Intune integration is active |
| Navigation | Intune → Endpoint security → Microsoft Defender for Endpoint |
| Expected | Connection status: Enabled |
| Result | Enabled — Last sync: 10/01/2026 21:34:59 |

> Evidence: `images/A5-defender-connection/05-defender-connector-active.png`

---

## Test Case 6: CA-DEV-01 Report-Only

| Field | Detail |
|---|---|
| Test | Validate CA-DEV-01 in Report-only before enforcement |
| Policy | CA-DEV-01 – Require Compliant Device |
| Expected | Policy visible in CA policies list with state: Report-only |
| Result | Confirmed — 6 CA policies active; CA-DEV-01 in Report-only |

> Evidence: `images/A4-ca-report-only/04-ca-dev-01-report-only.png`

---

## Test Case 7: CA-DEV-01 Enforced

| Field | Detail |
|---|---|
| Test | Enforce CA-DEV-01; verify state change to On |
| Policy | CA-DEV-01 – Require Compliant Device |
| Expected | Policy state: On |
| Result | Confirmed — CA-DEV-01 enforced |

> Evidence: `images/A6-ca-enforced/06-ca-dev-01-enforced.png`

---

## Monitoring Checklist (Ongoing)

After enforcement, monitor weekly:

| Signal | Location | What to Check |
|---|---|---|
| Device compliance | Intune → Reports → Device compliance | Any new noncompliant devices |
| BitLocker status | Intune → Reports → Encryption report | Devices without encryption |
| Defender risk | security.microsoft.com → Devices | Any device with Medium or High risk |
| CA block events | Entra ID → Sign-in logs → Filter: Failure | CA-DEV-01 block reason = device not compliant |
| OS version drift | Intune → Reports → OS version report | Devices below minimum OS build |
