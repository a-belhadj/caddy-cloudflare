# Caddy + Cloudflare DNS — Docker image

[Caddy](https://caddyserver.com) Docker image with the Cloudflare DNS plugin ([caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)) for ACME DNS-01 challenges, wildcard TLS certificates and Let's Encrypt — rebuilt every week on the latest Go and Alpine so it stays free of fixable CVEs. linux/amd64 only.

[![build](https://github.com/a-belhadj/caddy-cloudflare/actions/workflows/build.yml/badge.svg)](https://github.com/a-belhadj/caddy-cloudflare/actions/workflows/build.yml)
[![Trivy](https://img.shields.io/badge/scanned%20by-Trivy-1904DA)](https://github.com/a-belhadj/caddy-cloudflare/security/code-scanning)
[![Image size](https://ghcr-badge.egpl.dev/a-belhadj/caddy-cloudflare/size?tag=latest)](https://github.com/a-belhadj/caddy-cloudflare/pkgs/container/caddy-cloudflare)
[![Latest tag](https://ghcr-badge.egpl.dev/a-belhadj/caddy-cloudflare/latest_tag?label=latest)](https://github.com/a-belhadj/caddy-cloudflare/pkgs/container/caddy-cloudflare)

**Image:** [`ghcr.io/a-belhadj/caddy-cloudflare`](https://github.com/a-belhadj/caddy-cloudflare/pkgs/container/caddy-cloudflare)

## Why this image

The official `ghcr.io/caddy-dns/cloudflare` image is no longer published (since March 2026). Its frozen Go toolchain (1.26.1) and base layers carry **~70 HIGH/CRITICAL CVEs** (Go stdlib, `x/crypto`, OpenSSL/musl).

This image compiles the up-to-date plugin with `xcaddy` on the current official builder and runs `apk upgrade` on the final image. It is **rebuilt every week**, scanned with Trivy, and only pushed if the scan passes. Result: **~70 → 6 CVEs**, all 6 justified in [`.trivyignore`](.trivyignore).

## Quick start

```sh
docker run -d --name caddy \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -e CF_API_TOKEN=your-token \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  ghcr.io/a-belhadj/caddy-cloudflare:2
```

`compose.yaml`:

```yaml
services:
  caddy:
    image: ghcr.io/a-belhadj/caddy-cloudflare:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    environment:
      CF_API_TOKEN: ${CF_API_TOKEN}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

`Caddyfile` (wildcard certificate for `*.example.com`):

```caddyfile
*.example.com, example.com {
	tls {
		dns cloudflare {env.CF_API_TOKEN}
	}

	@app host app.example.com
	handle @app {
		reverse_proxy app:8080
	}

	handle {
		respond "Not found" 404
	}
}
```

## Cloudflare API token

In the Cloudflare dashboard → *My Profile* → *API Tokens* → *Create Token* → *Custom token*:

- `Zone` → `DNS` → `Edit`
- `Zone` → `Zone` → `Read`
- Zone resources: include the zone(s) you need (e.g. `example.com`).

## Use as a base image

```dockerfile
FROM ghcr.io/a-belhadj/caddy-cloudflare:2
COPY Caddyfile /etc/caddy/Caddyfile
COPY dist/ /srv/
```

## Tags and rebuild policy

| Tag | Meaning |
|-----|---------|
| `latest` | Most recent build |
| `2`, `2.11`, `2.11.4` | Caddy major / minor / exact version (moving: re-pushed by each weekly rebuild) |
| `2.11.4-YYYYMMDD` | Immutable per-build tag — pin this for reproducible deployments / rollback |
| `sha-<short>` | Git commit that produced the build |

The image is rebuilt **every Monday 04:00 UTC** (without layer cache, on fresh `caddy:2` / `caddy:2-builder`), on every push to `main`, on `v*` tags and on manual dispatch. Pull requests build and scan but never push. Images ship with SBOM and provenance attestations.

## Verify the image

Images are signed with GitHub build-provenance attestations (Sigstore, keyless):

```sh
gh attestation verify oci://ghcr.io/a-belhadj/caddy-cloudflare:2 --owner a-belhadj
```

## Known CVEs

Six CVEs remain because they are pinned by Caddy's own `go.mod` and cannot be overridden. Each one is documented with a justification and an expiry date (`2026-12-31`) in [`.trivyignore`](.trivyignore). Scan results are published in the repository's *Security* tab.

## Verify the plugin

```sh
docker run --rm ghcr.io/a-belhadj/caddy-cloudflare:2 caddy list-modules | grep cloudflare
# dns.providers.cloudflare
```

## License

[Apache-2.0](LICENSE), same as Caddy.
