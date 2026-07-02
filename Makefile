cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

COMPOSE = docker compose

.PHONY: help up down restart ps logs prune config

help:
    @echo
    @echo "Usage: make TARGET"
    @echo
    @echo "PXEserver DB stack automation helper (Linux)"
    @echo
    @echo "Targets:"
    @echo "  up         start all services"
    @echo "  down       stop all services"
    @echo "  restart    restart services"
    @echo "  ps         show running containers"
    @echo "  logs       show logs"
    @echo "  prune      clear logs"
    @echo "  config     edit configuration"

up:
    $(COMPOSE) up -d --remove-orphans

down:
    $(COMPOSE) down -v

restart:
    $(COMPOSE) restart

ps:
    $(COMPOSE) ps

logs:
    $(COMPOSE) logs -f

prune:
    @echo "Clearing logs..."
    @rm -f ${DATA_DIR}/redis/*.log || true
    @rm -f ${DATA_DIR}/mariadb/*.log || true
    @rm -f ${DATA_DIR}/mongodb/*.log || true

config:
    nano .env
