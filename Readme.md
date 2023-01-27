# This readme is valid for Versions/Branches starting with node version 18.0.0 (incl. a backport to v17.1.0)

# Node Base Images

Each branch is built as Docker image tag. 
Tag naming follows the official Node image tag names

The upstream version is base on the branch name.

# Environment Variables

Starting with nodejs version 19.4.0 images some environment variable are provided at runtime if injected with --build-arg when building images

| NAME | Default Value | Explanation |
|------|---------------|-------------|
| GIT_COMMIT | 0000 | Short commit sha for the current build, eg. `ac45a459692d` |
| BUILD_UUID | 0000 | Unique build identifier, if build by our jenkins pipeline eg. `jenkins-trigo-at-PROJECT_NAME-BRANCH_NAME-BUILD_NR` |
| BUILD_TIME | 0000 | Timestamp of the build, if build by our jenkins pipeline the format is `YYYY-MM-DD'T'hh:mm:ssZ` eg. `2023-01-26T14:12:04Z` |


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
