# ----* Testing *----
FROM node:9.11.1-slim AS testing

RUN apt-get update -yqq && apt-get install -yqq git

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .

ONBUILD RUN yarn install

ONBUILD ADD . /app

ONBUILD RUN rm /root/.npmrc

EXPOSE 3000

CMD ["npm", "start"]
