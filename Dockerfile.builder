ARG VERSION
ARG FLAVOR
FROM node:$VERSION-$FLAVOR

# RUN apt-get update

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc

WORKDIR /app

ONBUILD RUN if [ -f "./npmrc" ]; then cat ./npmrc >> /app/.npmrc && cat ./npmrc >> /root/.npmrc; fi
ONBUILD ADD package.json .
ONBUILD ADD package-lock.json .
ONBUILD RUN npm ci

ONBUILD ADD . /app
ONBUILD RUN npm run build
ONBUILD RUN npm prune --production --json
