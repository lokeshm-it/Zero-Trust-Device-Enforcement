# 2.3 — Disk Encryption Policy: BitLocker via Intune Endpoint Security

## Business Purpose
While the compliance policy *requires* BitLocker, it does not *configure* it. A device can fail BitLocker compliance simply because it was never encrypted. The Disk Encryption Endpoint Security policy establishes Intune as the **BitLocker management authority** — it configures, enforces, and monitors BitLocker settings, and ensures recovery keys are automatically escrowed to Entra ID.

This is the difference between checking for a lock and actually installing one.

---

## Policy Configuration

**Policy name:** `Disk encryption`
**Platform:** Windows 10 and later
**Profile type:** BitLocker (Endpoint Security → Disk Encryption)
**Assigned to:** All devices

### BitLocker Settings

| Category | Setting | Value |
|---|---|---|
| BitLocker | Require Device Encryption | **Enabled** |
| BitLocker | Configure Recovery Password Rotation | **Refresh on — Entra ID-joined devices** |
| OS Drives | Encryption method | **XTS-AES 128-bit** |
| Fixed Data Drives | Encryption method | **XTS-AES 128-bit** (default) |
| Removable Drives | Encryption method | **AES-CBC 128-bit** (default) |

> Export evidence: [`exports/Disk-Encryption-Policy.pdf`](exports/Disk-Encryption-Policy.pdf)

---

## Encryption Algorithm Selection

| Drive Type | Algorithm | Reason |
|---|---|---|
| OS drive | XTS-AES 128 | XTS mode provides superior integrity protection for fixed drives; not susceptible to manipulation of encrypted data |
| Fixed data drives | XTS-AES 128 | Same protection for secondary internal drives |
| Removable drives | AES-CBC 128 | CBC mode used for removable drives for cross-platform compatibility (XTS is not supported on older systems) |

---

## Recovery Key Escrow

The recovery password rotation setting `Refresh on — Entra ID-joined devices` means:
1. When BitLocker activates on an Entra ID-joined device, the recovery key is automatically uploaded to Entra ID
2. If the recovery key is used (e.g., to recover a locked device), a new key is generated and escrowed
3. Administrators can retrieve the key via: `Entra ID → Devices → [device name] → BitLocker keys`

This eliminates the risk of recovery keys being lost, stored insecurely, or never backed up.

---

## Implementation Steps

**Navigation:** `Intune → Endpoint security → Disk encryption → Create policy`

1. Select platform: **Windows 10 and later**
2. Select profile: **BitLocker**
3. Configure settings:
   - Require Device Encryption: **Enabled**
   - Recovery Password Rotation: **Refresh on Entra ID-joined devices**
   - Enable encryption method for drives
   - OS drives: XTS-AES 128-bit
   - Fixed drives: XTS-AES 128-bit
   - Removable drives: AES-CBC 128-bit
4. Assignments: All devices
5. Review and Create

---

## VM-Specific Considerations

In this lab, `PTC_01` is a Windows VM. Standard TPM-required BitLocker settings fail on VMs without a virtual TPM. The following settings were set to **Not configured** to allow BitLocker to function in a VM environment using software protection:

- Require TPM: Not configured
- Require Secure Boot: Not configured

This is a lab-specific accommodation. In production, TPM 2.0 should always be required.

---

## Validation

### Confirm BitLocker Active on Device

Open PowerShell as Administrator on the device:
```powershell
manage-bde -status
```

Expected output:
```
Volume C: [OS Volume]
Conversion Status: Fully Encrypted
Encryption Method: XTS-AES 128
Lock Status: Unlocked
Protection Status: Protection On
```

### Confirm Recovery Key in Entra ID

`Entra ID admin center → Devices → All devices → PTC_01 → BitLocker keys`

A recovery key ID and key value should be visible.

### Backup Recovery Key Manually (if missing)

```powershell
$KeyId = (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
    Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } |
    Select-Object -ExpandProperty KeyProtectorId

BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $KeyId
```

---

## Best Practices

- Always use Intune Endpoint Security Disk Encryption rather than compliance-only BitLocker — Endpoint Security establishes management authority and handles key escrow
- Set recovery password rotation for Entra ID-joined devices — ensures keys are always current and available
- Verify recovery keys in Entra ID before enforcing the compliance policy — if keys are missing, users cannot self-recover
- Use XTS-AES 128 minimum for OS and fixed drives in all production deployments

---

## Security Notes

**Why XTS-AES 128 and not AES-CBC?**
XTS (XEX-based tweaked-codebook mode with ciphertext stealing) provides integrity protection that AES-CBC does not. With CBC mode, an attacker who can modify ciphertext sectors may be able to manipulate data without detection. XTS binds encryption to specific sector positions, making such attacks impractical on fixed drives.

**Why is AES-CBC still used for removable drives?**
XTS-AES is not supported by BitLocker on operating systems older than Windows 10. Removable drives may be accessed by older systems, so AES-CBC 128 maintains compatibility while still providing encryption.

---

## Common Mistakes

| Mistake | Consequence | Prevention |
|---|---|---|
| Using compliance policy only (no Endpoint Security policy) | BitLocker required but never configured or escrowed | Deploy Disk Encryption via Endpoint Security |
| Requiring TPM on VMs without virtual TPM | BitLocker cannot activate; device stays noncompliant | Set TPM to Not configured in VM environments |
| Not verifying key escrow | Recovery key missing; locked device cannot be recovered | Always verify key in Entra ID after BitLocker activates |
| Setting encryption to optional | Some devices skip encryption | Set Require Device Encryption to Enabled |
