# ----* Dependencies *---
FROM node:9.11.1-slim AS dependencies

ONBUILD RUN apt-get update -yqq && apt-get install -yqq git

ONBUILD ARG NPM_TOKEN
ONBUILD ADD npmrc /root/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .

ONBUILD RUN yarn install --no-cache --frozen-lockfile --production
ONBUILD RUN cp -R node_modules node_modules_production

ONBUILD ADD . /app

ONBUILD RUN rm /root/.npmrc

# ----* Production *----
FROM dependencies AS production

ONBUILD COPY --from=dependencies /app .
ONBUILD COPY --from=dependencies /node_modules_production ./node_modules

EXPOSE 3000

CMD ["npm", "start"]
