ARG ALPINE_VERSION=3.24

# Build stage: the DHI kit variant has apk, used to fetch the C++ runtime
# libraries the .NET host (libhostfxr/libcoreclr) links against.
FROM dhi.io/alpine-base:${ALPINE_VERSION}-kit AS deps
USER 0
RUN apk add --no-cache libstdc++ libgcc \
    && mkdir -p /out/usr/lib \
    && cp -a /usr/lib/libstdc++.so.6* /usr/lib/libgcc_s.so.1 /out/usr/lib/

# Final stage: hardened Docker Hardened Images Alpine base (musl, OpenSSL,
# CA certificates) plus the .NET native dependencies. Equivalent to
# mcr.microsoft.com/dotnet/runtime-deps:*-alpine, for self-contained apps
# published with --runtime linux-musl-x64 --self-contained.
FROM dhi.io/alpine-base:${ALPINE_VERSION}
COPY --from=deps /out/ /

# Same non-root user and environment as the Microsoft .NET images.
USER 0
RUN echo "app:x:1654:1654::/home/app:/bin/sh" >> /etc/passwd \
    && echo "app:x:1654:app" >> /etc/group \
    && mkdir -p /home/app \
    && chown 1654:1654 /home/app

ENV APP_UID=1654 \
    ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

USER $APP_UID
