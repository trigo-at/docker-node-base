FROM node:15.5.1-slim

RUN apt-get update
RUN apt-get install bash

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc
ADD ./docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD package-lock.json .
ONBUILD RUN npm install

ONBUILD ADD . /app

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint"]
