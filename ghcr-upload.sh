#!/bin/sh

# builds image from repository Dockerfile and tags with repo name and branch as flag by extracting branch name from GITHUB_REF

docker build . --tag ghcr.io/trigo-at/node-base:${GITHUB_REF##*/}

#logs into github container registry via secret token and username

echo $TRIGO_PACKAGE_ACCESS_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

#pushes image to github container registry
docker push ghcr.io/trigo-at/node-base:${GITHUB_REF##*/}