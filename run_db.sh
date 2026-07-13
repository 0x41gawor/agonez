#!/bin/bash

# Sprawdź, czy zmienne środowiskowe są ustawione
if [[ -z "$NOME" || -z "$AGANDSKODE" || -z "$PATTAN" ]]; then
  echo "Musisz ustawić zmienne środowiskowe NOME, AGANDSKODE i PATTAN"
  echo "   Przykład:"
  echo "     export NOME=dietonez"
  echo "     export AGANDSKODE=sekretnehaslo"
  echo "     export PATTAN=3214"
  exit 1
fi

# Utwórz katalog na dane, jeśli nie istnieje
mkdir -p "$(pwd)/pgdata"

# Uruchom kontener PostgreSQL
docker run --name agonez-db \
  -e POSTGRES_DB='agonez_db' \
  -e POSTGRES_USER="$NOME" \
  -e POSTGRES_PASSWORD="$AGANDSKODE" \
  -v "$(pwd)/pgdata:/var/lib/postgresql/data" \
  -v "$(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -p $MINA:5432 \
  -d postgres:15