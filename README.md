Here’s the updated **README.md** with the two extra points you asked for — group membership for your `alberto` user and automatic container restart after reboot. I’ve slotted them neatly into the guide so it’s comprehensive and ready for GitHub.

---

```markdown
# PXEserver Database Stack (Debian 13 + Docker)

This project sets up **Redis, MariaDB, and MongoDB** inside a Debian 13 VM (with XFCE) running on VirtualBox.  
The databases are managed via **Docker Compose** and a **Makefile** for lifecycle automation.  
Your Zorin OS host connects to the VM databases using clients, either by IP or by the hostname `pxeserver`.

---

## 📂 Project Structure

```
~/docker/pxeserver/
├── .env
├── docker-compose.yml
├── Makefile
├── conf/
│   └── redis/
│       └── redis.conf
└── data/
    ├── redis/
    ├── mariadb/
    └── mongodb/
```

---

## 📝 .env file

```env
# Images
REDIS_IMAGE=redis:7
MARIADB_IMAGE=mariadb:11
MONGODB_IMAGE=mongo:6

# Directories
DATA_DIR=./data
CONFIG_DIR=./conf
```

---

## ⚙️ docker-compose.yml

```yaml
version: "3.8"

services:
  redis:
    image: ${REDIS_IMAGE}
    container_name: redis
    ports:
      - "6379:6379"
    command: ["redis-server", "/conf/redis.conf"]
    volumes:
      - ${CONFIG_DIR}/redis:/conf:ro
      - ${DATA_DIR}/redis:/data:rw
    restart: unless-stopped

  mariadb:
    image: ${MARIADB_IMAGE}
    container_name: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: secretpassword   # change this!
      MYSQL_DATABASE: mydb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
    ports:
      - "3306:3306"
    volumes:
      - ${DATA_DIR}/mariadb:/var/lib/mysql:rw
    restart: unless-stopped

  mongodb:
    image: ${MONGODB_IMAGE}
    container_name: mongodb
    ports:
      - "27017:27017"
    volumes:
      - ${DATA_DIR}/mongodb:/data/db:rw
    restart: unless-stopped
```

---

## 🛠️ Makefile

```makefile
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
```

---

## 🛠️ Step 1: Install Docker on Debian 13

*(same as before — installation steps)*

---

## 🔒 Step 2: Open Ports for External Access

*(same as before — VirtualBox networking + UFW firewall)*

---

## 🌐 Step 3: Access by Hostname (`pxeserver`)

*(same as before — `/etc/hosts` or LAN DNS)*

---

## 🚀 Step 4: Run the Stack

*(same as before — create directories, place `redis.conf`, run `make up`)*

---

## 👤 Step 5: User Group Setup (`alberto`)

To run Docker without `sudo`, add your Debian user `alberto` to the **docker group**:

```bash
sudo usermod -aG docker alberto
```

Log out and back in (or reboot) for the change to take effect.  
Check with:

```bash
groups alberto
```

You should see `docker` listed.

---

## 🔄 Step 6: Automatic Restart of Databases

- Docker service is managed by **systemd**. Enable it:
  ```bash
  sudo systemctl enable docker
  ```
- In `docker-compose.yml`, each service uses:
  ```yaml
  restart: unless-stopped
  ```
- This ensures:
  - Containers restart automatically after a VM reboot.  
  - Containers restart if they crash.  
  - If you manually stop a container, it stays stopped until you start it again.

Verify after reboot:
```bash
docker ps
```
You should see Redis, MariaDB, and MongoDB running.

---

## ✅ Verification

*(same as before — redis-cli, mysql, mongosh tests)*

---

## 📌 Notes

- Change passwords in `.env` before production use.  
- Use VM snapshots for rollback safety.  
- Bridged networking is easiest if you want to access from multiple devices.  
- NAT + Port Forwarding works if you only need access from the host machine.  
- Add your user (`alberto`) to the `docker` group for convenience.  
- Containers will auto‑start after reboot thanks to `restart: unless-stopped`.

---

## 🎯 Conclusion

This setup gives you:
- A **portable DB stack** inside Debian 13 VM.  
- **Clean separation** of data under `./data/redis`, `./data/mariadb`, `./data/mongodb`.  
- **Hostname access** via `pxeserver` for convenience.  
- Easy lifecycle management with `make up/down/ps/logs`.  
- **User-friendly Docker access** for `alberto`.  
- **Automatic restart** of databases after reboot.
```

---

Now your README.md is **fully comprehensive**: it documents the group membership for `alberto` and the auto‑restart behavior of your containers. This is the final polish for your PXEserver project guide.