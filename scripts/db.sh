#!/usr/bin/env bash
# PostgreSQL local pour Nalvium : conteneur Docker dédié "nalvium-db" (port 5433).
# Usage: scripts/db.sh start|stop|status|reset
set -euo pipefail
NAME=nalvium-db
PORT="${NALVIUM_PG_PORT:-5433}"
IMAGE=postgres:17-alpine

wait_ready() {
  for _ in $(seq 1 40); do
    docker exec "$NAME" pg_isready -U nalvium -d nalvium >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "PostgreSQL ne répond pas" >&2; return 1
}
start() {
  if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
    docker start "$NAME" >/dev/null
  else
    docker run -d --name "$NAME" -p "$PORT:5432" \
      -e POSTGRES_USER=nalvium -e POSTGRES_PASSWORD=nalvium_dev -e POSTGRES_DB=nalvium \
      -v nalvium_pgdata:/var/lib/postgresql/data "$IMAGE" >/dev/null
  fi
  wait_ready
  docker exec "$NAME" psql -U nalvium -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='nalvium_test'" | grep -q 1 || \
    docker exec "$NAME" createdb -U nalvium nalvium_test
  echo "PostgreSQL prêt sur localhost:$PORT (bases: nalvium, nalvium_test)"
}
case "${1:-}" in
  start) start ;;
  stop) docker stop "$NAME" ;;
  status) docker ps --filter "name=$NAME" --format '{{.Names}} {{.Status}}' ;;
  reset) docker rm -f "$NAME" >/dev/null 2>&1 || true; docker volume rm nalvium_pgdata >/dev/null 2>&1 || true; start ;;
  *) echo "usage: $0 start|stop|status|reset"; exit 1 ;;
esac
