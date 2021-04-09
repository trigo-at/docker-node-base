FROM node:7.4-slim

RUN apt-get update && \
   apt-get install -y apt-transport-https && \
   curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
   echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
   apt-get update &&  \
   apt-get install -y git yarn

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
# Build identifier base image build
ARG GIT_COMMIT
ARG BUILD_UUID

LABEL "build_uuid"="${BUILD_UUID}"
LABEL "git_commit"="${GIT_COMMIT}"

# Build Identifier when used as base image
ONBUILD ARG BUILD_UUID=00000
ONBUILD ARG GIT_COMMIT=00000

ONBUILD LABEL "build_uuid"="${BUILD_UUID}"
ONBUILD LABEL "git_commit"="${GIT_COMMIT}"
### END TEMPLATE ###
