PROJECT     := isac
COMPOSE_CORE := docker compose -p $(PROJECT) -f docker-compose.core.yaml
COMPOSE_RAN  := docker compose -p $(PROJECT) -f docker-compose.ran.yaml
COMPOSE_UE   := docker compose -p $(PROJECT) -f docker-compose.ue.yaml

.PHONY: build core-up core-down ran-up ran-down ue-up ue-down \
        up down restart status add-subscriber \
        logs-core logs-amf logs-smf logs-upf logs-gnb logs-ue

# ── Build ──────────────────────────────────────────────────────────────────────

build:
	docker build -t open5gs:local -f Dockerfile.open5gs .

# ── Core (Open5GS 5G SA) ───────────────────────────────────────────────────────

core-up: build
	$(COMPOSE_CORE) up -d

core-down:
	$(COMPOSE_CORE) down

core-restart:
	$(COMPOSE_CORE) restart

# ── RAN (OAI gNB, rfsim) ──────────────────────────────────────────────────────

ran-up:
	$(COMPOSE_RAN) up -d

ran-down:
	$(COMPOSE_RAN) down

# ── UE (OAI NR-UE, rfsim) ─────────────────────────────────────────────────────

ue-up:
	$(COMPOSE_UE) up -d

ue-down:
	$(COMPOSE_UE) down

# ── Full stack ─────────────────────────────────────────────────────────────────

up: core-up
	@echo "Waiting 15s for core to be ready..."
	@sleep 15
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

logs-gnb:
	docker logs -f oai-gnb

logs-ue:
	docker logs -f oai-nr-ue

# ── Status ─────────────────────────────────────────────────────────────────────

status:
	@echo "=== Core ===" && $(COMPOSE_CORE) ps
	@echo "=== RAN ===" && $(COMPOSE_RAN) ps
	@echo "=== UE ===" && $(COMPOSE_UE) ps
