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

Все настройки через переменные окружения (см. `.env.example`):

| Переменная | По умолчанию | Описание |
|---|---|---|
| `DB_NAME` | `mmo_prototype` | Имя базы данных |
| `DB_USER` | `postgres` | Пользователь БД |
| `DB_PASSWORD` | — | Пароль БД |
| `DB_HOST` | `127.0.0.1` | Хост БД (`db` внутри Docker) |
| `DB_PORT` | `5432` | Порт БД |
| `SERVER_HOST` | `0.0.0.0` | Адрес сервера |
| `SERVER_PORT` | `27014` | Порт сервера |
| `SERVER_MAX_CLIENTS` | `3000` | Лимит подключений |
| `LOG_LEVEL` | `info` | Уровень логирования |

При запуске через Docker Compose, `DB_HOST` автоматически переопределяется на `db`.

## Дроп базы данных и заливка дампа

```bash
docker exec -it mmorpg_prototype_db dropdb -U postgres --force mmo_prototype
docker exec -it mmorpg_prototype_db createdb -U postgres mmo_prototype
docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype < mmo_prototype_dump.sql
```

## Создание админ-аккаунта через контейнер

Пароли хранятся как **SHA-256 hex**.

```bash
# 1. Сгенерировать хеш пароля
echo -n "ТВОЙ_ПАРОЛЬ" | sha256sum

# 2. Зайти в контейнер с БД
docker exec -it mmorpg_prototype_db psql -U postgres -d mmo_prototype

# 3. Создать админа (роль 2 = admin)
INSERT INTO users (login, password, email, role)
VALUES ('admin', 'хеш_из_шага_1', 'admin@example.com', 2);

# 4. Проверить
SELECT * FROM users WHERE role = 2;

# 5. Выйти
\q
```

Роли: `0` — player, `1` — gm, `2` — admin (таблица `user_roles`).