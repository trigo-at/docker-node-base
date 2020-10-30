FROM node:6-slim

RUN apt-get update -yqq && apt-get install -yqq git

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD RUN npm install
ONBUILD ADD . /app

ONBUILD RUN rm /root/.npmrc

EXPOSE 3000

CMD ["npm", "start"]
