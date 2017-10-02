FROM node:8.6-slim

RUN apt-get update && \
   apt-get install -y apt-transport-https && \
   curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
   echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
   apt-get update &&  \
   apt-get install -y git yarn

RUN rm /usr/local/bin/yarn

ONBUILD ARG NPM_TOKEN
ADD npmrc /root/.npmrc
ADD npmrc /app/.npmrc

WORKDIR /app

ONBUILD ADD package.json .
ONBUILD ADD yarn.lock .
ONBUILD RUN yarn install

ONBUILD ADD . /app

EXPOSE 3000

CMD ["npm", "start"]

