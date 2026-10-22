# Guestbook containerisation

**Course:** COMS3011A Lab 2: Sustainable, Repeatable Infrastructure
**Student:** Victor Hyginus (2849537)

This site documents how the provided SvelteKit guestbook application was containerised
and orchestrated with Docker Compose, and why each design choice was made.

## The problem

"It works on my machine" bugs come from small differences between execution environments.
Containerisation fixes this by declaring the software and versions a service needs and running
it in a self-contained environment.

## What was delivered

| Deliverable | File | Purpose |
| --- | --- | --- |
| Image definition | `Dockerfile` | Multi-stage build of the SvelteKit app into a small, non-root runtime image |
| Stack definition | `compose.yml` | Two services (`app`, `db`), a named volume, a healthcheck and start ordering |
| Ignore rules | `.dockerignore` | Keeps `node_modules`, VCS data and docs out of the build context |
| Documentation | `docs/`, `mkdocs.yml` | This site |

## Result

The provided `automark.sh` reports **28/28 required checks** and **8/8 good-practice checks**
(no warnings). See [Running and testing](running.md) for the full output.

## Where to go next

- [Architecture](architecture.md): the containers, network, volume and startup sequence.
- [Decisions](decisions.md): the choices made, the alternatives and the trade-offs.
- [Running and testing](running.md): how to run, verify and clean up the stack.
- [AI declaration](ai-declaration.md): which AI tools were used and for what.
