FROM caddy:2-builder AS caddy-build
ARG CLOUDFLARE_VERSION=v0.2.4
# shortcut: x/net forcé au-dessus de Caddy v2.11.9 (CVE-2026-78669); retirer le --replace dès que caddy:2 embarque x/net >= 0.62.0 (sinon il rétrograde)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build --with github.com/caddy-dns/cloudflare@${CLOUDFLARE_VERSION} \
      --replace golang.org/x/net=golang.org/x/net@v0.62.0

FROM caddy:2
LABEL org.opencontainers.image.source="https://github.com/a-belhadj/caddy-cloudflare" \
      org.opencontainers.image.title="caddy-cloudflare" \
      org.opencontainers.image.description="Caddy with the Cloudflare DNS plugin (caddy-dns/cloudflare), rebuilt weekly on the latest Go and Alpine" \
      org.opencontainers.image.licenses="Apache-2.0"
RUN apk upgrade --no-cache
COPY --from=caddy-build /usr/bin/caddy /usr/bin/caddy
