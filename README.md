# Personal Loan Platform — Monorepo Starter

Starter repository for a Flutter personal-loan quotation application with a NestJS modular-monolith backend and PostgreSQL.

The structure is intentionally a **modular monolith**: one deployable API, with domain boundaries that can be extracted into independent services later. It does not introduce distributed-system complexity before the team needs it.

## 1. Repository layout

```text
personal-loan-monorepo/
├── apps/
│   └── consumer_app/             # Flutter consumer application
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma         # Database model source of truth
│   │   └── seed.ts               # Safe development seed
│   └── src/
│       ├── infrastructure/
│       │   └── database/         # Prisma connection boundary
│       └── modules/
│           ├── auth/             # Register/login/logout
│           ├── users/            # Current user
│           └── quotations/       # Loan quotation application
├── database/
│   └── README.md                 # Database initialization guide
├── docker-compose.yml
├── .env.example
└── .gitignore
```

## 2. Prerequisites

- Docker Desktop (or Docker Engine + Compose)
- Node.js 20 or newer and npm
- Flutter stable SDK
- Android Studio for Android development
- Xcode on macOS for iOS development

## 3. Start PostgreSQL

From the repository root:

```bash
cp .env.example .env
docker compose up -d postgres
docker compose ps
```

Windows PowerShell equivalent for the first command:

```powershell
Copy-Item .env.example .env
```

PostgreSQL is exposed on `localhost:5432`. The database is persisted in a Docker named volume.

> The credentials in `.env.example` are for local development only. Change them for every shared or production environment. Never commit `.env`.

## 4. Start the backend

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run db:migrate
npm run db:seed
npm run start:dev
```

On Windows PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

The API listens on `http://localhost:3000/api/v1`.

Useful endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/v1/health` | Health check |
| POST | `/api/v1/auth/register` | Create a user |
| POST | `/api/v1/auth/login` | Login and create a session |
| POST | `/api/v1/auth/refresh` | Rotate refresh token and issue a new access token |
| POST | `/api/v1/auth/logout` | Revoke current session |
| GET | `/api/v1/users/me` | Get current user (Bearer token) |
| GET | `/api/v1/products` | List active products |
| GET | `/api/v1/products/:code` | Product + required documents and consents |
| POST | `/api/v1/quotations` | Create a draft for a product (`productCode`), sections optional |
| GET | `/api/v1/quotations` | List current user's quotations |
| GET | `/api/v1/quotations/:id` | Full quotation with status history |
| PATCH | `/api/v1/quotations/:id` | Save one or more sections of a draft |
| POST | `/api/v1/quotations/:id/submit` | Validate (common + product rules + documents + consents) and submit |
| POST | `/api/v1/quotations/:id/cancel` | Cancel |
| POST | `/api/v1/quotations/:id/documents` | Upload (multipart: `file`, `documentTypeCode`) to server storage |
| GET | `/api/v1/quotations/:id/documents` | List documents |
| GET | `/api/v1/quotations/:id/documents/:docId/download` | Download |
| DELETE | `/api/v1/quotations/:id/documents/:docId` | Cancel a document |

> The quotation request shape changed: see `docs/legacy-mapping.md` and `backend/src/modules/quotations/dto/quotation.dto.ts`. The example payload below predates it; sections are now `applicant`, `addresses`, `occupations`, `loanRequest`, `vehicle` (motorcycle only), `persons`, `consents`.

Example registration:

```json
{
  "email": "demo@example.com",
  "password": "ChangeMe123!",
  "firstName": "Demo",
  "lastName": "User"
}
```

Example quotation request (all values are illustrative):

```json
{
  "personalInformation": {
    "firstName": "Demo",
    "lastName": "User",
    "phoneNumber": "0800000000",
    "dateOfBirth": "1994-01-01",
    "nationality": "TH"
  },
  "productInformation": {
    "productCode": "PERSONAL_LOAN",
    "requestedAmount": 50000,
    "requestedTermMonths": 24
  },
  "workInformation": {
    "employmentType": "SALARIED",
    "companyName": "Example Company",
    "monthlyIncome": 30000
  },
  "documents": [],
  "consents": [
    {
      "consentType": "PRIVACY_NOTICE",
      "version": "1.0",
      "accepted": true
    }
  ]
}
```

The API currently creates a draft record. It does not perform credit scoring, eligibility decisions, loan approval, or a real loan disbursement.

## 5. Start the Flutter app

See `apps/consumer_app/README.md` (first-run steps, structure, tests, CI/CD).
Quick version, after `flutter create` has generated the platform folders:

```bash
cd apps/consumer_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

API docs (Swagger UI) are served by the backend at `http://localhost:3000/api/docs`
(disabled in production unless `SWAGGER_ENABLED=true`).

CI: `.github/workflows/` contains backend CI (Postgres service container), Flutter CI,
and Firebase App Distribution. `scripts/check-flutter.sh|.ps1` runs the same Flutter checks locally.

## Editor setup (VS Code)

Open the repo root in VS Code and accept **"Install recommended extensions"**.
The list lives in `.vscode/extensions.json` (Dart/Flutter, Prisma, ESLint/Prettier,
Docker, database client, Thunder Client, GitLens, GitHub Actions, ...) and shared
editor settings in `.vscode/settings.json`. Use Android Studio only for the emulator
and SDK Manager. When working on the Flutter app, opening `apps/consumer_app` as its
own workspace folder makes the Dart extension find the project more reliably.

## 6. Database workflow

The Prisma schema is the source of truth for application database structure.

After changing `backend/prisma/schema.prisma`:

```bash
cd backend
npm run db:migrate
```

On first initialization this creates an `init` migration under `backend/prisma/migrations/` and applies it to the local database. For later schema changes, run `npx prisma migrate dev --name describe_your_change` from `backend/`. Commit every generated migration folder to Git.

For a clean local database only:

```bash
npm run db:reset
```

**Warning:** `db:reset` deletes local database data. Never run it against production.

For production deployment, apply committed migrations with:

```bash
npm run db:deploy
```

Do not use `prisma db push` as the production schema deployment process. Commit migration files to Git and review them before deployment.

## 7. Environment variables

Backend configuration is read from `backend/.env`. See `backend/.env.example`.

- `DATABASE_URL`: PostgreSQL connection string
- `JWT_ACCESS_SECRET`: signing key for short-lived access tokens
- `JWT_ACCESS_TTL`: access token lifetime
- `PORT`: API port
- `CORS_ORIGIN`: allowed frontend origins

Use a secret manager for production secrets. Do not store production credentials in GitHub source code or Docker Compose files.

## 8. Architecture rules

1. Keep one NestJS API deployment initially.
2. Each business domain owns its module, DTOs, services, and persistence operations.
3. Other modules must not query another domain's tables directly.
4. Keep database access behind `infrastructure/database` and domain repositories/services.
5. Use asynchronous jobs/events for slow work such as document processing and notifications.
6. Store uploaded files in object storage; PostgreSQL should store metadata and object keys only.
7. Add correlation IDs, structured logs, metrics, and tracing before scaling out.
8. Extract a service only when independent deployment, scaling, ownership, or isolation provides measurable value.

## 9. Security and production work still required

This starter is not production-ready for a financial application. Before handling real customer data:

- Add email/phone verification, password reset, brute-force protection, rate limiting, and MFA policy.
- The starter rotates refresh tokens and stores only their SHA-256 hashes. Before production, add refresh-token reuse detection that revokes the full token family, device/session management, and security review.
- Use HTTPS everywhere and secure secret management.
- Add authorization policies and audit logs.
- Add consent text/version management, proof of acceptance, retention, and withdrawal handling.
- Add secure document upload using signed object-storage URLs, malware scanning, file type/size validation, and encryption.
- Define PDPA/privacy notice, retention, deletion, access-control, and incident-response processes.
- Add automated unit, integration, API contract, and load tests.
- Review database indexes, connection pooling, backups, restore drills, and disaster recovery.
- Have the security and legal teams review the complete lending journey.

## 10. GitHub initialization

Create an empty repository on GitHub, then from this directory:

```bash
git init
git add .
git commit -m "chore: initialize personal loan platform monorepo"
git branch -M main
git remote add origin https://github.com/ORG/REPOSITORY.git
git push -u origin main
```

Replace `ORG/REPOSITORY` with your actual GitHub organization and repository.

## 11. Suggested next milestones

1. Complete auth/session lifecycle and authorization.
2. Add quotation draft update and submit endpoints.
3. Add master-data/product configuration APIs.
4. Integrate secure document upload to object storage.
5. Add consent versioning and audit trail.
6. Add CI checks, automated tests, staging deployment, and load testing.
