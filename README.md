Here’s the **complete README.md** in one go — fully polished, comprehensive, and ready to drop into GitHub for your PXEserver project:

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

1. Update system:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. Install prerequisites:
   ```bash
   sudo apt install -y ca-certificates curl gnupg lsb-release
   ```

3. Add Docker’s official GPG key:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/debian/gpg | \
     sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

4. Add Docker repository:
   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) \
     signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/debian \
     $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. Install Docker Engine + Compose plugin:
   ```bash
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

6. Enable and start Docker:
   ```bash
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

7. Verify installation:
   ```bash
   docker --version
   docker compose version
   ```

---

## 🔒 Step 2: Open Ports for External Access

1. **VirtualBox Networking**
   - Use **Bridged Adapter** (recommended) so the VM appears as a device on your LAN.  
   - Or use **NAT + Port Forwarding** to map host ports to VM ports.

2. **Firewall (UFW)**
   ```bash
   sudo ufw allow 6379/tcp   # Redis
   sudo ufw allow 3306/tcp   # MariaDB
   sudo ufw allow 27017/tcp  # MongoDB
   sudo ufw reload
   ```

3. **Verify listening ports**
   ```bash
   sudo ss -tlnp | grep -E '6379|3306|27017'
   ```

---

## 🌐 Step 3: Access by Hostname (`pxeserver`)

### Option A: Local `/etc/hosts`
On your Zorin host:
```bash
sudo nano /etc/hosts
```

Add:
```
192.168.1.50   pxeserver
```

*(Replace with your VM’s IP — check with `ip addr` inside Debian.)*

### Option B: LAN DNS
Register `pxeserver` in your router’s DNS/DHCP settings for network‑wide access.

---

## 🚀 Step 4: Run the Stack

1. Create directories:
   ```bash
   mkdir -p ~/docker/pxeserver/data/{redis,mariadb,mongodb}
   mkdir -p ~/docker/pxeserver/conf/redis
   ```

2. Place `redis.conf` under `~/docker/pxeserver/conf/redis/`.

3. Start services:
   ```bash
   cd ~/docker/pxeserver
   make up
   ```

4. Check status:
   ```bash
   make ps
   ```

5. Logs:
   ```bash
   make logs
   ```

---

## 👤 Step 5: User Group Setup (`alberto`)

Add your Debian user `alberto` to the docker group:

```bash
sudo usermod -aG docker alberto
```

Log out and back in (or reboot). Verify:

```bash
groups alberto
```

---

## 🔄 Step 6: Automatic Restart of Databases

- Enable Docker service:
  ```bash
  sudo systemctl enable docker
  ```
- Containers use `restart: unless-stopped`, ensuring:
  - They restart after reboot.  
  - They restart if they crash.  
  - They stay down only if you stop them manually.

Verify after reboot:
```bash
docker ps
```

---

Got it, Albert — let’s add a proper **MongoDB Enable Section** to the README so you have both the default (no auth) and secure (auth enabled) options documented. Here’s how it fits in:

---

## 🔑 Step 7: Enable MongoDB Authentication (Optional)

By default, the MongoDB container runs **without authentication**. This is fine for local testing, but for production‑like use you should enable a username and password.

### Option A: Default (no authentication)
With the current `docker-compose.yml`:
```yaml
mongodb:
  image: ${MONGODB_IMAGE}
  container_name: mongodb
  ports:
    - "27017:27017"
  volumes:
    - ${DATA_DIR}/mongodb:/data/db:rw
  restart: unless-stopped
```

You can connect directly:
```bash
mongosh --host pxeserver --port 27017
```

No credentials are required.

---

### Option B: Secure (authentication enabled)
Add environment variables to the MongoDB service:

```yaml
mongodb:
  image: ${MONGODB_IMAGE}
  container_name: mongodb
  ports:
    - "27017:27017"
  environment:
    MONGO_INITDB_ROOT_USERNAME: root
    MONGO_INITDB_ROOT_PASSWORD: yourStrongPassword
  volumes:
    - ${DATA_DIR}/mongodb:/data/db:rw
  restart: unless-stopped
```

This creates a root user with the specified password. Connect using:

```bash
mongosh --host pxeserver --port 27017 -u root -p yourStrongPassword --authenticationDatabase admin
```

---

### 📌 Notes
- Replace `yourStrongPassword` with a secure password.  
- Always specify `--authenticationDatabase admin` when logging in as the root user.  
- You can later create application‑specific users with limited roles inside MongoDB for better security.

---


## ✅ Verification

From your Zorin host:

- **Redis**
  ```bash
  redis-cli -h pxeserver -p 6379 ping
  ```
  Expected: `PONG`

- **MariaDB**
  ```bash
  mysql -h pxeserver -P 3306 -u myuser -p
  ```

- **MongoDB**
  ```bash
  mongosh --host pxeserver --port 27017
  ```

---

## 📌 Notes

- Change passwords in `.env` before production use.  
- Use VM snapshots for rollback safety.  
- Bridged networking is easiest for multi‑device access.  
- NAT + Port Forwarding works if you only need host access.  
- Add `alberto` to the docker group for convenience.  
- Containers auto‑start after reboot thanks to `restart: unless-stopped`.

---

## 🎯 Conclusion

This setup ensures:
- PXEserver runs **three databases (Redis, MariaDB, MongoDB)** continuously until shutdown.  
- After reboot or updates, services **resume automatically**.  
- Data is safely stored in dedicated subfolders under `./data`.  
- You can connect by hostname (`pxeserver`) instead of IP.  
- Lifecycle management is simplified with the provided `Makefile`.  
- User `alberto` can manage Docker without `sudo`.  

```

---

✨ That’s the **complete README.md** in one go — fully comprehensive, structured, and ready for GitHub. It guarantees PXEserver will behave exactly as you want: three databases always running, resuming after reboot, with clean persistence and easy access.