# Architecture Diagrams — Zero Trust Device Trust Enforcement

---

## Diagram 1: Device Trust Enforcement — High-Level Flow

```mermaid
flowchart TD
    A[User Sign-in Attempt] --> B{Entra ID\nConditional Access}
    B --> C{CA-DEV-01\nRequire Compliant Device?}
    C -->|Device Compliant| D[Access Granted]
    C -->|Device Not Compliant| E[Access Blocked]
    C -->|Device Not Enrolled| E

    subgraph Intune["Microsoft Intune — Device Management"]
        F[Entra ID Join\nAuto-Enrollment] --> G[CP-WIN-01\nCompliance Policy Applied]
        G --> H{Evaluation}
        H -->|BitLocker ✓ AV ✓ OS ✓| I[Compliant]
        H -->|Any check fails| J[Noncompliant]
        J --> K[Non-compliance Action\nMark noncompliant immediately]
        K --> L[User receives portal notification]
        L --> M[Self-remediation / IT support]
        M --> G
    end

    subgraph Encryption["Disk Encryption — Endpoint Security"]
        N[BitLocker Policy Applied\nXTS-AES 128] --> O[Recovery Key → Entra ID]
        O --> I
    end

    subgraph Defender["Microsoft Defender for Endpoint"]
        P[MDE Connector: Enabled] --> Q[Device Risk Signal]
        Q --> B
    end

    I --> C
```

---

## Diagram 2: Compliance Evaluation Logic

```mermaid
flowchart LR
    A[Device Check-In\nto Intune] --> B[Apply CP-WIN-01]

    B --> C{BitLocker\nEnabled?}
    C -->|No| FAIL
    C -->|Yes| D

    D{OS Version\n≥ 22631.6199?}
    D -->|No| FAIL
    D -->|Yes| E

    E{Antivirus\nRegistered?}
    E -->|No| FAIL
    E -->|Yes| F

    F[Compliance State:\nCOMPLIANT]
    FAIL[Compliance State:\nNONCOMPLIANT]

    F --> G[CA-DEV-01 satisfied\nAccess granted]
    FAIL --> H[CA-DEV-01 blocks access]
    FAIL --> I[Non-compliance action:\nMark immediately]
```

---

## Diagram 3: Entra ID Join and MDM Auto-Enrolment Sequence

```mermaid
sequenceDiagram
    participant U as User / Device
    participant W as Windows 11 (PTC_01)
    participant E as Microsoft Entra ID
    participant I as Microsoft Intune
    participant C as Conditional Access

    U->>W: Sign in with WillStone@Patchthecloud
    W->>E: Entra ID Join request
    E-->>W: Joined — device registered
    W->>I: MDM auto-enrollment (scope: All)
    I-->>W: Enrollment token issued
    W->>I: Device check-in
    I->>W: Push CP-WIN-01 compliance policy
    I->>W: Push BitLocker disk encryption policy
    W->>W: BitLocker activated (XTS-AES 128)
    W->>E: Escrow recovery key to Entra ID
    W->>I: Check-in — compliance evaluation
    I-->>E: Compliance state = Compliant
    U->>C: Attempt to access Microsoft 365
    C->>E: Check device compliance signal
    E-->>C: Device is compliant
    C-->>U: Access granted
```

---

## Diagram 4: Zero Trust Pillars — Device Layer Context

```mermaid
mindmap
    root((Zero Trust\nPatchthecloud))
        Identity
            CA01 Require MFA
            CA02 Block Legacy Auth
            CA03 Require Phishing-Resistant MFA for Admins
            CA04 PIM Just-In-Time
        Devices
            Entra ID Join
            MDM Auto-Enrollment
            CP-WIN-01 Compliance Policy
                BitLocker Required
                Min OS 22631.6199
                Antivirus Required
            BitLocker XTS-AES 128
                Recovery Key → Entra ID
            CA-DEV-01 Require Compliant Device
            Defender for Endpoint Connector
        Network
            Planned
        Applications
            Planned
        Data
            Planned
```

---

## Diagram 5: Deployment Timeline

```mermaid
gantt
    title Project 2 — Zero Trust Device Trust Enforcement
    dateFormat  YYYY-MM-DD
    section Enrolment
        Entra ID Join PTC_01         :done, e1, 2026-01-05, 1d
        MDM Auto-Enrollment (All)    :done, e2, 2026-01-05, 1d
    section Compliance
        Create CP-WIN-01             :done, c1, 2026-01-06, 1d
        Assign to All Devices        :done, c2, 2026-01-06, 1d
        Verify noncompliant state    :done, c3, 2026-01-07, 1d
    section Encryption
        Deploy BitLocker policy      :done, enc1, 2026-01-07, 1d
        Recovery key escrow confirmed :done, enc2, 2026-01-08, 1d
        Device reaches Compliant     :done, enc3, 2026-01-08, 1d
    section Defender
        Enable MDE-Intune connector  :done, mde1, 2026-01-09, 1d
        Confirm Connection: Enabled  :done, mde2, 2026-01-09, 1d
    section CA Enforcement
        CA-DEV-01 Report-only        :done, ca1, 2026-01-09, 2d
        Validate CA signal           :done, ca2, 2026-01-10, 1d
        CA-DEV-01 Enforced           :done, ca3, 2026-01-10, 1d
```
