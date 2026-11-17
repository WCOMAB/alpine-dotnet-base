ARG ALPINE_VERSION=3.24

# Build stage: the DHI kit variant has apk, used to fetch the C++ runtime
# libraries the .NET host (libhostfxr/libcoreclr) links against.
# Copies exactly the files each package owns, plus the packages' apk database
# entries, so vulnerability scanners and SBOM tools see them in the final image.
FROM dhi.io/alpine-base:${ALPINE_VERSION}-kit AS deps
USER 0
RUN apk add --no-cache libstdc++ libgcc \
    && mkdir -p /out /db \
    && apk info -qL libstdc++ libgcc | grep . | tar -C / -cf - -T - | tar -C /out -xf - \
    && awk 'BEGIN { RS = ""; ORS = "\n\n" } /\nP:(libstdc\+\+|libgcc)\n/' /lib/apk/db/installed > /db/installed

# Final stage: hardened Docker Hardened Images Alpine base (musl, OpenSSL,
# CA certificates) plus the .NET native dependencies. Equivalent to
# mcr.microsoft.com/dotnet/runtime-deps:*-alpine, for self-contained apps
# published with --runtime linux-musl-x64 --self-contained.
FROM dhi.io/alpine-base:${ALPINE_VERSION}
COPY --from=deps /out/ /

# Register the copied packages in the apk database, and add the same non-root
# user as the Microsoft .NET images.
USER 0
RUN --mount=type=bind,from=deps,source=/db,target=/db \
    cat /db/installed >> /lib/apk/db/installed \
    && echo "app:x:1654:1654::/home/app:/bin/sh" >> /etc/passwd \
    && echo "app:x:1654:app" >> /etc/group \
    && mkdir -p /home/app \
    && chown 1654:1654 /home/app

ENV APP_UID=1654 \
    ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

USER $APP_UID
