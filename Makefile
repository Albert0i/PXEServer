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

# prune:
# 	@echo "Clearing logs..."
# 	@rm -f $(DATA_DIR)/redis/*.log || true
# 	@rm -f $(DATA_DIR)/mariadb/*.log || true
# 	@rm -f $(DATA_DIR)/mongodb/*.log || true
# 	@echo "Resetting web client persistence data directories..."
# 	@sudo rm -rf ./data/dbeaver_data ./data/compass_data ./data/redisinsight_data
# 	@echo "Recreating folders and enforcing correct user ownership restrictions..."
# 	@mkdir -p ./data/dbeaver_data ./data/compass_data ./data/redisinsight_data
# 	@sudo chown -R 1001:1001 ./data/dbeaver_data
# 	@sudo chown -R 1000:1000 ./data/compass_data
# 	@sudo chown -R 1000:1000 ./data/redisinsight_data
# 	@echo "✅ Client folders reset successfully with matching Linux permissions!"
prune:
	@echo "⚠️ Completely removing the entire data folder and all subfolders..."
	@sudo rm -rf ./data
	@echo "📁 Recreating the root data directory and all database/client subfolders..."
	@sudo mkdir -p ./data
	@sudo mkdir -p ./data/mariadb ./data/mongodb ./data/redis
	@sudo mkdir -p ./data/dbeaver_data ./data/compass_data ./data/redisinsight_data
	@echo "🔒 Setting permissions and ownership layers..."
	@# 1. Enforce root:root ownership on the main data folder itself
	@sudo chown root:root ./data
	@sudo chmod 755 ./data
	@# 2. Match your system layout for databases (dnsmasq:systemd-journal)
	@sudo chown -R 103:101 ./data/mariadb
	@sudo chown -R 103:101 ./data/mongodb
	@sudo chown -R 103:101 ./data/redis
	@# 3. Match '8978:8978' ownership for CloudBeaver workspace
	@sudo chown -R 8978:8978 ./data/dbeaver_data
	@# 4. Match your host user account (alberto) for Compass and RedisInsight
	@sudo chown -R $(shell id -u):$(shell id -g) ./data/compass_data
	@sudo chown -R $(shell id -u):$(shell id -g) ./data/redisinsight_data
	@echo "✅ The entire data folder structure has been completely reset and permissioned!"

config:
	nano .env
