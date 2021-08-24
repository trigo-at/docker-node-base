FROM node:16.7.0-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
	apt-get -yqq install sudo && \
	apt-get -yqq install apt-transport-https curl

RUN mkdir -p /usr/share/man/man1

RUN set -x ; \
    apt-get install -y wget \
    && apt-get install -y gnupg2 \
    && apt-get install -y software-properties-common \
    && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add - \
    && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
    && apt-get update && apt-get install -y adoptopenjdk-8-hotspot \
	&& apt-get -y -q install libreoffice libreoffice-writer \
    ure libreoffice-java-common libreoffice-core libreoffice-common \
    fonts-opensymbol hyphen-fr hyphen-de hyphen-en-us \
    hyphen-it hyphen-ru fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
    fonts-noto fonts-dustin fonts-f500 fonts-fanwood fonts-freefont-ttf \
    fonts-liberation fonts-lmodern fonts-lyx fonts-sil-gentium fonts-texgyre \
    fonts-tlwg-purisa unoconv \
	&& apt-get -q -y remove libreoffice-gnome libreoffice-gtk3

RUN adduser --home=/opt/libreoffice --disabled-password --gecos "" --shell=/bin/bash libreoffice

ONBUILD ADD sofficerc /etc/libreoffice/sofficerc

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
