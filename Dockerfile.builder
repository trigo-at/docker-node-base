FROM node:17.1.0-slim

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD package-lock.json .
ONBUILD RUN npm ci

ONBUILD ARG ENV

ONBUILD ADD . /app
ONBUILD RUN if [ -n "$ENV" ]; then cat ./build-env/.env.${ENV} > .env.local || true ; fi
ONBUILD RUN npm run build
ONBUILD RUN npm prune --production --json
