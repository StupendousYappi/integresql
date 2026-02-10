# AGENTS.md

Guidance for coding agents working in this repository (`/workspace/integresql`).

## Project overview

- **IntegreSQL** is a Go web server that manages isolated PostgreSQL databases for integration tests.
- It exposes a REST API to create/finalize template databases and lease/release isolated test databases cloned from templates.
- The architecture is focused on **fast, parallel, deterministic tests** using real Postgres.

## Repository layout

- `cmd/server/`: application entrypoint.
- `internal/api/`: HTTP server wiring, handlers, middleware, route registration.
- `internal/router/`: router setup and router-level tests.
- `pkg/manager/`: core orchestration logic for templates and test DB pools.
- `pkg/pool/`: pool lifecycle and concurrency behavior.
- `pkg/db/`: DB access/config primitives.
- `pkg/templates/`: template metadata and collections.
- `pkg/util/`: shared utilities.
- `tests/`: integration-style tests and test client models.

Prefer small, targeted edits in the package that owns the behavior instead of cross-cutting refactors.

## Development workflow

- Main local workflow is make-based:
  - `make init` – download modules, install tools, tidy.
  - `make` – format, build, vet flow (see Makefile default target).
  - `make test` – run tests with race + coverage output.
- Quick direct alternative:
  - `go test ./...`

## Environment expectations

- Many tests require a reachable PostgreSQL instance (defaults often point to `127.0.0.1:5432` unless environment is overridden).
- For full local development, repo docs expect Docker + Docker Compose.
- `docker-compose.yml` provides a canonical development setup (`integresql` + `postgres` services).

If tests fail with `connect: connection refused` to Postgres, treat this as an environment dependency issue first.

## Coding standards

- Use idiomatic Go and keep packages cohesive.
- Always run `gofmt` on changed Go files.
- Keep exported API changes intentional; avoid renaming env vars, route paths, or config fields unless explicitly required.
- Preserve existing logging style (zerolog) and error-wrapping patterns used nearby.
- Avoid introducing new dependencies unless necessary.

## Testing guidance for agents

When making code changes:

1. Run the narrowest relevant tests first (package-level when possible).
2. Then run broader verification (`go test ./...` or `make test`) when environment permits.
3. If Postgres is unavailable, report clearly which command failed and why.

For non-code/doc-only changes, lightweight checks are sufficient.

## Safe-change checklist

Before finishing:

- Confirm modified files are minimal and relevant.
- Ensure formatting is clean.
- Ensure any new behavior is covered by tests or explain why not.
- Provide concise notes on runtime dependencies (especially PostgreSQL) in your handoff.
