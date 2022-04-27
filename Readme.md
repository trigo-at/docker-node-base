# This readme is valid for Versions/Branches starting with node version 18.0.0

# Node Base Images

Each branch is built as Docker image tag. 
Tag naming follows the official Node image tag names

The upstream version is base on the branch name.

# Usage
## Wihtout build step

```
FROM ghcr.io/trigo-at/node-base:{{VERSION}}
```
This uses `/app` as working directory and runs `npm start`

## With build step
```
FROM ghcr.io/trigo-at/node-base:{{VERSION}}-builder as builder
FROM ghcr.io/trigo-at/node-base:{{VERSION}}-runtime
```
This runs `npm ci` and `npm prune --production` in the builder image and copies over all of `/app` to the runtime image, uses `npm start` to run the app in the runtime image.