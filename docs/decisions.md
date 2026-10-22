# Design decisions

Each decision is recorded with its context, the choice made, the alternatives considered and the
consequences.

## D1. Multi-stage Docker build

**Context.** The brief states that at runtime the server only needs `build/`, the production
`node_modules` and `package.json`.

**Decision.** Use two stages. The `build` stage runs `npm ci`, `npm run build` and
`npm prune --omit=dev`. The `runtime` stage copies only those three artefacts.

**Alternatives.** A single-stage image is simpler but ships source, dev dependencies and the Vite
toolchain, which makes it larger and increases the attack surface.

**Consequences.** Smaller image (162 MB) and a smaller attack surface. The image has a slightly more
involved `Dockerfile`.

## D2. `node:22-alpine` base image

**Context.** `.npmrc` sets `engine-strict=true`, and only Node 20.19+, 22.12+ and 24+ are supported.

**Decision.** `node:22-alpine` for both stages. 22 is an even-numbered LTS release inside the supported range.

**Alternatives.** `node:24-alpine` also works. `node:22` (Debian) is larger. `node:23` and `node:18` are
rejected by `engine-strict`.

**Consequences.** Small image. Alpine uses musl, which is fine here because the `postgres` driver is pure
JavaScript and has no native addons.

## D3. Layer ordering for build caching

**Decision.** Copy `package.json`, `package-lock.json` and `.npmrc` and run `npm ci` *before* copying the
rest of the source.

**Consequences.** Editing application code does not invalidate the dependency layer, so rebuilds are fast.
`npm ci` (not `npm install`) installs exactly what the lockfile records, which keeps builds repeatable.

## D4. Run as a non-root user

**Decision.** `USER node`, the unprivileged user shipped in the official Node image. Copied files are
`--chown`ed to it.

**Alternatives.** Create a custom user. There is no benefit when `node` already exists.

**Consequences.** A compromised process has no root access inside the container. The app needs no
privileged ports because it listens on 3000.

## D5. Configuration through environment, none baked in

**Decision.** The `Dockerfile` sets only non-secret defaults (`NODE_ENV`, `PORT`, `HOST`).
`DATABASE_URL` and the Postgres credentials are set in `compose.yml`.

**Alternatives.** Put `DATABASE_URL` in the image with `ENV`. This would leak credentials to anyone who can
inspect the image, and it would tie the image to one environment.

**Consequences.** The same image can run anywhere with different credentials. The credentials in
`compose.yml` are lab placeholders. A real deployment should use `.env` files or Docker secrets
(see *Future work*).

## D6. PostgreSQL 17 on Alpine

**Context.** PostgreSQL 14+ using the official `postgres` image is required. Postgres 18 and newer changed
the data directory, and mounting a volume at `/var/lib/postgresql/data` makes 18+ refuse to start.

**Decision.** `postgres:17-alpine`, with the volume mounted at `/var/lib/postgresql/data`.

**Alternatives.** `postgres:18-alpine` with the volume at `/var/lib/postgresql`. 17 is a mature release
and avoids the path change.

**Consequences.** Correct mount path for the chosen version. Upgrading to 18+ later requires changing
the mount path and a data migration.

## D7. Named volume for persistence

**Decision.** A named volume `guestbook_data` mounted at the Postgres data directory.

**Alternatives.** A bind mount ties the data to a host path and brings permission problems, especially on
Windows and macOS. An anonymous volume is hard to find and easy to orphan.

**Consequences.** Data survives `docker compose down` and `up`. It is only removed by `down -v`, which is
what the automarker uses for teardown.

## D8. Healthcheck plus `depends_on: service_healthy`

**Context.** The brief requires that the app "should not come up before the database is ready to accept
connections".

**Decision.** `pg_isready` healthcheck on `db`; `app` declares `depends_on: db: condition: service_healthy`.

**Alternatives.**

- Plain `depends_on` only waits for the container to *start*, not for Postgres to accept connections.
- A `wait-for-it` script inside the app image adds a dependency and extra moving parts.
- Relying only on the app's built-in retry works but produces noisy "database not ready" logs.

**Consequences.** Deterministic start order. The app's own retry loop remains as a second safety net.

## D9. Do not publish the database port

**Decision.** `db` has no `ports:` entry. `app` reaches it through the Compose network at `db:5432`.

**Consequences.** The database cannot be reached from the host or the wider network, which reduces exposure
and avoids host port conflicts with a local Postgres. For debugging use
`docker compose exec db psql -U guestbook`.

## D10. Hostname-based service discovery

**Decision.** `DATABASE_URL` uses the service name `db` as the host.

**Alternatives.** `localhost`, `127.0.0.1` and `host.docker.internal` are rejected by the automarker and
would not reach the database container anyway. Hard-coding an IP breaks when containers are recreated.

**Consequences.** Compose's embedded DNS resolves `db` to the current container IP even after recreation.

## D11. Image healthcheck and restart policy

**Decision.** A `HEALTHCHECK` in the `Dockerfile` calls `/api/marking-test` with busybox `wget`.
Both services use `restart: unless-stopped`.

**Consequences.** `docker ps` shows real application health including DB connectivity. Containers recover
from crashes and daemon restarts. Intentionally stopped containers stay stopped.

## D12. `.dockerignore`

**Decision.** Exclude `node_modules`, `.svelte-kit`, `build`, `.env*`, logs, docs, the Git directory and
the automarker from the build context.

**Consequences.** Faster builds, a stable cache, and no risk of host `node_modules` or secrets leaking into
the image. This also stops host-built dependencies overwriting the ones installed in the container.

## D13. Documentation with MkDocs

**Decision.** MkDocs with the Material theme and Mermaid diagrams, kept in `docs/` beside the code.

**Consequences.** Architecture and decisions are versioned with the code and render as a browsable site
(`mkdocs serve`).

## Future work

- Move credentials to a git-ignored `.env` file or Docker secrets.
- Pin images by digest for fully reproducible builds.
- Add a reverse proxy with TLS in front of `app`.
- Add a database backup job for the `guestbook_data` volume.
