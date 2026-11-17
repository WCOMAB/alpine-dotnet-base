# alpine-dotnet-base

Minimal, rootless Alpine base image for self-contained .NET apps, built on [Docker Hardened Images](https://hub.docker.com/hardened-images/catalog/dhi/alpine-base) `dhi.io/alpine-base`.

Published to `acrwcom.azurecr.io/alpine-dotnet-base`.

## Contents

The hardened `dhi.io/alpine-base` (musl, OpenSSL, CA certificates, BusyBox shell) plus:

* `libstdc++` and `libgcc`, needed by the .NET host
* non-root `app` user, uid/gid `1654`, set as the default user (same as the Microsoft .NET images)
* `ASPNETCORE_HTTP_PORTS=8080`, `DOTNET_RUNNING_IN_CONTAINER=true`, `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true`

No .NET runtime is included. It is the equivalent of `mcr.microsoft.com/dotnet/runtime-deps:*-alpine`, so apps must be published self-contained for `linux-musl-x64`. No ICU or time zone data either; set `<InvariantGlobalization>true</InvariantGlobalization>` in the app's project.

Image layers are pushed gzip-compressed, as the .NET SDK container tooling can't read the zstd layers of `dhi.io` images directly.

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
```

The pipeline needs the `common-build-variables` group (`dhi.io.username`, `dhi.io.password`) and the `WCOM ACR Push` service connection.
