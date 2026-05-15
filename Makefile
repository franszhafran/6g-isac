PROJECT     := isac
COMPOSE_CORE := docker compose -p $(PROJECT) -f docker-compose.core.yaml
COMPOSE_RAN  := docker compose -p $(PROJECT) -f docker-compose.ran.yaml
COMPOSE_UE   := docker compose -p $(PROJECT) -f docker-compose.ue.yaml

.PHONY: build build-core build-ran build-ue \
        gtp5g \
        core-up core-down \
        ran-up ran-down \
        ue-up ue-down \
        up down restart status \
        add-subscriber \
        logs-core logs-amf logs-smf logs-upf logs-gnb logs-ue

# ── Build (from source) ────────────────────────────────────────────────────────

build: build-core build-ran build-ue

build-core:
	$(COMPOSE_CORE) build

build-ran:
	$(COMPOSE_RAN) build

build-ue:
	$(COMPOSE_UE) build

# ── Host prerequisite: gtp5g kernel module ────────────────────────────────────
# Must run as root on the Ubuntu host BEFORE starting UPF.

gtp5g:
	sudo bash scripts/install-gtp5g.sh

# ── Core (free5GC 5G SA) ───────────────────────────────────────────────────────

core-up:
	$(COMPOSE_CORE) up -d

core-down:
	$(COMPOSE_CORE) down

core-restart:
	$(COMPOSE_CORE) restart

# ── RAN (OAI gNB, rfsim, built from source) ───────────────────────────────────

ran-up:
	$(COMPOSE_RAN) up -d

ran-down:
	$(COMPOSE_RAN) down

# ── UE (OAI NR-UE, rfsim, built from source) ──────────────────────────────────

ue-up:
	$(COMPOSE_UE) up -d

ue-down:
	$(COMPOSE_UE) down

# ── Full stack ─────────────────────────────────────────────────────────────────

up: core-up
	@echo "Waiting 20s for core to be ready..."
	@sleep 20
	$(MAKE) ran-up
	@sleep 5
	$(MAKE) ue-up

down:
	-$(COMPOSE_UE) down
	-$(COMPOSE_RAN) down
	-$(COMPOSE_CORE) down

restart: down up

# ── Subscriber management ──────────────────────────────────────────────────────

add-subscriber:
	bash scripts/add-subscriber.sh

# ── Logs ───────────────────────────────────────────────────────────────────────

logs-core:
	$(COMPOSE_CORE) logs -f --tail=100

logs-amf:
	docker logs -f amf

logs-smf:
	docker logs -f smf

logs-upf:
	docker logs -f upf

logs-nrf:
	docker logs -f nrf

logs-gnb:
	docker logs -f oai-gnb

logs-ue:
	docker logs -f oai-nr-ue

# ── Status ─────────────────────────────────────────────────────────────────────

status:
	@echo "=== Core ===" && $(COMPOSE_CORE) ps
	@echo "=== RAN ===" && $(COMPOSE_RAN) ps
	@echo "=== UE ===" && $(COMPOSE_UE) ps
