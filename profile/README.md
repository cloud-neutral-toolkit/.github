<div align="center">

# ☁️ Cloud-Neutral Toolkit

**Build, Authenticate, Deploy — Anywhere.**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Go Report Card](https://goreportcard.com/badge/github.com/cloud-neutral-toolkit/rag-server.svc.plus)](https://goreportcard.com/report/github.com/cloud-neutral-toolkit/rag-server.svc.plus)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[English](#-english) | [中文文档](#-中文文档)

---

</div>

<a name="-english"></a>

## 🌐 English

**Cloud-Neutral Toolkit** is a **cloud-native**, **vendor-agnostic**, and **portable** AI infrastructure & DevOps platform. We provide a comprehensive toolset to help developers achieve automation, observability, and intelligent operations in multi-cloud environments.

Our core vision is to liberate your applications and data from specific cloud platforms, making them truly **Cloud-Agnostic**.

### ⚡ Core Capabilities

Streamline your development and deployment pipeline with our key services:

| Feature Module | Description | Action |
| :--- | :--- | :--- |
| **🔐 Authentication** | Secure, flexible identity verification supporting multiple login methods. | [Register App](https://console.svc.plus/) |
| **🛡️ Authorization** | Granular permission control and access management (RBAC/ABAC). | [Learn More](https://docs.svc.plus/auth) |
| **🤖 Machine-to-Machine** | Dedicated security mechanisms for service-to-service (M2M) communication. | [M2M Guide](https://docs.svc.plus/m2m) |
| **🔌 REST & Admin APIs** | Robust programmatic interfaces for deep system integration. | [API Docs](https://docs.svc.plus/api) |
| **💻 CLI Connect** | Manage your environment instantly via terminal. | [Get CLI](https://docs.svc.plus/cli) |

### 📦 Ecosystem Components

| Repository | Lang | Role | Quick Access |
| :--- | :--- | :--- | :--- |
| **console.svc.plus** | `TS` | **Frontend Console**: Manage apps, users, and configs with a sleek UI. | [Visit Console](https://console.svc.plus/) |
| **rag-server.svc.plus** | `Go` | **RAG Backend**: Retrieval-Augmented Generation service for AI knowledge. | [Source](https://github.com/cloud-neutral-toolkit/rag-server.svc.plus) |
| **accounts.svc.plus** | `Go` | **Identity Core**: Handles registration, login, and session management. | [Source](https://github.com/cloud-neutral-toolkit/accounts.svc.plus) |
| **agent.svc.plus** | `N/A` | **Smart Agent**: Core logic for multi-cloud automation (Private Beta). | [Request Access](mailto:contact@svc.plus) |

### 🚀 Quick Start

Ready to break free from vendor lock-in?

1.  **Create App**: Start your journey at the [Console](https://console.svc.plus/).
2.  **Read Docs**: Full integration guides available at [docs.svc.plus](https://docs.svc.plus/).
3.  **Connect**:

```bash
# Install the CLI and login
cn login

# Initialize your first cloud-neutral app
cn app create my-first-app
