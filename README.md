# alpine-dotnet-base

Minimal, rootless Alpine base image for self-contained .NET apps, built on [Docker Hardened Images](https://hub.docker.com/hardened-images/catalog/dhi/alpine-base) `dhi.io/alpine-base`.

Published to `acrwcom.azurecr.io/alpine-dotnet-base`.

## Contents

The hardened `dhi.io/alpine-base` (musl, OpenSSL, CA certificates, BusyBox shell) plus:

* `libstdc++` and `libgcc`, needed by the .NET host, from the DHI package repository and registered in the apk database (`/lib/apk/db/installed`) so vulnerability scanners see them
* non-root `app` user, uid/gid `1654`, set as the default user (same as the Microsoft .NET images)
* `ASPNETCORE_HTTP_PORTS=8080`, `DOTNET_RUNNING_IN_CONTAINER=true`, `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true`

No .NET runtime is included. It is the equivalent of `mcr.microsoft.com/dotnet/runtime-deps:*-alpine`, so apps must be published self-contained for `linux-musl-x64`. No ICU or time zone data either; set `<InvariantGlobalization>true</InvariantGlobalization>` in the app's project, or use the [extra image](#extra-image).

Image layers are pushed gzip-compressed, as the .NET SDK container tooling can't read the zstd layers of `dhi.io` images directly.

## Extra image

`acrwcom.azurecr.io/alpine-dotnet-base-extra` is built on top of the base image by the same pipeline run, and adds:

* `icu-libs` and `icu-data-full` (all cultures), for culture-aware formatting, sorting and `CultureInfo`
* `tzdata`, for `TimeZoneInfo` lookups by IANA or Windows id
* `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false`

Like the base image, the packages come from the DHI package repository and are registered in the apk database. It is the equivalent of `mcr.microsoft.com/dotnet/runtime-deps:*-alpine-extra`; use it when the app needs culture or time zone data, and don't set `InvariantGlobalization`. It has the same tags as the base image.

## Mini image

`acrwcom.azurecr.io/alpine-dotnet-base-mini` holds only what a self-contained .NET app needs at runtime, assembled from the base image of the same pipeline run into a single layer on `scratch`:

* the `musl`, `libcrypto3`, `libssl3`, `ca-certificates-bundle`, `libstdc++` and `libgcc` packages, complete and registered in the apk database (`/lib/apk/db/installed`)
* `/etc/os-release`, so vulnerability scanners detect Alpine
* `/etc/passwd` and `/etc/group` with `root` and the `app` user (uid/gid `1654`, the default user)
* `/tmp` (for .NET diagnostics sockets) and `/home/app`
* the same environment variables as the base image

Compared with the base image it leaves out the BusyBox shell and tools, `ssl_client` (only used by BusyBox `wget`; .NET loads OpenSSL directly), `alpine-baselayout-data`, the apk keys and repositories, and the DHI SBOM file (the apk database lists the packages instead).

There is no shell, so `docker exec … sh` doesn't work; use `docker cp`, `docker export` or a debug container to inspect it. Globalization is invariant only, as in the base image. It has the same tags as the base image.

## Tags

* `latest`
* `3.24`, the Alpine version
* `yyyy.M.d.r`, the build number

The image is rebuilt weekly to pick up security fixes from the base image.

## Usage

### .NET SDK

```bash
dotnet publish \
  --runtime linux-musl-x64 \
  --self-contained \
  -t:PublishContainer \
  -p:ContainerBaseImage=acrwcom.azurecr.io/alpine-dotnet-base:latest
```

### WCOM.AzurePipelines.YamlTemplates

```yaml
container:
  baseimage: 'acrwcom.azurecr.io/alpine-dotnet-base:latest'
  runtime: 'linux-musl-x64'
  selfContained: true
  pullRegistryUsername: 'acrwcom'
  pullRegistryPassword: '$(wcom.azurecr.io.password)'
```

## Build

```bash
docker login dhi.io
docker build -t alpine-dotnet-base .
docker build -f Dockerfile.extra --build-arg BASE_IMAGE=alpine-dotnet-base -t alpine-dotnet-base-extra .
docker build -f Dockerfile.mini --build-arg BASE_IMAGE=alpine-dotnet-base -t alpine-dotnet-base-mini .
```

The pipeline needs the `common-build-variables` group (`dhi.io.username`, `dhi.io.password`) and the `WCOM ACR Push` service connection.
