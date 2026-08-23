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
	@echo "  prune      clear logs and reset client data folder permissions"
	@echo "  config     edit configuration"

up:
	$(COMPOSE) up -d --remove-orphans
	@echo ""
	@echo "┌────────────────────────────────────────────────────────────────────────┐"
	@echo "│ 🚀 DB stack & clients are running active                               │"
	@echo "├────────────────────────────────────────────────────────────────────────┤"
	@echo "│                                                                        │"
	@echo "│ 🌐 1. MariaDB Relational DB Manager (DBeaver / CloudBeaver)            │"
	@echo "│    👉 URL:        http://localhost:8978                                │"
	@echo "│    👉 DB Host:    mariadb                                              │"
	@echo "│    👉 DB Port:    3306                                                 │"
	@echo "│                                                                        │"
	@echo "│ 🌐 2. MongoDB Document DB Manager (MongoDB Compass Web)                │"
	@echo "│    👉 URL:        http://localhost:8085                                │"
	@echo "│    👉 DB Host:    mongodb                                              │"
	@echo "│    👉 DB Port:    27017                                                │"
	@echo "│                                                                        │"
	@echo "│ 🌐 3. Redis In-Memory Key-Value stora Manager (RedisInsight)           │"
	@echo "│    👉 URL:        http://localhost:5540                                │"
	@echo "│    👉 DB Host:    redis                                                │"
	@echo "│    👉 DB Port:    6379                                                 │"
	@echo "│                                                                        │"
	@echo "└────────────────────────────────────────────────────────────────────────┘"

down:
	$(COMPOSE) down -v

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

prune:
	@echo "⚠️ Completely removing the entire data folder and all subfolders..."
	@sudo rm -rf ./data
	@echo "📁 Recreating the root data directory and all subfolders..."
	@sudo mkdir -p ./data
	@sudo mkdir -p ./data/mariadb ./data/mongodb ./data/redis
	@sudo mkdir -p ./data/dbeaver_data ./data/compass_data ./data/redisinsight_data
	@sudo mkdir -p ./data/grafana_data ./data/prometheus_data
	@echo "🔒 Enforcing precise user ownership matching your system layout..."
	@# 1. Root folder ownership
	@sudo chown root:root ./data
	@sudo chmod 755 ./data
	@# 2. Database folders (Using explicit system text names)
	@sudo chown -R dnsmasq:systemd-journal ./data/mariadb
	@sudo chown -R dnsmasq:systemd-journal ./data/mongodb
	@sudo chown -R dnsmasq:systemd-journal ./data/redis
	@# 3. Monitoring folders (Using explicit system text names / numeric IDs)
	@sudo chown -R 472:472 ./data/grafana_data
	@sudo chown -R nobody:nogroup ./data/prometheus_data
	@# 4. Client interface folders (Using explicit numeric and active host user IDs)
	@sudo chown -R 8978:8978 ./data/dbeaver_data
	@sudo chown -R $(shell id -u):$(shell id -g) ./data/compass_data
	@sudo chown -R $(shell id -u):$(shell id -g) ./data/redisinsight_data
	@echo "✅ The entire data folder structure has been completely reset and permissioned!"

config:
	nano .env
