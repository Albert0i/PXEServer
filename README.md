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

Perfect, Albert — here’s the **new Section 8** you asked for, documenting Redis authentication and database location. This fits seamlessly after Section 7 (MongoDB authentication) in your README:

---

## 🔒 Step 8: Enable Redis Authentication and Database Location

By default, Redis runs without a password. For secure setups, you should configure authentication and persistence in `redis.conf`.

### Sample `redis.conf`

```conf
# Redis configuration file

# Require clients to authenticate with a password
requirepass myStrongRedisPassword

# Optional: enable ACL user with username/password (Redis 6+)
# user default on >myStrongRedisPassword ~* +@all

# Set the working directory for database files
dir /data

# Name of the dump file (RDB persistence)
dbfilename dump.rdb

# Append-only file for durability
appendonly yes
appendfilename "appendonly.aof"
```

### 📌 Explanation
- `requirepass myStrongRedisPassword` → sets the password clients must use.  
  Connect with:
  ```bash
  redis-cli -h pxeserver -p 6379 -a myStrongRedisPassword
  ```
- `dir /data` → tells Redis to store its persistence files in `/data`.  
  In your `docker-compose.yml`, `/data` is mapped to `./data/redis` on the host.  
- `dbfilename dump.rdb` → snapshot file name.  
- `appendonly yes` → enables append‑only file persistence for durability.  

### 🔄 Integration with Docker Compose
Your Compose file mounts:
```yaml
volumes:
  - ${CONFIG_DIR}/redis:/conf:ro
  - ${DATA_DIR}/redis:/data:rw
```

So place the `redis.conf` under:
```
~/docker/pxeserver/conf/redis/redis.conf
```

Redis will read it at startup, and persistence files (`dump.rdb`, `appendonly.aof`) will be written into:
```
~/docker/pxeserver/data/redis/
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

---




---


**Yes, you absolutely need to add a swap space**. Operating a modern Linux system like Debian 13 with only 1.4 GB of RAM and no swap risks immediate system instability, application crashes (due to the Linux Out-Of-Memory Killer), and an inability to handle sudden memory spikes.

For your specific setup, adding a swap space is generally recommended for system stability, with a size often tailored to available RAM.

## Why Swap is Beneficial

- **Prevents System Instability**: Without swap, if your memory usage hits 1.4 GB, the system may freeze or force-close active programs due to the Linux Out-Of-Memory (OOM) Killer.
- **Improves RAM Efficiency**: Linux moves idle background tasks into swap, freeing up your limited 1.4 GB of fast RAM for active applications and disk caching, as noted in Linux documentation. 

## Sizing and Setup Considerations

- **Common Recommendations**: A general guideline for machines with low RAM is to create a swap space of a size similar to or larger than the total RAM.
- **Performance Note**: The performance of the swap depends heavily on whether your storage drive is an SSD or an HDD.

## How to Add a Swap File
Instead of repartitioning your drive, you can create a swap file dynamically without rebooting. Run the following commands in your terminal as root or with sudo:

## 1. Create the File
Allocate a file on your storage drive (e.g., using 2G to create a 2 Gigabyte file): [13, 14] 
```
sudo fallocate -l 2G /swapfile
```
*(If fallocate fails, use: sudo dd if=/dev/zero of=/swapfile bs=1M count=2048)*

## 2. Secure Permissions
Restrict read/write access to the root user for security:
```
sudo chmod 600 /swapfile
```

## 3. Format as Swap
Set up the file as Linux swap space:
```
sudo mkswap /swapfile
```

## 4. Activate Swap
Enable the swap file immediately:
```
sudo swapon /swapfile
```

## 5. Make it Permanent
To ensure the swap file activates automatically every time your system boots, append it to your file system table. Open the file:
```
sudo nano /etc/fstab
```

Add the following line at the very bottom of the file, save, and exit:
```
/swapfile none swap sw 0 0
```

## Optimizing Swap Usage (Swappiness)
Because your RAM is quite low, you may want to configure how aggressively Debian uses the swap file to balance performance.

* Open the configuration file: `sudo nano /etc/sysctl.conf`
* Add this line to the bottom to set swappiness to a lower value, such as **10** (default is usually 60, which might cause too much disk activity on slower drives):
```
vm.swappiness=10
```

* Apply the changes immediately by running: `sudo sysctl -p`

**Disclaimer**: This information is for general knowledge regarding Linux system management. Always consult with system documentation for personalized advice on system optimization.

---

**You need at least 4 GB of swap space**. Running three major production-grade databases (Redis, MariaDB, and MongoDB) simultaneously on just 1.4 GB of RAM is incredibly tight. To prevent Docker containers from immediately crashing due to Out-Of-Memory (OOM) errors, a larger swap cushion is vital.

To create and permanently activate a **4 GB swap file**, run these commands in sequence:

## The Commands to Create the Swap
```
# 1. Allocate a 4 Gigabyte file 
sudo fallocate -l 4G /swapfile

# 2. Lock down the file permissions for system security
sudo chmod 600 /swapfile

# 3. Format the file into Linux swap format
sudo mkswap /swapfile

# 4. Turn the swap space on immediately
sudo swapon /swapfile

# 5. Make the swap file persist across system reboots
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**(Note: If the fallocate command gives you an error, use sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 instead to create the file)**.

## ⚠️ Critical Step: Limit Docker Memory
Because you are running heavy databases on extremely low physical memory, they will easily choke your system if left unconstrained. When launching your database containers, you **must use Docker resource limits** to force them to play nice.

For example, when running your docker run commands, enforce memory limits like this: [10, 11] 

* **Redis** (Typically low idle, but grows with keys): Limit to 128MB.
```
docker run -d --name my-redis -m 128m redis
```

* **MariaDB**: Limit to 350MB.
```
docker run -d --name my-mariadb -m 350m -e MARIADB_ROOT_PASSWORD=secret mariadb
```

* **MongoDB** (Very memory aggressive): Limit to 450MB.
```
docker run -d --name my-mongodb -m 450m mongo
```

If you plan to use a unified deployment script, let me know if you would like me to generate a docker-compose.yml file that automatically applies these strict memory limits for all three databases at once.


---

Here is your modified docker-compose.yml file.

Because your system only has 1.4 GB of physical RAM, I have added strict **deploy.resources.limits** blocks to each database. This prevents them from exceeding your physical memory and forcing the system to rely heavily on your new 4 GB swap file.

```
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
    # Added strict resource constraints
    deploy:
      resources:
        limits:
          memory: 128M

  mariadb:
    image: ${MARIADB_IMAGE}
    container_name: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: 7aStgp6OCwAHTNXBp1MGRxh0XgXFjoFcQZDSeVG5KKs=
      MYSQL_DATABASE: mydb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
    ports:
      - "3306:3306"
    volumes:
      - ${DATA_DIR}/mariadb:/var/lib/mysql:rw
    restart: unless-stopped
    # Added strict resource constraints
    deploy:
      resources:
        limits:
          memory: 350M

  mongodb:
    image: ${MONGODB_IMAGE}
    container_name: mongodb
    ports:
      - "27017:27017"
    volumes:
      - ${DATA_DIR}/mongodb:/data/db:rw
    restart: unless-stopped
    # Added strict resource constraints
    deploy:
      resources:
        limits:
          memory: 450M
```

## Important Warning for MongoDB & MariaDB
Even with Docker limits, these databases like to cache data inside their own internal engines, which can cause them to crash if they hit Docker's wall. To ensure they stay completely within these tight boundaries, you should add these configurations:

1. **MongoDB**: Inside your container, it is highly recommended to explicitly cap the WiredTiger cache size so it knows it only has small memory. If you use a custom command or config file later, ensure you pass --wiredTigerCacheSizeGB 0.25.
2. **MariaDB**: Ensure your internal InnoDB buffer pool size (innodb_buffer_pool_size) in your custom MariaDB configuration does not exceed 256M.

Would you like help creating a **custom configuration** file for MariaDB or MongoDB to ensure their internal memory settings match these new Docker limits perfectly?


---

To make this setup as clean and reliable as possible, **you do not actually need to deal with the hassle of separate volume mounts or configuration files**.

We can inject the low-memory optimizations **directly into the docker-compose.yml** file using native command-line flags and environment variables. This guarantees your databases strictly obey your memory limits without needing to create or map any extra text files.

Here is the fully optimized, production-ready `docker-compose.yml` tailored for your 1.4 GB RAM system:
```
version: "3.8"
services:
  redis:
    image: ${REDIS_IMAGE}
    container_name: redis
    ports:
      - "6379:6379"
    # Added maxmemory flag directly to the startup command to match the Docker limit
    command: ["redis-server", "/conf/redis.conf", "--maxmemory", "100mb", "--maxmemory-policy", "allkeys-lru"]
    volumes:
      - ${CONFIG_DIR}/redis:/conf:ro
      - ${DATA_DIR}/redis:/data:rw
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128M

  mariadb:
    image: ${MARIADB_IMAGE}
    container_name: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: 7aStgp6OCwAHTNXBp1MGRxh0XgXFjoFcQZDSeVG5KKs=
      MYSQL_DATABASE: mydb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
    ports:
      - "3306:3306"
    # Passing critical low-RAM flags directly to the MariaDB engine
    command: [
      "mariadbd",
      "--innodb-buffer-pool-size=128M",
      "--innodb-log-buffer-size=8M",
      "--key-buffer-size=16M",
      "--max-connections=20"
    ]
    volumes:
      - ${DATA_DIR}/mariadb:/var/lib/mysql:rw
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 350M

  mongodb:
    image: ${MONGODB_IMAGE}
    container_name: mongodb
    ports:
      - "27017:27017"
    # Crucial flag: forces MongoDB's WiredTiger cache to stick to 256MB (its bare minimum) 
    # instead of trying to read your total system RAM.
    command: ["mongod", "--wiredTigerCacheSizeGB", "0.25"]
    volumes:
      - ${DATA_DIR}/mongodb:/data/db:rw
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 450M
```

## What these modifications do:

   1. **Redis**: Constrained via `--maxmemory 100mb`. If it hits this threshold, it will automatically evict old data (`allkeys-lru`) instead of requesting more RAM and causing Docker to kill the container.
   2. **MariaDB**: The `--innodb-buffer-pool-size=128M` command caps its heavy internal cache engine. Dropping `--max-connections=20` is equally important, as each concurrent connection to a SQL database silently eats up massive chunks of system memory.
   3. **MongoDB**: MongoDB assumes it owns the whole machine and scales its cache aggressively. The -`-wiredTigerCacheSizeGB 0.25` argument forces it to use its minimum allowed cache size (256MB), leaving the rest of its 450MB footprint to handle incoming traffic and network sockets. [1, 2] 

Would you like help setting up the system environment variables (like ${DATA_DIR} and ${MONGODB_IMAGE}) in an .env file to spin this stack up properly?


---

Adding these limits will cause a noticeable drop in database performance. However, on a system with only 1.4 GB of RAM, this is a necessary trade-off to keep the services running without crashing. 
 
Here is exactly how performance will degrade for each service under these settings:

## 1. MariaDB (Relational Database)

- **Slow Disk Reads**: The `innodb_buffer_pool_size` is where MariaDB stores table indexes and frequently accessed data in RAM. Because it is capped at 128 MB, queries that search large tables cannot be answered from memory. The database will constantly read directly from your storage drive (SSD/HDD), making queries significantly slower.
- **Connection Bottlenecks**: Limiting `max-connections=20` means if you have an application with high traffic or poorly optimized connection pooling, users will face "Too many connections" errors or experience delays waiting for an open slot.

## 2. MongoDB (Document Database)

- **High Eviction Rate**: The WiredTiger storage engine relies heavily on RAM caching. Capping it at 0.25 GB means data pages will constantly look for space. Pages will be aggressively evicted to your drive, causing a massive spike in disk I/O operations and delaying find/update queries. [5, 6] 
- **Aggressive Page Faults**: MongoDB handles queries by mapping data files to virtual memory. Because physical RAM is tiny, this will cause heavy use of your new Swap Space. Swap space on an SSD or HDD is thousands of times slower than physical RAM. [7, 8] 

## 3. Redis (In-Memory Key-Value Store)

- **Data Loss (Eviction)**: Redis keeps everything in RAM. By setting `--maxmemory 100mb` and `allkeys-lru`, the moment your stored data exceeds 100 MB, Redis will automatically delete old keys to make room for new ones. If you use Redis for persistent data storage, you will lose data. If you use it for session management, users will be logged out unexpectedly. [9] 

## Summary of Overall System Performance
Because your total memory requirements will spill over into the 4 GB Swap space, your drive will experience continuous read/write cycles ("**disk thrashing**").

- **If your server uses an SSD**: The performance will be sluggish but usable for development or low-traffic testing.
- **If your server uses an HDD**: The system will likely become completely unresponsive under heavy loads because mechanical hard drives cannot handle constant swap traffic. [11, 12] 

Are these databases being used for a **local development environment**, a **personal playground**, or a **small production app**? Knowing your use case can help optimize these limits further.

---

No, those settings will **technically boot up and run** in a production environment, but they are highly risky for production because they sacrifice the reliability and stability that a live application needs.

The settings work perfectly for a **local development environment** or **personal playground** because you are the only user. If a query takes 2 seconds instead of 10 milliseconds, or if Redis deletes a session key and logs you out, it is just a minor annoyance.

In a **small production environment**, however, those exact same settings can cause severe business issues:

## Why those settings struggle in Production

- **User Face-Plant**: If 5 users try to load your app at the same exact time, MariaDB and MongoDB will instantly start fighting over your tiny 1.4 GB RAM. They will dump their caches into the Swap file on your hard drive. Your app will slow down to a crawl, and users will see "**504 Gateway Timeout**" errors.
- **The Silent Data Drop**: Because Redis is limited to 100MB with `allkeys-lru`, it will silently delete older data to make room for new data. If your production app relies on Redis to store critical data (like shopping carts, user permissions, or long-lived authentication tokens), your users will randomly lose their data or get kicked out of the app.
- **Server Lockups**: If your application traffic spikes, the heavy reading/writing to the Swap file (called **disk thrashing**) can max out your CPU and storage speed completely. When this happens, your entire Debian server can freeze, forcing you to hard-reboot it to get your app back online.

## How to make it work for Production on 1.4 GB RAM
If you absolutely *must* deploy this to production on this exact server due to budget limits, you should make these three adjustments to the settings we discussed:

1. **Change Redis to a Pure Cache**: Ensure your code never uses Redis for data that cannot be lost. Treat Redis strictly as a cache. If Redis deletes a key, your code must be able to gracefully look up that data from MariaDB instead.
2. **Slash MariaDB Connections**: In your application code (Node.js, Python, PHP, etc.), configure your connection pool to a strict maximum of **5 connections**. It is much better for your users to wait an extra 100ms in a queue for a free connection than to have MariaDB spawn 20 connections and crash your server.
3. **Optimize the Code, Not Just the DB**: Avoid complex database JOIN queries, full-table scans, or heavy text searches in MongoDB. Your queries must be simple and heavily reliant on specific database indexes so the tiny RAM cache doesn't get overwhelmed.

Would you like to move forward with configuring the .env file to launch this Docker setup, or would you like to check your server's current memory usage first to see how much RAM you have left right now?


---



---



1. 64位元Debian Linux作業系統實務-Trixie版, 李博明編著
https://eshop.tsanghai.com.tw/products/cs0464


---

246.
"To see all the things that happen to us as accidents or incidents from
a novel, which we read not with our eyes but with life. Only with
this attitude can we overcome the mischief of each day and the
fickleness of events."

"Considerar todas as coisas que nos sucedem’ como acidentes ou episódios de um romance, a que assistimos não com a atenção senão com a vida. Só com essa atitude poderemos vencer a malícia dos dias e os caprichos dos sucessos."


238. 
"There is no sure prize for virtue, and no sure punishment for sin.
Nor would it be right for such prizes and punishments to exist."

"Nenhum prémio certo tem a virtude, nenhum castigo certo o pecado. Nem seria justo que houvesse tal prémio ou tal castigo."

189. 
RAINY DAY
"The air is a veiled yellow, like a pale yellow seen through a dirty
white. There’s scarcely any yellow in the grey air, but the paleness
of the grey has a yellow in its sadness"

Dia de chuva
"O ar é de um amarelo escondido’, como um amarelo pálido visto através de um branco sujo. Mal há amarelo no ar acinzentado. A palidez do cinzento, porém, tem um amarelo na sua tristeza."

---

the ancient Greek mathematician Archimedes famously said: "Give me a place to stand and a lever long enough, and I will move the Earth". 

---

Everything has a reason, right? Why is it called "PXE Server"? What does "PXE" stand for?

