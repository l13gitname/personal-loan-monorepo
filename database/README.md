# Database layer

## Local initialization

Run these commands from the repository root:

```bash
cp .env.example .env
docker compose up -d postgres
docker compose logs -f postgres
```

Then initialize the schema from the backend directory:

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run db:migrate
npm run db:seed
```

## Where database code lives

- `backend/prisma/schema.prisma`: tables, relations, enums, and indexes.
- `backend/prisma/migrations/`: committed schema migration history.
- `backend/src/infrastructure/database/`: Prisma client lifecycle and NestJS module.
- Domain modules call the database through their own services/repositories.

## Rules

- Do not create or modify production tables manually.
- Generate migrations locally, review the SQL, and commit the migration directory.
- Deploy with `prisma migrate deploy`.
- Do not run `prisma migrate reset` against shared or production databases.
- Use a separate database/schema and credentials per environment.
- Use a managed PostgreSQL service for production unless there is a clear operational reason to self-host.
- Configure connection pooling and database backups before production traffic.
