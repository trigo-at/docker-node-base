ARG VERSION
ARG FLAVOR
FROM node:18.4.0-slim

# RUN apt-get update

USER node
ONBUILD ARG NPM_TOKEN
ADD --chown=node:node npmrc /root/.npmrc
ADD --chown=node:node npmrc /app/.npmrc

WORKDIR /app

ONBUILD ADD --chown=node:node package.json .
ONBUILD ADD --chown=node:node package-lock.json .
ONBUILD RUN npm ci

ONBUILD ADD --chown=node:node . /app
ONBUILD RUN npm run build
ONBUILD RUN npm prune --production --json
