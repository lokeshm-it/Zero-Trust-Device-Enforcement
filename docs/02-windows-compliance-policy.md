# 2.2 — Windows Compliance Policy: CP-WIN-01 Zero Trust Baseline

## Business Purpose
A compliance policy defines the minimum security baseline a device must meet before it is permitted to access corporate resources. Without a compliance policy, Intune-managed devices default to "Compliant" — meaning the Conditional Access device requirement has no real enforcement. This policy answers the question: **what does a trustworthy device look like?**

---

## Policy Configuration

**Policy name:** `Windows Compliance Policy`
**Platform:** Windows 10 and later
**Profile type:** Windows 10/11 compliance policy
**Assigned to:** All devices

### Compliance Settings

| Category | Setting | Value | Business Rationale |
|---|---|---|---|
| Device Health | BitLocker | **Require** | Encrypts data at rest; non-negotiable for Zero Trust device trust |
| Device Properties | Minimum OS version | **22631.6199** | Enforces Windows 11 23H2 — ensures devices are on a supported, patched build |
| System Security | Antivirus | **Require** | Active threat protection must be running at all times |

### Actions for Non-compliance

| Action | Schedule |
|---|---|
| Mark device noncompliant | **Immediately** |

No grace period. A device that fails any compliance setting is immediately marked non-compliant and loses access via CA-DEV-01.

### Assignment

| Group | Status | Filter |
|---|---|---|
| All devices | Active | None |

---

## Implementation Steps

**Navigation:** `Intune → Devices → Compliance policies → Create policy`

1. Select platform: **Windows 10 and later**
2. Enter name: `Windows Compliance Policy`
3. Configure Device Health:
   - BitLocker: **Require**
4. Configure Device Properties:
   - Minimum OS version: `22631.6199`
5. Configure System Security:
   - Antivirus: **Require**
6. Configure Actions for noncompliance:
   - Action: Mark device noncompliant
   - Schedule: Immediately
7. Assignments → Include: **All devices**
8. Review and Create

---

## Compliance Evaluation Cycle

After assignment, Intune evaluates each device against the policy at the next check-in. Initial result for `PTC_01`:

**Status: Noncompliant**
- BitLocker was not enabled on the device at the time of policy assignment
- Device check-in: 10/01/2026 15:46

> Screenshot evidence: `images/A3-compliance-status/03-noncompliant-bitlocker-missing.png`

This is the correct and expected behaviour. The policy is working — it correctly identified a security gap on the endpoint.

After BitLocker was enabled and the recovery key escrowed to Entra ID:

**Status: Compliant**
- Device check-in: 10/01/2026 15:08 (subsequent check-in showing compliant)

> Screenshot evidence: `images/A1-device-enrolled/01-device-enrolled-compliant.png`

---

## Validation

1. Navigate to: `Intune → Devices → Compliance policies → Windows Compliance Policy → Device status`
2. Confirm PTC_01 shows:
   - Compliance state: Compliant
   - Last report time: within last 24 hours
3. Cross-check in: `Endpoint security → All devices`
4. Confirm Conditional Access evaluates device compliance on next sign-in

---

## Best Practices

- Always include BitLocker as a required setting for any Windows compliance policy — it is the single most important data-at-rest control
- Set non-compliance action to Immediately — grace periods create windows where non-compliant devices retain access
- Set minimum OS version to enforce patching — old OS builds cannot receive security updates
- Assign to All devices rather than user groups — device compliance should follow the device, not the user
- Review compliance policy settings quarterly against Microsoft's current baseline recommendations

---

## Security Notes

**Why "Immediately" for non-compliance action?**
Any grace period (e.g., 1 day, 3 days) creates a window where a compromised or misconfigured device retains corporate access. Zero Trust design requires that the moment a device falls out of compliance, access is revoked. Admins are then alerted to remediate.

**What happens to a non-compliant device?**
1. Intune marks the device non-compliant
2. Conditional Access evaluates the compliance signal at next sign-in
3. CA-DEV-01 blocks access because `device is compliant` requirement is not met
4. User receives a block page with a reason code
5. Admin must remediate the device for access to be restored

---

## Common Mistakes

| Mistake | Consequence | Prevention |
|---|---|---|
| Not assigning the policy to any group | Policy exists but never evaluates any device | Always assign to All devices or a scoped group |
| Setting non-compliance grace period to 7+ days | Non-compliant devices retain access for a week | Set to Immediately |
| Not including BitLocker | Device can pass compliance without encryption | Always require BitLocker |
| Using user group assignment instead of device group | Users with multiple devices may have inconsistent compliance | Assign to device groups |
