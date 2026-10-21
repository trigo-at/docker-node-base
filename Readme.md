# This readme is valid for Versions/Branches starting with node version 18.0.0 (incl. a backport to v17.1.0)

# Node Base Images

Each branch is built as Docker image tag. 
Tag naming follows the official Node image tag names

The upstream version is base on the branch name.

# Environment Variablees

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
# TLS trust (eMudhra/emSign, October 2026)

Starting with 26.12.0 every image runs Node with `NODE_OPTIONS=--use-openssl-ca` against the
patched Debian `ca-certificates` package (bookworm `>= 20250419~deb12u2`, trixie `>= 20250419+deb13u1`), because the bundled Node root
store still trusts the compromised emSign intermediates. `/usr/local/lib/trigo/tls-trust-check.mjs`
fails the base build and, as the first ONBUILD step, every child build if the flag is missing,
`--use-system-ca`/`--use-bundled-ca` or `NODE_TLS_REJECT_UNAUTHORIZED=0` are set, or the OS store
or `NODE_EXTRA_CA_CERTS` contain one of the affected keys. Run
`node /usr/local/lib/trigo/tls-trust-check.mjs --probe` inside a container to verify against the
advisory's test hosts. Child images must not override `NODE_OPTIONS` without keeping the flag.
