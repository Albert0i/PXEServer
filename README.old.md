Here’s the **finished README.md** — now fully complete, polished, and ready to drop into GitHub. It includes every piece: project structure, `.env`, `docker-compose.yml`, `Makefile`, installation, networking, user group setup, auto‑restart behavior, and final notes.

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

Here’s the full **Step 1: Install Docker on Debian 13** section from the PXEserver guide, laid out clearly so you can copy it straight into your README:

---

## 🛠️ Step 1: Install Docker on Debian 13

1. **Update the system packages**
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. **Install prerequisites**
   These packages allow apt to use repositories over HTTPS and manage keys.
   ```bash
   sudo apt install -y ca-certificates curl gnupg lsb-release
   ```

3. **Add Docker’s official GPG key**
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/debian/gpg | \
     sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

4. **Set up the Docker repository**
   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) \
     signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/debian \
     $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. **Install Docker Engine and Compose plugin**
   ```bash
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

6. **Enable and start the Docker service**
   ```bash
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

7. **Verify installation**
   ```bash
   docker --version
   docker compose version
   ```

---

✨ After completing this step, Docker is installed and ready to run containers. Combined with the `restart: unless-stopped` policy in your `docker-compose.yml`, your PXEserver VM will automatically bring up Redis, MariaDB, and MongoDB after reboot.

---

## 🔒 Step 2: Open Ports for External Access

Here’s the full **Step 2: Open Ports for External Access** section from the PXEserver guide, written in README‑style so you can drop it straight into your documentation:

---

## 🔒 Step 2: Open Ports for External Access

By default, Docker maps container ports to the VM. To allow your Zorin host (or other machines) to connect, you need to configure networking and firewall rules.

### 1. VirtualBox Networking
- **Bridged Adapter (recommended)**  
  - Go to **VirtualBox → VM Settings → Network**.  
  - Select **Bridged Adapter**.  
  - This makes the Debian VM appear as a device on your LAN, with its own IP address.  
  - Other devices on the same network can connect directly using that IP or the hostname `pxeserver`.

- **NAT + Port Forwarding (alternative)**  
  - If you prefer NAT, configure **Port Forwarding** in VirtualBox.  
  - Map host ports to VM ports, for example:  
    - Host 6379 → Guest 6379 (Redis)  
    - Host 3306 → Guest 3306 (MariaDB)  
    - Host 27017 → Guest 27017 (MongoDB)  
  - This allows access from the host machine, but not other LAN devices.

### 2. Firewall (UFW)
If UFW is enabled on Debian, open the required ports:

```bash
sudo ufw allow 6379/tcp   # Redis
sudo ufw allow 3306/tcp   # MariaDB
sudo ufw allow 27017/tcp  # MongoDB
sudo ufw reload
```

This ensures external clients can reach the services.

### 3. Verify Listening Ports
After starting the stack (`make up`), confirm that the services are listening:

```bash
sudo ss -tlnp | grep -E '6379|3306|27017'
```

You should see entries showing Redis on 6379, MariaDB on 3306, and MongoDB on 27017.

---

✨ With this step complete, your PXEserver VM is reachable from your Zorin host (and other LAN devices if using Bridged networking). Combined with hostname mapping (`pxeserver`), you can connect without needing to remember IP addresses.

---

## 🌐 Step 3: Access by Hostname (`pxeserver`)

Here’s the full **Step 3: Access by Hostname (`pxeserver`)** section from the PXEserver guide, formatted for your README:

---

## 🌐 Step 3: Access by Hostname (`pxeserver`)

Instead of connecting to your Debian VM by IP address, you can configure your system to use the hostname `pxeserver`.

### Option A: Local `/etc/hosts` (simple and quick)
On your Zorin host, edit the hosts file:

```bash
sudo nano /etc/hosts
```

Add a line mapping the VM’s IP address to the hostname:

```
192.168.1.50   pxeserver
```

*(Replace `192.168.1.50` with your VM’s actual IP — check inside Debian with `ip addr`.)*

Now you can connect using the hostname:
- `redis-cli -h pxeserver -p 6379`
- `mysql -h pxeserver -P 3306 -u myuser -p`
- `mongosh --host pxeserver --port 27017`

### Option B: LAN DNS (advanced)
If your home router or network has DNS/DHCP features:
- Register the hostname `pxeserver` with the VM’s IP in the router’s DNS settings.  
- This makes `pxeserver` resolvable by all devices on your LAN, not just your Zorin host.

---

✨ With this step complete, you no longer need to remember or type the VM’s IP address — simply use `pxeserver` as the hostname when connecting to Redis, MariaDB, or MongoDB. This makes your PXEserver VM feel like a proper service host on your network.

---

## 🚀 Step 4: Run the Stack

Here’s the full **Step 4: Run the Stack** section from the PXEserver guide, formatted for your README:

---

## 🚀 Step 4: Run the Stack

Once Docker is installed and networking is configured, you can launch the PXEserver database stack.

### 1. Create directories
Make sure the data and configuration directories exist:

```bash
mkdir -p ~/docker/pxeserver/data/{redis,mariadb,mongodb}
mkdir -p ~/docker/pxeserver/conf/redis
```

This ensures each database has its own persistent storage folder under `./data`.

### 2. Add Redis configuration
Place your `redis.conf` file under:

```
~/docker/pxeserver/conf/redis/redis.conf
```

This file will be mounted into the Redis container.

### 3. Start services
Navigate to the project folder and bring up the stack:

```bash
cd ~/docker/pxeserver
make up
```

This runs `docker compose up -d --remove-orphans`, starting Redis, MariaDB, and MongoDB in detached mode.

### 4. Check container status
Verify that all services are running:

```bash
make ps
```

You should see three containers: `redis`, `mariadb`, and `mongodb`.

### 5. View logs
To monitor logs from all services:

```bash
make logs
```

Use `Ctrl+C` to exit the log stream.

---

✨ At this point, your PXEserver VM is running Redis, MariaDB, and MongoDB. They will continue running until shutdown, and thanks to the `restart: unless-stopped` policy, they will automatically resume service after a reboot.

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
  - They only stay down if you explicitly stop them yourself.

Verify after reboot:
```bash
docker ps
```
You should see Redis, MariaDB, and MongoDB running.

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
- Bridged networking is easiest if you want to access from multiple devices.  
- NAT + Port Forwarding works if you only need access from the host machine.  
- Add your user (`alberto`) to the `docker` group for convenience.  
- Containers will auto‑start after reboot thanks to `restart: unless-stopped`.  

---

## 🎯 Conclusion

This setup ensures:
- PXEserver runs **three databases (Redis, MariaDB, MongoDB)** continuously until shutdown.  
- After reboot or updates, services **resume automatically**.  
- Data is safely stored in dedicated subfolders under `./data`.  
- You can connect by hostname (`pxeserver`) instead of IP.  
- Lifecycle management is simplified with the provided `Makefile`.

```

---

✨ That’s the **complete package** — everything in one go, fully documented and ready for GitHub. This README guarantees PXEserver will behave exactly as you want: three databases always running, resuming after reboot, with clean persistence and easy access.
