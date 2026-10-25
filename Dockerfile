# github-readme-stats, run as a plain Node server (server.js) on port 8080 by the image's non-root `node` user.
# The build arguments are the stack file's (yggdrasil's stacks/github-readme-stats.yml): public values only. The
# GitHub token (PAT_1, PAT_2, ...) is the application's variable, read from the container's environment at run
# time (env_file), never a build argument.
# Node 22 is what .nvmrc and package.json "engines" ask for.
FROM node:22.23.4-alpine3.24@sha256:fe4f6d74e20370acb04ad889077d14d0f64a9c8ea6a42bc60cddf1e844699914 AS deps

WORKDIR /app
COPY package.json package-lock.json ./
# --ignore-scripts: the "prepare" script runs husky, a git hook tool the image has no use for.
RUN npm ci --omit=dev --ignore-scripts && mkdir -p node_modules

FROM node:22.23.4-alpine3.24@sha256:fe4f6d74e20370acb04ad889077d14d0f64a9c8ea6a42bc60cddf1e844699914

ARG GIT_COMMIT=
ARG YGG_ENVIRONMENT=
ENV NODE_ENV=production \
    PORT=8080 \
    GIT_COMMIT=${GIT_COMMIT} \
    YGG_ENVIRONMENT=${YGG_ENVIRONMENT}

WORKDIR /app
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

LABEL org.opencontainers.image.revision="${GIT_COMMIT}" \
      yggdrasil.built-for="${YGG_ENVIRONMENT}"

USER node
EXPOSE 8080
# wget is busybox's, in the image; --spider asks without downloading.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/healthz || exit 1
CMD ["node", "server.js"]
