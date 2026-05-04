![Latest Release](https://img.shields.io/github/v/release/CodeWorldBlog/ipasigncraft)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![License](https://img.shields.io/github/license/CodeWorldBlog/ipasigncraft)

<p align="center">
  <img src="docs/screens/icon.png" width="120" alt="IPASignCraft Icon">
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
    %% Phase 1: Preparation
    subgraph Preparation ["<b>1. PREPARATION PHASE</b>"]
        direction LR
        A("📦 <b>Load</b><br/>IPA Archive") 
        B("📂 <b>Extract</b><br/>Workspace") 
        C("🛠 <b>Modify</b><br/>Bundle")
        A --> B --> C
    end

    %% Phase 2: Signing
    subgraph Signing ["<b>2. SIGNING PHASE</b>"]
        direction LR
        D("🔐 <b>Create Temporary Keychain</b><br/>Setup") 
        E("📜 <b>Cert</b><br/>Import") 
        F("📎 <b>Profile</b><br/>Embed") 
        G("⚙️ <b>Entitlements</b><br/>Gen")
        D --> E --> F --> G
    end

    %% Phase 3: Finalization
    subgraph Finalization ["<b>3. FINALIZATION PHASE</b>"]
        direction LR
        H("🧹 <b>Clean</b><br/>Signatures") 
        I("✍️ <b>Sign</b><br/>Bundles") 
        J("✅ <b>Verify</b><br/>Integrity") 
        K("📦 <b>Pack</b><br/>Payload") 
        L("🚀 <b>Export</b><br/>IPA")
        H --> I --> J --> K --> L
    end

    %% Phase Transitions
    Preparation ==> Signing
    Signing ==> Finalization

    %% Styling Logic
    classDef prep fill:#E3F2FD,stroke:#2196F3,stroke-width:2px,color:#0D47A1;
    classDef sign fill:#F1F8E9,stroke:#689F38,stroke-width:2px,color:#1B5E20;
    classDef final fill:#FFF3E0,stroke:#EF6C00,stroke-width:2px,color:#E65100;
    
    %% Style Subgraphs
    style Preparation fill:#F8FDFF,stroke:#2196F3,stroke-width:3px,stroke-dasharray: 5 5
    style Signing fill:#FBFFF9,stroke:#689F38,stroke-width:3px,stroke-dasharray: 5 5
    style Finalization fill:#FFFAF2,stroke:#EF6C00,stroke-width:3px,stroke-dasharray: 5 5

    class A,B,C prep;
    class D,E,F,G sign;
    class H,I,J,K,L final;
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