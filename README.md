<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0ea5e9,100:6366f1&height=200&section=header&text=Personal%20Loan%20Monorepo&fontSize=48&fontColor=ffffff&animation=fadeIn&fontAlignY=38&desc=Quotation%20app%20starter%20%E2%80%A2%20Flutter%20%2B%20NestJS%20%2B%20PostgreSQL&descAlignY=60&descSize=18" alt="Personal Loan Monorepo banner" />

<a href="https://git.io/typing-svg">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1000&color=6366F1&center=true&vCenter=true&width=620&lines=%F0%9F%92%B8+Personal+loan+quotations%2C+made+simple;%F0%9F%93%B1+Flutter+consumer+app;%F0%9F%9B%A0%EF%B8%8F+NestJS+modular+monolith+API;%F0%9F%90%98+PostgreSQL+%2B+Prisma;%F0%9F%90%B3+One+command+to+spin+up+the+database" alt="Typing animation" />
</a>

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NestJS](https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Swagger](https://img.shields.io/badge/Swagger-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

</div>

---

> [!WARNING]
> 🚧 **This is a starter, not a production system.** It is **not ready** to handle real customer or financial data. See [Before going to production](#-before-going-to-production) for what's still missing.

## 📖 Table of Contents

- [✨ What is this?](#-what-is-this)
- [🏗️ Architecture](#️-architecture)
- [🧰 Tech Stack](#-tech-stack)
- [📂 Project Structure](#-project-structure)
- [🚀 Quick Start](#-quick-start)
- [⚙️ Configuration](#️-configuration)
- [🧪 Scripts & Commands](#-scripts--commands)
- [🔌 API Overview](#-api-overview)
- [🛡️ Before going to production](#️-before-going-to-production)
- [🗺️ Roadmap](#️-roadmap)

---

## ✨ What is this?

A monorepo starter for a **personal-loan quotation app** 💸. A customer fills in a loan request on a mobile app, and the backend stores it as a **draft quotation** that can be updated, submitted or cancelled.

| 📱 Consumer app | 🛠️ Backend API | 🐘 Database |
|:---:|:---:|:---:|
| Flutter | NestJS (TypeScript) | PostgreSQL + Prisma |
| Quotation journey for customers | JWT auth with refresh-token rotation | Dockerized, persisted in a named volume |

**Highlights**

- 🧩 **Modular monolith**: one deployable API with clear domain modules (`auth`, `users`, `quotations`) that can be split into services later
- 🔐 **Secure-by-default auth**: JWT access tokens plus rotating refresh tokens
- 📚 **Swagger UI** for exploring the API
- 🤖 **CI ready**: GitHub Actions for backend, Flutter and Firebase App Distribution
- 🧑‍💻 **Dev-friendly**: shared VS Code settings and recommended extensions

---

## 🏗️ Architecture

```mermaid
flowchart LR
    A["📱 Flutter<br/>Consumer App"] -->|"REST /api/v1"| B

    subgraph B["🛠️ NestJS API (modular monolith)"]
        direction TB
        B1["🔐 auth"]
        B2["👤 users"]
        B3["📝 quotations"]
    end

    B -->|"Prisma"| C[("🐘 PostgreSQL<br/>Docker")]
    B -.->|"docs"| D["📚 Swagger UI<br/>/api/docs"]
```

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| 📱 **Frontend** | Flutter |
| 🛠️ **Backend** | NestJS (TypeScript), JWT auth with refresh-token rotation |
| 🐘 **Database** | PostgreSQL, managed with Prisma |
| 🐳 **Infrastructure** | Docker Compose with a named volume for persistence |
| 📚 **API docs** | Swagger UI |
| 🤖 **CI/CD** | GitHub Actions (backend CI with Postgres service container, Flutter CI, Firebase App Distribution) |
| 🧑‍💻 **Tooling** | VS Code with recommended extensions and shared settings |

---

## 📂 Project Structure

```text
personal-loan-monorepo/
├── 🤖 .github/workflows/     # CI pipelines
├── 🧑‍💻 .vscode/              # Recommended extensions & settings
├── 📱 apps/
│   └── consumer_app/         # Flutter application
├── 🛠️ backend/                # NestJS API
│   ├── prisma/               # Schema, migrations, seed
│   └── src/
│       ├── auth/             # 🔐 Authentication
│       ├── users/            # 👤 Users
│       ├── quotations/       # 📝 Quotations
│       └── infrastructure/
│           └── database/     # 🐘 Prisma connection
├── 🐘 database/              # Database initialization guide
├── 📚 docs/                  # Documentation (incl. legacy mapping doc)
├── 🧰 scripts/               # Flutter check scripts (.sh / .ps1)
├── .env.example
├── docker-compose.yml
└── README.md
```

---

## 🚀 Quick Start

You'll bring up three things: the **database**, the **backend**, then the **Flutter app**.

### 1️⃣ Start PostgreSQL 🐘

From the **repo root**:

```bash
cp .env.example .env
docker compose up -d postgres
docker compose ps        # check it's healthy
```

> PostgreSQL will be available on `localhost:5432`.

### 2️⃣ Start the backend 🛠️

From `backend/`:

```bash
cp .env.example .env
npm install
npm run prisma:generate
npm run db:migrate
npm run db:seed
npm run start:dev
```

| What | Where |
|---|---|
| 🌐 API | `http://localhost:3000/api/v1` |
| 📚 Swagger UI | `http://localhost:3000/api/docs` |

> [!NOTE]
> Swagger is disabled in production unless you set `SWAGGER_ENABLED=true`.

### 3️⃣ Start the Flutter app 📱

From `apps/consumer_app/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

> [!TIP]
> If the platform folders (`android/`, `ios/`, ...) are missing, generate them first with `flutter create .`

---

## ⚙️ Configuration

Backend variables live in `backend/.env`:

| Variable | Description |
|---|---|
| `DATABASE_URL` | 🐘 PostgreSQL connection string |
| `JWT_ACCESS_SECRET` | 🔑 Secret used to sign access tokens |
| `JWT_ACCESS_TTL` | ⏱️ Access token lifetime |
| `PORT` | 🔌 Port the API listens on |
| `CORS_ORIGIN` | 🌍 Allowed browser origin(s) |

> [!CAUTION]
> 🔒 Never commit real credentials. Use a **secret manager** in production.

---

## 🧪 Scripts & Commands

| Command | What it does |
|---|---|
| `npm run db:migrate` | ▶️ Apply migrations locally (creates the `init` migration on first run) |
| `npm run db:seed` | 🌱 Load safe development seed data |
| `npm run db:reset` | 💥 **Deletes all local database data.** Never run against production |
| `npm run db:deploy` | 🚢 Apply committed migrations (production) |
| `scripts/check-flutter.sh` / `.ps1` | ✅ Run the same Flutter checks locally as CI |

> [!IMPORTANT]
> Don't use `prisma db push` for production deployments. Use `db:deploy` with committed migrations.

---

## 🔌 API Overview

All routes are under `/api/v1`. Open **Swagger UI** for the full, interactive reference. 📚

| Area | Endpoints |
|---|---|
| 💚 **Health** | `GET /health` |
| 🔐 **Auth** | register, login, refresh, logout |
| 👤 **Users** | `GET /users/me` |
| 🏷️ **Products** | list active products, get a product by code |
| 📝 **Quotations** | create, list, get, update sections, submit, cancel |
| 📎 **Documents** | upload, list, download, cancel |

<details>
<summary>📦 <b>Quotation request sections</b> (click to expand)</summary>

<br/>

The quotation request shape has changed, and any old example payload is outdated. The current sections are:

- 🙋 `applicant`
- 🏠 `addresses`
- 💼 `occupations`
- 💰 `loanRequest`
- 🚗 `vehicle`
- 👥 `persons`
- ✅ `consents`

</details>

---

## 🛡️ Before going to production

The API currently **only creates draft quotations**. It does **not** do credit scoring, eligibility checks, approvals or disbursements.

Before handling real customer data, you'll need at least:

- [ ] 🪪 Identity verification
- [ ] 🚦 Rate limiting
- [ ] 🔐 Multi-factor authentication (MFA)
- [ ] 🧾 Audit logs
- [ ] 🗄️ Secure document storage
- [ ] 📜 Consent management
- [ ] ⚖️ Security and legal review

---

## 🗺️ Roadmap

- [ ] 🔐 Finish authentication and authorization
- [ ] ✏️ Add draft update and submit endpoints
- [ ] 🏷️ Add product configuration APIs
- [ ] ☁️ Integrate object storage for documents
- [ ] 📜 Add consent versioning
- [ ] 🤖 Set up CI checks and a staging environment

---

<div align="center">

**Built with ☕ and 💙**

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:6366f1,100:0ea5e9&height=100&section=footer" alt="footer wave" />

</div>
