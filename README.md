## Логи контейнера и счетчик приветствия(4 балла)
```text
2026-11-04 18:40:49,639 listening port=8000 storage=sqlite
2026-11-04 18:40:53,162 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-04 18:40:53,296 http 192.168.65.1 "GET /favicon.ico HTTP/1.1" 404 -
2026-11-04 18:41:07,518 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-04 18:41:07,915 http 192.168.65.1 "GET /favicon.ico HTTP/1.1" 404 -
2026-11-04 18:41:40,344 http 192.168.65.1 "POST /increment HTTP/1.1" 200 -
2026-11-04 18:41:45,267 http 192.168.65.1 "GET / HTTP/1.1" 200 -

{"greeting": "Hello world", "count": 0, "hostname": "21ede6f0f533", "storage": "sqlite"}
{"greeting": "Hello world", "count": 1, "hostname": "21ede6f0f533", "storage": "sqlite"}
```

## Проверка сохранения счетчика(6 баллов)
```text
artem@MacBook-Air-Artem docker-hw % curl http://localhost:8080 
{"greeting": "Hello world", "count": 4, "hostname": "586547165a0a", "storage": "sqlite"}%                                                  
artem@MacBook-Air-Artem docker-hw % docker compose down
[+] down 2/2
 ✔ Container docker-hw-app-1 Removed                                                                                                   3.1s
 ✔ Network docker-hw_default Removed                                                                                                   0.1s
artem@MacBook-Air-Artem docker-hw % docker compose up -d
[+] up 2/2
 ✔ Network docker-hw_default Created                                                                                                   0.0s
 ✔ Container docker-hw-app-1 Started                                                                                                   0.1s
artem@MacBook-Air-Artem docker-hw % curl http://localhost:8080
{"greeting": "Hello world", "count": 4, "hostname": "4b805a56c040", "storage": "sqlite"}%                       
```

## Отдельное хранилище(8 баллов)
```text
artem@MacBook-Air-Artem docker-hw % curl -X POST http://localhost:8080/increment
{"greeting": "Hello world", "count": 4, "hostname": "237c56330e36", "storage": "redis"}%
artem@MacBook-Air-Artem docker-hw % docker compose down
[+] down 3/3
✔ Container docker-hw-app-1   Removed                                                                                                 3.1s
✔ Container docker-hw-redis-1 Removed                                                                                                 0.1s
✔ Network docker-hw_default   Removed                                                                                                 0.1s
artem@MacBook-Air-Artem docker-hw % docker compose up -d
[+] up 3/3
✔ Network docker-hw_default   Created                                                                                                 0.0s
✔ Container docker-hw-redis-1 Healthy                                                                                                 5.1s
✔ Container docker-hw-app-1   Started                                                                                                 5.1s
artem@MacBook-Air-Artem docker-hw % curl http://localhost:8080/
{"greeting": "Hello world", "count": 4, "hostname": "c26286d58190", "storage": "redis"}%

artem@MacBook-Air-Artem docker-hw % docker compose stop redis
[+] stop 1/1
 ✔ Container docker-hw-redis-1 Stopped                                                                                                 0.1s
artem@MacBook-Air-Artem docker-hw % curl -i http://localhost:8080/healthz
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.13.18
Date: Wed, 11 Nov 2026 07:59:50 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 19
Cache-Control: no-store

{"status": "alive"}%                                                                                                                       
artem@MacBook-Air-Artem docker-hw % curl -i http://localhost:8080/readyz 
HTTP/1.0 503 Service Unavailable
Server: BaseHTTP/0.6 Python/3.13.18
Date: Wed, 11 Nov 2026 08:00:19 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 32
Cache-Control: no-store

{"error": "storage_unavailable"}%                                                                                                          
artem@MacBook-Air-Artem docker-hw % curl -i -X POST  http://localhost:8080/increment
HTTP/1.0 503 Service Unavailable
Server: BaseHTTP/0.6 Python/3.13.18
Date: Wed, 11 Nov 2026 08:00:48 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 32
Cache-Control: no-store

{"error": "storage_unavailable"}%  

artem@MacBook-Air-Artem docker-hw % docker compose start redis
[+] start 1/1
 ✔ Container docker-hw-redis-1 Started                                                                                                 0.1s
artem@MacBook-Air-Artem docker-hw % curl http://localhost:8080/                     
{"greeting": "Hello world", "count": 4, "hostname": "60b7f4912ee1", "storage": "redis"}%                                                   
artem@MacBook-Air-Artem docker-hw % curl -X POST http://localhost:8080/increment    
{"greeting": "Hello world", "count": 5, "hostname": "60b7f4912ee1", "storage": "redis"}%    
```

## Проверка восстановления(10 баллов)
## 1 проверка
```text
artem@MacBook-Air-Artem docker-hw % ./scripts/check.sh
[+] Building 2.4s (13/13) FINISHED                                                                                       
 => [internal] load local bake definitions                                                                          0.0s
 => => reading from stdin 538B                                                                                      0.0s
 => [internal] load build definition from Dockerfile                                                                0.0s
 => => transferring dockerfile: 345B                                                                                0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                                                 2.2s
 => [internal] load .dockerignore                                                                                   0.0s
 => => transferring context: 99B                                                                                    0.0s
 => [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106  0.0s
 => => resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106  0.0s
 => [internal] load build context                                                                                   0.0s
 => => transferring context: 94B                                                                                    0.0s
 => CACHED [2/6] RUN addgroup --system app && adduser --system --ingroup app app     && mkdir /data     && chown a  0.0s
 => CACHED [3/6] WORKDIR /app                                                                                       0.0s
 => CACHED [4/6] COPY app/requirements.txt .                                                                        0.0s
 => CACHED [5/6] RUN pip install -r requirements.txt                                                                0.0s
 => CACHED [6/6] COPY app/app.py .                                                                                  0.0s
 => exporting to image                                                                                              0.0s
 => => exporting layers                                                                                             0.0s
 => => exporting manifest sha256:8287fad953c7ad0e6723c17c05ac3a2f6fb338db18256f6c6434a227c4cfc5ae                   0.0s
 => => exporting config sha256:2c3aba2a49ef045a225a390691355b5ba4ba74f6d62e580d3d1b41ffc6b68780                     0.0s
 => => exporting attestation manifest sha256:6f203f5c5ffdf3dd40150c261c59beede8920958f1b81e061e533b78131604bb       0.0s
 => => exporting manifest list sha256:a7f0c602450153bc87929533e7ed8ca62672c42aae8d29d293ce5567d0b4df5d              0.0s
 => => naming to docker.io/library/docker-hw-check-2744-19254-app:latest                                            0.0s
 => => unpacking to docker.io/library/docker-hw-check-2744-19254-app:latest                                         0.0s
 => resolving provenance for metadata file                                                                          0.0s
[+] up 5/5
 ✔ Image docker-hw-check-2744-19254-app         Built                                                                3.5s
 ✔ Network docker-hw-check-2744-19254_default   Created                                                              0.0s
 ✔ Volume docker-hw-check-2744-19254_redis-data Created                                                              0.0s
 ✔ Container docker-hw-check-2744-19254-redis-1 Healthy                                                              5.1s
 ✔ Container docker-hw-check-2744-19254-app-1   Started                                                              5.1s
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 1, "hostname": "0ecc4fab6461", "storage": "redis"}
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 2, "hostname": "0ecc4fab6461", "storage": "redis"}
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 3, "hostname": "0ecc4fab6461", "storage": "redis"}
PASS: после 3 POST count=3
[+] up 1/1
 ✔ Container docker-hw-check-2744-19254-app-1 Started                                                                3.2s
PASS: контейнер приложения пересоздан, redis и count=3 сохранены
[+] stop 1/1
 ✔ Container docker-hw-check-2744-19254-redis-1 Stopped                                                              0.2s
GET /healthz -> HTTP 200 {"status": "alive"}
GET /readyz -> HTTP 503 {"error": "storage_unavailable"}
POST /increment -> HTTP 503 {"error": "storage_unavailable"}
[+] start 1/1
 ✔ Container docker-hw-check-2744-19254-redis-1 Started                                                              0.0s
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 4, "hostname": "05dc5c4e1cdb", "storage": "redis"}
PASS: redis восстановлен без перезапуска app
[+] stop 2/2
 ✔ Container docker-hw-check-2744-19254-app-1   Stopped                                                              3.1s
 ✔ Container docker-hw-check-2744-19254-redis-1 Stopped                                                              0.2s
Successfully copied 491B (transferred 2.05kB) to /Users/artem/Desktop/docker-hw/redis-backup-docker-hw-check-2744-19254.tar.gz
c8de11ef85770801166b95a8964910b9f8528f9297aeebbe90bf53776445dd5a
PASS: резервная копия создана: /Users/artem/Desktop/docker-hw/redis-backup-docker-hw-check-2744-19254.tar.gz
[+] down 4/4
 ✔ Container docker-hw-check-2744-19254-app-1   Removed                                                              0.0s
 ✔ Container docker-hw-check-2744-19254-redis-1 Removed                                                              0.0s
 ✔ Volume docker-hw-check-2744-19254_redis-data Removed                                                              0.0s
 ✔ Network docker-hw-check-2744-19254_default   Removed                                                              0.1s
PASS: тестовый проект и его томы удалены
```
### 2 проверка
```text
artem@MacBook-Air-Artem docker-hw % ./scripts/check.sh
[+] Building 1.4s (13/13) FINISHED                                                                                       
 => [internal] load local bake definitions                                                                          0.0s
 => => reading from stdin 536B                                                                                      0.0s
 => [internal] load build definition from Dockerfile                                                                0.0s
 => => transferring dockerfile: 345B                                                                                0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                                                 1.2s
 => [internal] load .dockerignore                                                                                   0.0s
 => => transferring context: 99B                                                                                    0.0s
 => [internal] load build context                                                                                   0.0s
 => => transferring context: 94B                                                                                    0.0s
 => [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106  0.0s
 => => resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106  0.0s
 => CACHED [2/6] RUN addgroup --system app && adduser --system --ingroup app app     && mkdir /data     && chown a  0.0s
 => CACHED [3/6] WORKDIR /app                                                                                       0.0s
 => CACHED [4/6] COPY app/requirements.txt .                                                                        0.0s
 => CACHED [5/6] RUN pip install -r requirements.txt                                                                0.0s
 => CACHED [6/6] COPY app/app.py .                                                                                  0.0s
 => exporting to image                                                                                              0.0s
 => => exporting layers                                                                                             0.0s
 => => exporting manifest sha256:f224e69f6ccbb881cc7cd4d1434bdf496bb69121b353dc09f01d4266a8214968                   0.0s
 => => exporting config sha256:5d086bae7b1ecb5903f59afc45c95ea195faf31ace3322d66fcb99a272c345d7                     0.0s
 => => exporting attestation manifest sha256:6c97c5ed4106985763750e9be803d06ef04f3553e9d6aae83d56f2b7fb06817c       0.0s
 => => exporting manifest list sha256:6668b54a84e110b97abfd78d03bb573f9de81bd6bfde226f647e238f6c0f4290              0.0s
 => => naming to docker.io/library/docker-hw-check-2955-3943-app:latest                                             0.0s
 => => unpacking to docker.io/library/docker-hw-check-2955-3943-app:latest                                          0.0s
 => resolving provenance for metadata file                                                                          0.0s
[+] up 5/5
 ✔ Image docker-hw-check-2955-3943-app         Built                                                                 1.4s
 ✔ Network docker-hw-check-2955-3943_default   Created                                                               0.0s
 ✔ Volume docker-hw-check-2955-3943_redis-data Created                                                               0.0s
 ✔ Container docker-hw-check-2955-3943-redis-1 Healthy                                                               5.1s
 ✔ Container docker-hw-check-2955-3943-app-1   Started                                                               5.1s
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 1, "hostname": "29e40f5daad1", "storage": "redis"}
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 2, "hostname": "29e40f5daad1", "storage": "redis"}
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 3, "hostname": "29e40f5daad1", "storage": "redis"}
PASS: после 3 POST count=3
[+] up 1/1
 ✔ Container docker-hw-check-2955-3943-app-1 Started                                                                 3.2s
PASS: контейнер приложения пересоздан, redis и count=3 сохранены
[+] stop 1/1
 ✔ Container docker-hw-check-2955-3943-redis-1 Stopped                                                               0.1s
GET /healthz -> HTTP 200 {"status": "alive"}
GET /readyz -> HTTP 503 {"error": "storage_unavailable"}
POST /increment -> HTTP 503 {"error": "storage_unavailable"}
[+] start 1/1
 ✔ Container docker-hw-check-2955-3943-redis-1 Started                                                               0.0s
POST /increment -> HTTP 200 {"greeting": "Hello world", "count": 4, "hostname": "2ede975f37ba", "storage": "redis"}
PASS: redis восстановлен без перезапуска app
[+] stop 2/2
 ✔ Container docker-hw-check-2955-3943-app-1   Stopped                                                               3.1s
 ✔ Container docker-hw-check-2955-3943-redis-1 Stopped                                                               0.2s
Successfully copied 499B (transferred 2.05kB) to /Users/artem/Desktop/docker-hw/redis-backup-docker-hw-check-2955-3943.tar.gz
a5a40ef9fc64867a04148d7da95697e28419af74ea1f71bc7fd9d7c5ddcd03d1
PASS: резервная копия создана: /Users/artem/Desktop/docker-hw/redis-backup-docker-hw-check-2955-3943.tar.gz
[+] down 4/4
 ✔ Container docker-hw-check-2955-3943-app-1   Removed                                                               0.0s
 ✔ Container docker-hw-check-2955-3943-redis-1 Removed                                                               0.0s
 ✔ Volume docker-hw-check-2955-3943_redis-data Removed                                                               0.0s
 ✔ Network docker-hw-check-2955-3943_default   Removed                                                               0.1s
PASS: тестовый проект и его томы удалены
```
### Ограничения приложения
```text
artem@MacBook-Air-Artem docker-hw % docker compose exec app python -c 'import os; print(os.getuid())'
100
artem@MacBook-Air-Artem docker-hw % docker inspect "$(docker compose ps -q app)" --format 'read_only={{.HostConfig.ReadonlyRootfs}} memory={{.HostConfig.Memory}} NanoCPUs={{.HostConfig.NanoCpus}}' 
read_only=true memory=268435456 NanoCPUs=1000000000
```