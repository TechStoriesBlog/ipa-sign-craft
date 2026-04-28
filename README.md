![Latest Release](https://img.shields.io/github/v/release/CodeWorldBlog/ipasigncraft)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/github/license/CodeWorldBlog/ipasigncraft)

# IPASignCraft

A lightweight macOS utility to re-sign IPA files with clarity, safety, and control.

---

## 🖼️ Preview

### Home Screen
![Home Screen](docs/screens/home.png)

### IPA Selection
![IPA Selection](docs/screens/ipa-selection.png)

### Certificate & Provisioning
![Signing Setup](docs/screens/signing.png)

### Result
![Result Screen](docs/screens/result.png)

---

## ✨ Features

* Simple IPA loading
* Certificate (.p12) support
* Provisioning profile integration
* Secure temporary keychain signing
* Clean re-signing workflow
* Export ready-to-install IPA

---

## ⚙️ Secure Re-Signing Workflow

```mermaid
flowchart TD

    A[Load IPA File] --> B[Extract Payload Workspace]
    B --> C[Apply Bundle / Plist Modifications]
    C --> D[Create Temporary Signing Keychain]

    D --> E[Import P12 Certificate Securely]
    E --> F[Resolve Signing Identity SHA1]
    F --> G[Embed Provisioning Profile]
    G --> H[Generate Updated Entitlements]

    H --> I[Remove Existing Signatures]
    I --> J[Sign Frameworks / Dylibs / Extensions]
    J --> K[Sign Main Application Bundle]

    K --> L[Verify Signed Bundle]
    L --> M[Repackage Payload to IPA]

    M --> N[Restore Original Keychain Session]
    N --> O[Delete Temporary Signing Keychain]
    O --> P[Export Resigned IPA]
```

---

## ⬇️ Download

👉 **[Download Latest Version](https://github.com/CodeWorldBlog/ipasigncraft/releases/latest)**

---

## ⚡ Quick Start

1. Open IPASignCraft
2. Load your IPA
3. Select certificate and provisioning profile
4. Apply desired signing options
5. Click **Re-sign**
6. Export the newly signed IPA

---

## 🧰 Requirements

* macOS 12+
* Apple Developer Certificate (.p12)
* Provisioning Profile (.mobileprovision)

---

## 🔒 Security Approach

IPASignCraft uses an isolated temporary signing keychain during the re-sign process.

This means:

* No permanent certificate import into Login Keychain
* No System Keychain modification
* No persistent signing identity left on macOS
* Temporary signing artifacts are removed automatically after completion

Designed to keep the host machine clean while maintaining a stable Apple signing workflow.

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

## 📜 License

MIT License

---

## 🤝 Contributing

Open to improvements, ideas, and refinements.

---

## 🔍 Notes

* Designed for development and internal testing workflows
* Follows Apple code-signing mechanisms
* Does not bypass Apple platform security restrictions