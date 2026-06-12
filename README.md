# MMOLoginServer — Auth + PostgreSQL

Port: `27014`

## Prod (Release, без hot-reload)

```bash
cd mmorpg-prototype-login-server
docker-compose up --build -d
```

Собирает образ с `CMAKE_BUILD_TYPE=Release`, стрипает бинарник, запускает PostgreSQL и логин-сервер.

## Dev (Debug, hot-reload через watchexec)

```bash
cd mmorpg-prototype-login-server
docker-compose -f docker-compose.dev.yml up --build -d
```

Собирает с `CMAKE_BUILD_TYPE=Debug`, включает watchexec — при изменении `.cpp`/`.hpp` пересобирает и рестартует сервер автоматически.

## Порядок запуска

Логин-сервер запускается **первым** — он создаёт сеть `mmo_network` и поднимает PostgreSQL.

После него запускай game-server и chunk-server.

## Конфигурация

`config.json`:
- `max_clients` — лимит одновременных подключений (применяется в коде, а не только TCP backlog)
- `database` — доступы к PostgreSQL (host: `db` внутри Docker-сети)

## Дроп базы данных и заливка дампа
docker exec -it mmorpg_prototype_db dropdb -U postgres --force mmo_prototype
docker exec -it mmorpg_prototype_db createdb -U postgres mmo_prototype
docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype < mmo_prototype_dump.sql