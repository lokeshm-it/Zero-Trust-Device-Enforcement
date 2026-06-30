# 2.5 — Conditional Access: CA-DEV-01 Require Compliant Device

## Business Purpose
Compliance policies and Defender signals define what a trustworthy device looks like. Conditional Access is the **enforcement mechanism** that acts on those signals at access time. Without CA-DEV-01, a user can sign in from a non-compliant device — the compliance policy marks it as non-compliant in Intune, but nothing stops them from accessing Microsoft 365.

CA-DEV-01 closes that gap: if the device is not compliant, access to all Microsoft 365 resources is denied — regardless of identity.

---

## Policy Configuration

**Policy name:** `CA-DEV-01 – Require Compliant Device`

| Setting | Value |
|---|---|
| Users: Include | All users |
| Users: Exclude | Break-glass account |
| Target resources | All cloud apps (All resources) |
| Grant control | Require device to be marked as compliant |
| Operator | OR (with MFA from CA01 — both conditions apply) |
| State | Report-only → validate → **On** |

---

## Relationship to CA01 (Identity Layer)

CA-DEV-01 is the **Devices pillar** counterpart to CA01 (Identity pillar). Both policies are active and both must be satisfied for access:

| Layer | Policy | Requirement |
|---|---|---|
| Identity | CA01 — Baseline MFA | User must authenticate with MFA |
| Device | CA-DEV-01 — Require Compliant Device | Device must be Intune-managed and compliant |

A user on a compliant device who fails MFA is blocked by CA01.
A user who completes MFA from a non-compliant device is blocked by CA-DEV-01.
Both must pass for access to be granted.

---

## Implementation Steps

**Navigation:** `Entra ID → Conditional Access → Policies → + New policy`

1. Name: `CA-DEV-01 – Require Compliant Device`
2. Users:
   - Include: All users
   - Exclude: Break-glass account
3. Target resources:
   - Include: All cloud apps
4. Grant:
   - Select: **Require device to be marked as compliant**
5. Enable policy: **Report-only**
6. Create

---

## Report-Only Validation

After creating in Report-only, sign in from `PTC_01` as `WillStone@Patchthecloud.onmicrosoft.com`.

**Navigate to sign-in logs:** `Entra ID → Monitoring → Sign-in logs → [sign-in event] → Conditional Access tab`

Expected result:
| Policy | Result |
|---|---|
| CA-DEV-01 – Require Compliant Device | Report-only: Would have applied |

Check:
- Device shown in sign-in log: PTC_01
- Compliance state visible: Compliant

> Screenshot evidence: `images/A4-ca-report-only/04-ca-dev-01-report-only.png`

---

## Enforcement

Once report-only validation confirms correct behaviour:

1. Open CA-DEV-01
2. Change `Enable policy` from `Report-only` to **On**
3. Save

> Screenshot evidence: `images/A6-ca-enforced/06-ca-dev-01-enforced.png`

---

## What Happens When a Non-Compliant Device Attempts Access

1. User signs in with valid credentials and completes MFA (CA01 satisfied)
2. Conditional Access evaluates CA-DEV-01
3. Device compliance state: Non-compliant
4. CA-DEV-01 blocks the request
5. Sign-in log shows:
   - Failure reason: Device is not compliant
   - CA-DEV-01: Failure — Grant control not satisfied

---

## Best Practices

- Always deploy CA-DEV-01 in Report-only first — a non-compliant device policy enforced without testing can block admins and legitimate users
- Verify the break-glass account exclusion before enforcement
- Combine with CA01 (MFA) — device compliance alone without identity verification is not sufficient
- Monitor sign-in logs for CA-DEV-01 failure reasons weekly after enforcement
- Consider adding a separate policy for unmanaged devices with limited session controls rather than a hard block (e.g., read-only access from browser)

---

## Common Mistakes

| Mistake | Consequence | Prevention |
|---|---|---|
| Not testing in Report-only | Legitimate compliant devices blocked unexpectedly | Always validate first |
| Forgetting break-glass exclusion | Emergency access locked out | Exclude break-glass from all CA policies |
| Using OR instead of AND for MFA + compliant | User can satisfy one condition and bypass the other | Review CA grant logic carefully |
| Applying before compliance policy is deployed | All devices immediately blocked | Deploy compliance policy first, wait for devices to report |
