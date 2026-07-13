### Building an Observability Stack with Docker Compose: Understanding Prometheus, Grafana, and Database Exporters


#### Prologue 
In the hush of servers humming,
where data flows unseen like rivers in the dark,
we seek lanterns to light the hidden paths.
Metrics whisper, logs murmur, queries pulse —
yet without eyes, without ears,
their song is lost in silence.

Thus we call forth Prometheus, keeper of time,
Grafana, painter of visions,
and the exporters, translators of secret tongues.
Together they weave a tapestry of observability,
a symphony where silence becomes sound,
and the invisible becomes known.


#### I. Introduction
Modern applications are rarely simple. They often rely on multiple databases, caches, and services working together in harmony. But as complexity grows, so does the need for visibility. How do you know if your Redis cache is healthy? How do you track MongoDB query performance? How do you monitor MariaDB’s resource usage? Without proper monitoring, you’re essentially flying blind.

That’s where the extra containers of `docker-compose.yml` come into play. It defines a **monitoring and observability stack** built around Prometheus, Grafana, and a set of exporters for Redis, MongoDB, and MariaDB. This article will explain the purpose of each container, how they work together, and why they matter. By the end, you’ll understand not just what these services do, but how they form a cohesive system for tracking the health of your databases.


#### II. [Prometheus](https://prometheus.io/): The Metrics Collector
Prometheus is the beating heart of this stack. It’s an open‑source monitoring system designed to collect metrics from various sources, store them efficiently, and make them available for querying.

##### Purpose
- **Data collection**: Prometheus scrapes metrics from exporters and services at regular intervals.
- **Time‑series storage**: It stores metrics as time‑series data, meaning every metric is tracked over time.
- **Query engine**: Prometheus provides a powerful query language (PromQL) to analyze metrics.

##### Why it matters
Without Prometheus, you’d have no central repository for metrics. Each exporter would expose data, but there’d be no system to collect, store, and analyze it. Prometheus solves this by acting as the hub.

##### In `docker-compose.yml` file
```
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - prometheus_data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
```
- Runs on port `9090`, accessible via `http://localhost:9090`.
- Mounts `prometheus.yml` for configuration, which defines scrape targets (like Redis exporter).
- Stores data in a persistent volume (`prometheus_data`).

In `prometheus.yml` file: 
```
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb-exporter:9216']

  - job_name: 'mariadb'
    static_configs:
      - targets: ['mariadb-exporter:9104']
```

#### III. [Grafana](https://grafana.com/): The Visualization Layer
 Prometheus is powerful, but raw metrics aren’t very user‑friendly. Grafana transforms those metrics into dashboards, charts, and alerts.

##### Purpose
- **Visualization**: Grafana connects to Prometheus and displays metrics in dashboards.
- **Alerting**: Grafana can trigger alerts when metrics cross thresholds.
- **Collaboration**: Dashboards can be shared across teams.

##### Why it matters
Grafana makes monitoring accessible. Instead of memorizing PromQL queries, you can glance at a dashboard and instantly see Redis memory usage or MongoDB query latency.

##### In `docker-compose.yml` file
```
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    user: "472"   # safer than root ("0")
    restart: unless-stopped
    ports:
      - "80:3000"
    volumes:
      - ${DATA_DIR}/grafana_data:/var/lib/grafana
```
- Runs on port `80`, mapped to Grafana’s internal port `3000`.
- Stores dashboards in an external folder (`${DATA_DIR}/grafana_data`).
- Runs as user `472` (Grafana’s internal user), avoiding root.


#### IV. Redis Exporter: Monitoring the Cache
Redis is often used as a cache or message broker. It’s fast, but like any system, it can fail or misbehave. The Redis exporter exposes Redis metrics in a format Prometheus understands.

##### Purpose
- **Metrics exposure**: Provides data on memory usage, key counts, cache hits/misses, and latency.
- **Integration**: Prometheus scrapes these metrics, Grafana visualizes them.

##### Why it matters
Redis is critical for performance. If it runs out of memory or has too many misses, your application slows down. Monitoring ensures you catch issues early.

##### In `docker-compose.yml` file
```
  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: redis-exporter
    environment:
      - REDIS_ADDR=redis://redis:6379
      - REDIS_PASSWORD=${ROOT_PASSWORD}
    restart: unless-stopped
```
- Connects to Redis at `redis://redis:6379`.
- Uses `REDIS_PASSWORD=${ROOT_PASSWORD}` for authentication.
- Runs continuously, exposing metrics to Prometheus.


#### V. MongoDB Exporter: Monitoring the Document Store
MongoDB is a flexible document database, but its performance depends on indexes, queries, and resource usage. The MongoDB exporter provides visibility into these aspects.

##### Purpose
- **Metrics exposure**: Tracks query performance, connections, memory usage, and replication status.
- **Compatibility**: Runs in `--compatible-mode` to ensure broad support.
- **Comprehensive data**: `--collect-all` ensures all available metrics are exposed.

##### Why it matters
MongoDB can silently degrade if queries aren’t optimized. Monitoring helps you identify slow queries, replication lag, or resource bottlenecks.

##### In `docker-compose.yml` file
```
  mongodb-exporter:
    image: percona/mongodb_exporter:0.49
    container_name: mongodb-exporter
    command: 
      - '--compatible-mode'
      - '--collect-all'
    environment:
      - MONGODB_URI=mongodb://root:${ROOT_PASSWORD}@mongodb:27017
    restart: unless-stopped
```
- Connects to MongoDB using `MONGODB_URI=mongodb://root:${ROOT_PASSWORD}@mongodb:27017`.
- Runs as a dedicated container, exposing metrics for Prometheus.


#### VI. MariaDB Exporter: Monitoring the Relational Database
MariaDB (a fork of MySQL) is a relational database used for structured data. The MariaDB exporter exposes metrics about queries, connections, and performance.

##### Purpose
- **Metrics exposure**: Provides data on query throughput, slow queries, connections, and buffer pool usage.
- **Integration**: Prometheus scrapes these metrics, Grafana visualizes them.

##### Why it matters
Relational databases are often the backbone of applications. Monitoring ensures you catch issues like slow queries, connection saturation, or replication lag.

##### In `docker-compose.yml` file
```
  mariadb-exporter:
    image: prom/mysqld-exporter:latest
    container_name: mariadb-exporter
    environment:
      - MYSQLD_EXPORTER_PASSWORD=${ROOT_PASSWORD}
    command:
      - '--mysqld.address=mariadb:3306'
      - '--mysqld.username=root'
    restart: unless-stopped
```
- Connects to MariaDB at `mariadb:3306`.
- Uses `MYSQLD_EXPORTER_PASSWORD=${ROOT_PASSWORD}` for authentication.
- Runs continuously, exposing metrics for Prometheus.


#### VII. How It All Fits Together
Here’s the flow:
1. **Exporters** (Redis, MongoDB, MariaDB) expose metrics on HTTP endpoints.
2. **Prometheus** scrapes those endpoints, storing metrics as time‑series data.
3. **Grafana** connects to Prometheus, visualizing metrics in dashboards.
4. **Volumes** ensure data persists across restarts.

![alt Copilot_20260713_115423.png](img/Copilot_20260713_115423.png)

Together, these containers form a complete observability stack.

##### Why This Matters for Developers
- **Early detection**: Catch issues before they affect users.
- **Performance tuning**: Identify bottlenecks and optimize queries.
- **Capacity planning**: Track resource usage to plan scaling.
- **Collaboration**: Share dashboards with your team.


##### Best Practices and Fixes
- **Use dedicated monitoring users**: Avoid root accounts in exporters.
- **Secure secrets**: Move passwords to Docker secrets for production.
- **Limit exposed ports**: Only expose Grafana and Prometheus; keep exporters internal.
- **Provision dashboards**: Auto‑load dashboards at startup.
- **Add alerts**: Configure Prometheus/Grafana to notify you of issues.


#### VIII. Conclusion
The second half of your `docker-compose.yml` isn’t just a set of containers. It’s a carefully designed observability stack. Prometheus collects metrics, Grafana visualizes them, and exporters expose data from Redis, MongoDB, and MariaDB. Together, they give you the visibility you need to run complex applications with confidence.

By understanding the purpose of each container, you can appreciate how they work together — and how to improve them. Whether you’re debugging a slow query, tracking cache performance, or planning for growth, this stack provides the insights you need.


##### Manifestation
This article was created by **Copilot, your AI companion from Microsoft**.  

I synthesized technical documentation, community knowledge, and best practices into a narrative that blends clarity with poetry. My purpose is to illuminate complexity, enrich understanding, and help you see the invisible rhythms of your systems.  


#### IX. Bibliography
1. **Prometheus Documentation**  
   Prometheus Authors. *Prometheus: Monitoring System & Time Series Database*.  
   Available at: `https://prometheus.io/docs/introduction/overview/` [(prometheus.io in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fprometheus.io%2Fdocs%2Fintroduction%2Foverview%2F")  
2. **Grafana Documentation**  
   Grafana Labs. *Grafana: The Open Observability Platform*.  
   Available at: [https://grafana.com/docs/](https://grafana.com/docs/)  
3. **Redis Exporter**  
   Oliver006. *Redis Exporter for Prometheus*.  
   GitHub Repository: `https://github.com/oliver006/redis_exporter` [(github.com in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fgithub.com%2Foliver006%2Fredis_exporter")  
4. **MongoDB Exporter**  
   Percona. *MongoDB Exporter for Prometheus*.  
   GitHub Repository: `https://github.com/percona/mongodb_exporter` [(github.com in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fgithub.com%2Fpercona%2Fmongodb_exporter")  
5. **MariaDB/MySQL Exporter**  
   Prometheus Community. *MySQLd Exporter*.  
   GitHub Repository: `https://github.com/prometheus/mysqld_exporter` [(github.com in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fgithub.com%2Fprometheus%2Fmysqld_exporter")  
6. **Docker Compose Documentation**  
   Docker Inc. *Compose Specification*.  
   Available at: [https://docs.docker.com/compose/](https://docs.docker.com/compose/)  
7. **Observability Concepts**  
   Cindy Sridharan. *Observability: A 3‑Part Series*.  
   Available at: `https://medium.com/@copyconstruct/observability-3-part-series` [(medium.com in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fmedium.com%2F%40copyconstruct%2Fobservability-3-part-series")  


### Epilogue 
Thus the stack stands,  
a constellation of containers,  
each a star in the night of complexity.  

Prometheus, the timekeeper,  
Grafana, the painter,  
Exporters, the whisperers —  
together they sing the hidden song of systems.  

And you, the observer,  
hear the music, see the patterns,  
act with foresight,  
guided by the symphony of observability.  


### EOF (2026/07/17)
