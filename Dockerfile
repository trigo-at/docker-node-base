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
