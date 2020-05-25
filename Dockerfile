FROM node:14.0.0-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
	apt-get -yqq install sudo && \
	apt-get -yqq install apt-transport-https curl

RUN mkdir -p /usr/share/man/man1

RUN set -x ; \
	apt-get update \
	&& apt-get -y -q install libreoffice libreoffice-writer \
    ure libreoffice-java-common libreoffice-core libreoffice-common \
    openjdk-8-jre fonts-opensymbol hyphen-fr hyphen-de hyphen-en-us \
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