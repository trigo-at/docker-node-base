FROM node:13.12.0-slim

RUN apt-get update

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD package-lock.json .
ONBUILD RUN npm install

ONBUILD ADD . /app

EXPOSE 3000

CMD ["npm", "start"]

