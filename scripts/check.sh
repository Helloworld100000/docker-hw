#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(pwd)"
PROJECT="docker-hw-check-$$-$RANDOM"
BACKUP="redis-backup-${PROJECT}.tar.gz"
N=3
backup_cid=""
stage="подготовка"
cleanup_needed=1
HOST_PORT=0
export HOST_PORT
cd "$ROOT"
dc() { docker compose -p "$PROJECT" -f "$ROOT/compose.yaml" "$@"; }
fail() { echo "FAIL [$stage]: $*" >&2; exit 1; }
cleanup() {
    if [[ -n "${backup_cid:-}" ]]; then
      docker rm -f "$backup_cid" >/dev/null 2>&1 || true
    fi
    if [[ "${cleanup_needed:-0}" == "1" ]]; then
      dc down -v --remove-orphans >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT
trap 'code=$?; echo "FAIL [$stage]: команда завершилась с ошибкой ($code)" >&2; exit "$code"' ERR
wait_ready() {
    local i response
    for ((i=0; i<90; i++)); do
      response="$(curl -sS --connect-timeout 2 --max-time 5 \
        -w $'\n%{http_code}' "$URL/readyz" 2>/dev/null || true)"
        [[ "${response##*$'\n'}" == "200" ]] && return
      sleep 1
    done
    fail "не дождался готовности сервиса за 90 секунд"
}
set_url() {
    local mapping port
    mapping="$(dc port app 8000)"
    mapping="${mapping%%$'\n'*}"
    port="${mapping##*:}"
    [[ "$port" =~ ^[0-9]+$ && "$port" != "0" ]] || fail "не удалось получить порт приложения"
    URL="http://127.0.0.1:$port"
}
request() {
    local method="$1" path="$2" response
    response="$(curl -sS --connect-timeout 2 --max-time 5 \
    -X "$method" -w $'\n%{http_code}' "$URL$path")" ||
    fail "таймаут или ошибка запроса $method $path"
    code="${response##*$'\n'}"
    body="${response%$'\n'*}"
}
check_status() {
    request "$1" "$2"
    [[ "$code" == "$3" ]] || fail "$1 $2: ожидался HTTP $3, получен $code"
    echo "$1 $2 -> HTTP $code $body"
}
get_count() {
    [[ "$body" =~ \"count\"[[:space:]]*:[[:space:]]*([0-9]+) ]] ||
      fail "в ответе нет счетчика"
    echo "${BASH_REMATCH[1]}"
}
stage="запуск тестового проекта"
dc up --build -d
set_url
wait_ready
stage="проверка нового хранилища и счетчика"
request GET /
[[ "$code" == "200" && "$(get_count)" == "0" ]] || fail "начальный счетчик не равен 0"
for ((i=0; i<N; i++)); do check_status POST /increment 200; done
request GET /
[[ "$(get_count)" == "$N" ]] || fail "после $N запросов счетчик неверный"
echo "PASS: после $N POST count=$N"
stage="пересоздание только контейнера приложения"
app_before="$(dc ps -q app)"
redis_before="$(dc ps -q redis)"
dc up -d --no-deps --force-recreate app
set_url
wait_ready
[[ "$(dc ps -q app)" != "$app_before" ]] || fail "контейнер приложения не пересоздался"
[[ "$(dc ps -q redis)" == "$redis_before" ]] || fail "redis изменился при пересоздании контейнера приложения"
request GET /
[[ "$(get_count)" == "$N" ]] || fail "счетчик изменился при пересоздании контейнера приложения"
echo "PASS: контейнер приложения пересоздан, redis и count=$N сохранены"
stage="остановка и восстановление redis"
app_before="$(dc ps -q app)"
dc stop redis
check_status GET /healthz 200
check_status GET /readyz 503
check_status POST /increment 503
dc start redis
wait_ready
[[ "$(dc ps -q app)" == "$app_before" ]] || fail "app перезапустился вместе с redis"
request GET /
[[ "$(get_count)" == "$N" ]] || fail "счетчик после redis не восстановился"
check_status POST /increment 200
[[ "$(get_count)" == "$((N+1))" ]] || fail "после восстановления счетчик не стал N+1"
echo "PASS: redis восстановлен без перезапуска app"
stage="резервное копирование redis"
dc stop app redis
volume="$(docker volume ls -q --filter "label=com.docker.compose.project=$PROJECT")"
[[ -n "$volume" && "$volume" != *$'\n'* ]] || fail "не удалось определить том с данными redis для резервной копии"
backup_cid="$(docker create \
  -v "$volume:/data:ro" \
  alpine:3 \
  tar -czf /tmp/redis-backup.tar.gz -C /data .)"
docker start -a "$backup_cid"
docker cp "$backup_cid:/tmp/redis-backup.tar.gz" "$ROOT/$BACKUP"
docker rm "$backup_cid"
backup_cid=""
[[ -s "$ROOT/$BACKUP" ]] || fail "резервная копия не создана"
echo "PASS: резервная копия создана: $ROOT/$BACKUP"
stage="удаление тестового проекта и его томов"
dc down -v --remove-orphans
cleanup_needed=0
echo "PASS: тестовый проект и его томы удалены"