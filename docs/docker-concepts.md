# Docker concepts

Four short questions on the Docker fundamentals behind this lab, with answers.

## Q1. What does Docker do?

**b) Packages an application together with its dependencies and runs it in isolated containers.**

The other options describe different tools:

- a) Tracking versions of source code is Git.
- c) Emulating a full computer, hardware included, is a virtual machine or hypervisor.
- d) Bundling and minifying JavaScript is a bundler such as Webpack or Vite.

## Q2. Why use Docker Compose instead of plain `docker run` commands?

Compose lets you define a multi-container setup (services, networks, volumes, environment variables and
ports) in one declarative YAML file instead of typing a long `docker run` command for each container.
This makes the setup:

- **Reproducible**, because the whole stack is described in one file.
- **Easy to version-control and share**, because that file lives in the repository.
- **Easy to manage**, because one command starts, stops or rebuilds everything.

Compose also creates a shared network automatically, so services reach each other by name. In this lab
the app connects to the database at `db:5432`.

## Q3. What command starts all the containers defined in a compose file?

```sh
docker compose up
```

Usually run as `docker compose up -d` to start in detached (background) mode. This lab also uses
`--build` to rebuild the image first. Older installs use the hyphenated `docker-compose up`.

## Q4. What command stops and removes those containers?

```sh
docker compose down
```

This stops and removes the containers and the default network. Named volumes are kept, so the guestbook
data survives. Add `-v` to remove the named volumes too, which deletes the data.
