# syntax=docker/dockerfile:1

# ---- Stage 1: build ----
# Full dependency install + SvelteKit/Vite build. Nothing from this stage
# except build/ and the production node_modules reaches the final image.
FROM node:22-alpine AS build
WORKDIR /app

# Copy manifests first so the (slow) dependency layer is cached until they change.
COPY package.json package-lock.json .npmrc ./
RUN npm ci

COPY . .
RUN npm run build \
 && npm prune --omit=dev

# ---- Stage 2: runtime ----
FROM node:22-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

# Only what the server needs at runtime: build/, production node_modules, package.json.
COPY --from=build --chown=node:node /app/build ./build
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/package.json ./package.json

# The official node image ships an unprivileged "node" user.
USER node

EXPOSE 3000

# busybox wget is available in alpine; /api/marking-test returns 503 when the DB is down.
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=5 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/api/marking-test" >/dev/null || exit 1

CMD ["node", "build"]
