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
  <img src="docs/screens/ipa-selection.png" width="90%" alt="IPA Selection">
</p>

---

### Certificate & Provisioning Setup

<p align="center">
  <img src="docs/screens/signing.png" width="90%" alt="Signing Setup">
</p>

---

### Final Signing Result

<p align="center">
  <img src="docs/screens/result.png" width="90%" alt="Result">
</p>

---

## ⚙️ Signing Pipeline

```mermaid
flowchart LR

    subgraph Preparation
        A[Load IPA] --> B[Extract Workspace] --> C[Apply Bundle Modifications]
    end

    subgraph Signing
        D[Create Temporary Keychain] --> E[Import Signing Certificate] --> F[Embed Provisioning Profile] --> G[Generate Entitlements]
    end

    subgraph Finalization
        H[Remove Existing Signatures] --> I[Sign Frameworks & App Bundle] --> J[Verify Signature] --> K[Repackage Payload] --> L[Export Resigned IPA]
    end

    C --> D
    G --> H
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