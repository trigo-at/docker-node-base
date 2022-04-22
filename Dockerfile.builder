FROM node:17.1.0-slim

# RUN apt-get update

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD package-lock.json .
ONBUILD RUN npm ci

ONBUILD ADD . /app
ONBUILD RUN npm run build
ONBUILD RUN npm prune --production --json
