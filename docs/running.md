# Running and testing

## Prerequisites

- Docker with Compose v2
- For the automarker: `bash`, `curl` and `jq`
- Host port `3000` free

## Run the stack

```sh
docker compose up -d --build   # build the image and start both services
docker compose ps              # both should become "healthy"
```

Open <http://localhost:3000> and leave an entry in the guestbook.

Diagnostic endpoint:

```sh
curl http://localhost:3000/api/marking-test
```

## Stop and restart

```sh
docker compose down            # remove containers, KEEP the data volume
docker compose up -d           # data is still there
docker compose down -v         # remove containers AND the data (destructive)
```

## Run the automarker

```sh
./automark.sh                  # build, start, test, tear down
./automark.sh --keep           # leave the stack running afterwards
```

## Results

| Stage | Result |
| --- | --- |
| 1. Static checks | 7 / 7 |
| 2. Build and start | 3 / 3 |
| 3. Marking-test endpoint | 9 / 9 |
| 4. App smoke test | 3 / 3 |
| 5. Persistence | 3 / 3 |
| 6. Full-stack restart | 2 / 2 |
| 7. Database-only restart | 1 / 1 |
| **Required total** | **28 / 28 (100%)** |
| 8. Good practice | 8 / 8, 0 warnings |

Notable values reported by the run: Node `v22.23.4`, PostgreSQL `17.11`, app image size `162 MB`,
app running as uid `1000`.

## Building this documentation

```sh
pip install mkdocs mkdocs-material
mkdocs serve                   # live preview at http://127.0.0.1:8000
mkdocs build --strict          # static site into site/
```
