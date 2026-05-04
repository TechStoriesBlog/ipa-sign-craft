![Latest Release](https://img.shields.io/github/v/release/CodeWorldBlog/ipasigncraft)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/github/license/CodeWorldBlog/ipasigncraft)

<p align="center">
  <img src="docs/icon.png" width="120" alt="IPASignCraft Icon">
</p>

<h1 align="center">IPASignCraft</h1>

<p align="center">
A lightweight macOS utility to re-sign IPA files with clarity, safety, and control.
</p>

<p align="center">
  <a href="https://github.com/CodeWorldBlog/ipasigncraft/releases/latest"><b>⬇ Download Latest Release</b></a>
</p>

---

## 🖼️ Application Preview

<p align="center">
  <img src="docs/screens/home.jpg" width="95%" alt="IPASignCraft Home Screen">
</p>

<p align="center"><i>Main workspace of IPASignCraft</i></p>

---

## ✨ Core Features

- Clean drag-and-drop IPA loading
- Apple certificate (.p12) signing support
- Provisioning profile embedding
- Temporary isolated keychain signing
- Bundle identifier and metadata modification
- Secure export of ready-to-install IPA
- Real-time signing progress logs

---

## 🧩 Detailed Screens

### IPA Selection Workflow

<p align="center">
  <img src="docs/screens/ipa-selection.jpg" width="90%" alt="IPA Selection">
</p>

---

### Certificate & Provisioning Setup

<p align="center">
  <img src="docs/screens/signing.jpg" width="90%" alt="Signing Setup">
</p>

---

### Final Signing Result

<p align="center">
  <img src="docs/screens/result.jpg" width="90%" alt="Result">
</p>

---

## ⚙️ Signing Pipeline

```mermaid
flowchart TB

    subgraph Preparation["Preparation Phase"]
        direction LR
        A[📦 Load IPA Archive] --> B[📂 Extract Payload Workspace] --> C[🛠 Apply Bundle Modifications]
    end

    subgraph Signing["Signing Phase"]
        direction LR
        D[🔐 Create Temporary Keychain] --> E[📜 Import Signing Certificate] --> F[📎 Embed Provisioning Profile] --> G[⚙️ Generate Entitlements]
    end

    subgraph Finalization["Finalization Phase"]
        direction LR
        H[🧹 Remove Existing Signatures] --> I[✍️ Sign Frameworks & App Bundle] --> J[✅ Verify Signature Integrity] --> K[📦 Repackage Payload] --> L[🚀 Export Resigned IPA]
    end

    C --> MID1(( ))
    MID1 --> D

    G --> MID2(( ))
    MID2 --> H

    classDef prep fill:#eef7ff,stroke:#4a90e2,stroke-width:1.5px;
    classDef sign fill:#f4f9ee,stroke:#7cb342,stroke-width:1.5px;
    classDef final fill:#fff6ea,stroke:#fb8c00,stroke-width:1.5px;
    classDef mid fill:none,stroke:none;

    class A,B,C prep;
    class D,E,F,G sign;
    class H,I,J,K,L final;
    class MID1,MID2 mid;
```

---

## ⚡ Quick Start

1. Launch IPASignCraft
2. Load target IPA file
3. Select provisioning profile
4. Choose signing certificate (.p12 or keychain)
5. Configure optional bundle modifications
6. Start secure re-sign process
7. Export signed IPA

---

## 🧰 Requirements

- macOS 12.0+
- Apple Developer Certificate (.p12) or local keychain certificate
- Valid Provisioning Profile (.mobileprovision)

---

## 🔒 Security Philosophy

IPASignCraft performs the signing process inside an isolated temporary macOS keychain session.

This ensures:

- No permanent certificate import into Login Keychain
- No modification of System Keychain
- No long-lived signing identity left on the machine
- Temporary signing artifacts are removed automatically after completion

A cleaner and safer workflow for Apple code-signing operations.

---

## 📁 Project Structure

```text
IPASignCraft/
 ├── App/
 ├── Core/
 ├── Features/
 ├── Resources/
 └── docs/
```

---

## ⬇️ Download

**[Download Latest Version](https://github.com/CodeWorldBlog/ipasigncraft/releases/latest)**

---

## 📜 License

MIT License

---

## 🤝 Contributing

Ideas, refinements, and pull requests are welcome.

---

## 🔍 Notes

- Built for development and internal testing workflows
- Uses Apple's standard code-signing mechanisms
- Does not bypass Apple platform security enforcement