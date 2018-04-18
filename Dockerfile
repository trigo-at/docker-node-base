# ----* Base Node *----
FROM node:9.11.1-slim AS base

RUN apt-get update -yqq && apt-get install -yqq git

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .

# ----* Testing *----
FROM base AS testing

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .

ONBUILD RUN yarn install

ONBUILD ADD . /app

ONBUILD RUN rm /root/.npmrc

EXPOSE 3000

CMD ["npm", "start"]

# ----* Dependencies *---
FROM base AS dependencies

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .

ONBUILD RUN yarn install --no-cache --frozen-lockfile --production
ONBUILD RUN cp -R node_modules node_modules_production

ONBUILD ADD . /app

ONBUILD RUN rm /root/.npmrc

# ----* Production *----
FROM base AS production

ONBUILD COPY --from=dependencies /app .
ONBUILD COPY --from=dependencies /node_modules_production ./node_modules

EXPOSE 3000

CMD ["npm", "start"]
