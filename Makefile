IMAGE := caddy-cf:scan

.PHONY: build scan ci

build:
	docker build --pull -t $(IMAGE) .

# Même scan que la CI (informatif, ne bloque pas)
scan: build
	trivy image --severity HIGH,CRITICAL $(IMAGE)

# Rejoue le workflow en local (nécessite `act`) ; push/attestation échouent sans token, seul build + scan comptent
ci:
	act pull_request -W .github/workflows/build.yml
