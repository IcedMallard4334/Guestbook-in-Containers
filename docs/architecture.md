# Architecture

## Overview

The system is a two-container Compose application. The browser only ever talks to the `app`
container; the `db` container is reachable only on the private Compose network.

```mermaid
flowchart LR
    user([Browser]) -- "HTTP :3000" --> app

    subgraph host[Docker host]
        subgraph net[Compose default network]
            app["app<br/>SvelteKit on Node 22 (alpine)<br/>non-root user 'node'"]
            db["db<br/>postgres:17-alpine"]
            app -- "postgres://...@db:5432/guestbook" --> db
        end
        vol[("named volume<br/>guestbook_data")]
        db --- vol
    end
```

## Services

### `app`

- Built from the repository `Dockerfile` (`build.context: .`).
- SvelteKit with `@sveltejs/adapter-node`; run with `node build`.
- Configured purely through environment variables:
    - `NODE_ENV=production`
    - `DATABASE_URL=postgres://guestbook:guestbook_pw@db:5432/guestbook`
    - `PORT=3000` / `HOST=0.0.0.0` (image defaults)
- Publishes container port `3000` to host port `3000`.
- Creates its own `entries` table on startup (`CREATE TABLE IF NOT EXISTS`), so no SQL is run by hand.
- Exposes `GET /api/marking-test`, used both by the automarker and by the image `HEALTHCHECK`.

### `db`

- Official `postgres:17-alpine` image.
- Credentials supplied through `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_DB`.
- Data directory `/var/lib/postgresql/data` is backed by the named volume `guestbook_data`.
- `healthcheck` runs `pg_isready`, so other services can wait until it accepts connections.
- **No published ports**: the database is reachable from `app` over the Compose network only.

## Image build (multi-stage)

```mermaid
flowchart TB
    subgraph build["Stage 1: build (node:22-alpine)"]
        a1[COPY package*.json .npmrc] --> a2[npm ci]
        a2 --> a3[COPY source]
        a3 --> a4[npm run build]
        a4 --> a5["npm prune --omit=dev"]
    end
    subgraph runtime["Stage 2: runtime (node:22-alpine)"]
        b1["COPY build/"] --> b2["COPY production node_modules"]
        b2 --> b3[COPY package.json]
        b3 --> b4["USER node, CMD node build"]
    end
    a5 -. "only build/, node_modules, package.json" .-> b1
```

The runtime image contains no source code, no dev dependencies and no build tooling.
It is about 162 MB, well under the 300 MB good-practice threshold.

## Startup sequence

```mermaid
sequenceDiagram
    participant C as docker compose up
    participant D as db
    participant A as app
    C->>D: create + start
    loop every 5s, up to 10 retries
        C->>D: pg_isready
    end
    D-->>C: healthy
    C->>A: start (depends_on: service_healthy)
    A->>D: CREATE TABLE IF NOT EXISTS entries
    A-->>C: /api/marking-test returns 200 ok
```

## Data lifecycle

| Command | Containers | Volume `guestbook_data` | Guestbook data |
| --- | --- | --- | --- |
| `docker compose stop` / `restart` | stopped / restarted | kept | kept |
| `docker compose down` | removed | **kept** | **kept** |
| `docker compose down -v` | removed | **deleted** | **lost** |

## Resilience

Two layers cover the database being unavailable:

1. **Compose level:** `depends_on` with `condition: service_healthy` prevents `app` starting before
   Postgres accepts connections.
2. **Application level:** the provided `hooks.server.ts` retries schema creation with back-off, and the
   `postgres` driver reconnects on its own. This is why the app recovers when only the database is
   restarted (automarker stage 7) without the app container being restarted.
